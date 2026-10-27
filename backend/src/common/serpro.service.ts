import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import axios, { AxiosError, AxiosInstance } from 'axios';
import { readFileSync } from 'fs';
import { Agent } from 'https';

type SerproTokens = {
  accessToken: string;
  jwtToken: string;
  expiresAt: number;
};

type GeneratedDas = {
  content: Buffer;
  filename: string;
};

@Injectable()
export class SerproService {
  private readonly authUrl =
    process.env.SERPRO_AUTH_URL ??
    'https://autenticacao.sapi.serpro.gov.br/authenticate';
  private readonly gatewayUrl =
    process.env.SERPRO_GATEWAY_URL ??
    'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1';
  private tokens?: SerproTokens;
  private pendingToken?: Promise<SerproTokens>;

  async generateDas(cnpj: string, period: string): Promise<GeneratedDas> {
    if (process.env.SERPRO_ENABLED !== 'true') {
      throw new ServiceUnavailableException(
        'A geração de guias ainda não está habilitada.',
      );
    }
    if (!/^\d{14}$/.test(cnpj) || !/^\d{6}$/.test(period)) {
      throw new BadRequestException('CNPJ ou competência inválida.');
    }

    let tokens = await this.getTokens();
    let response;
    try {
      response = await this.emitDas(cnpj, period, tokens);
    } catch (error) {
      if (!this.isUnauthorized(error)) throw this.mapCommunicationError(error);
      this.tokens = undefined;
      tokens = await this.getTokens();
      try {
        response = await this.emitDas(cnpj, period, tokens);
      } catch (retryError) {
        throw this.mapCommunicationError(retryError);
      }
    }

    return this.parseGeneratedDas(response.data, cnpj, period);
  }

  private async emitDas(cnpj: string, period: string, tokens: SerproTokens) {
    const contractor = this.requiredDigits(
      'SERPRO_CONTRACTOR_CNPJ',
      process.env.SERPRO_CONTRACTOR_CNPJ,
    );
    return this.gatewayClient().post('/Emitir', {
      contratante: { numero: contractor, tipo: 2 },
      autorPedidoDados: { numero: contractor, tipo: 2 },
      contribuinte: { numero: cnpj, tipo: 2 },
      pedidoDados: {
        idSistema: 'PGDASD',
        idServico: 'GERARDAS12',
        versaoSistema: '1.0',
        dados: JSON.stringify({ periodoApuracao: period }),
      },
    }, {
      headers: {
        Authorization: `Bearer ${tokens.accessToken}`,
        jwt_token: tokens.jwtToken,
        'Content-Type': 'application/json',
      },
    });
  }

  private async getTokens(): Promise<SerproTokens> {
    if (this.tokens && this.tokens.expiresAt > Date.now() + 60_000) {
      return this.tokens;
    }
    if (this.pendingToken) return this.pendingToken;
    this.pendingToken = this.authenticate();
    try {
      this.tokens = await this.pendingToken;
      return this.tokens;
    } finally {
      this.pendingToken = undefined;
    }
  }

  private async authenticate(): Promise<SerproTokens> {
    const key = this.required('SERPRO_CONSUMER_KEY');
    const secret = this.required('SERPRO_CONSUMER_SECRET');
    try {
      const response = await axios.post(
        this.authUrl,
        new URLSearchParams({ grant_type: 'client_credentials' }).toString(),
        {
          timeout: 30_000,
          httpsAgent: this.mtlsAgent(),
          headers: {
            Authorization: `Basic ${Buffer.from(`${key}:${secret}`).toString('base64')}`,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Role-Type': 'TERCEIROS',
          },
        },
      );
      const accessToken = response.data?.access_token;
      const jwtToken = response.data?.jwt_token;
      if (!accessToken || !jwtToken) throw new Error('Tokens ausentes.');
      const expiresIn = Number(response.data?.expires_in ?? 3600);
      return {
        accessToken,
        jwtToken,
        expiresAt: Date.now() + Math.max(60, expiresIn) * 1000,
      };
    } catch (error) {
      throw this.mapCommunicationError(error, 'Falha na autenticação com o Integra Contador.');
    }
  }

  private gatewayClient(): AxiosInstance {
    return axios.create({
      baseURL: this.gatewayUrl,
      timeout: 45_000,
      maxContentLength: 15 * 1024 * 1024,
      maxBodyLength: 15 * 1024 * 1024,
    });
  }

  private mtlsAgent() {
    const pfxPath = process.env.SERPRO_PFX_PATH;
    if (pfxPath) {
      try {
        return new Agent({
          pfx: readFileSync(pfxPath),
          passphrase: process.env.SERPRO_CERT_PASSWORD || undefined,
          keepAlive: true,
        });
      } catch {
        throw new ServiceUnavailableException(
          'Não foi possível carregar o certificado PFX do Integra Contador.',
        );
      }
    }

    const cert = this.pem('SERPRO_CERT_PEM', 'SERPRO_CERT_PATH');
    const key = this.pem('SERPRO_PRIVATE_KEY_PEM', 'SERPRO_PRIVATE_KEY_PATH');
    return new Agent({
      cert,
      key,
      passphrase: process.env.SERPRO_CERT_PASSWORD || undefined,
      keepAlive: true,
    });
  }

  private pem(valueName: string, pathName: string) {
    const value = process.env[valueName];
    if (value) return value.replace(/\\n/g, '\n');
    const path = process.env[pathName];
    if (!path) {
      throw new ServiceUnavailableException(
        `Configure ${valueName} ou ${pathName}.`,
      );
    }
    try {
      return readFileSync(path, 'utf8');
    } catch {
      throw new ServiceUnavailableException(
        'Não foi possível carregar o certificado do Integra Contador.',
      );
    }
  }

  private parseGeneratedDas(data: any, cnpj: string, period: string): GeneratedDas {
    const messages = Array.isArray(data?.mensagens) ? data.mensagens : [];
    const noAmountDue = messages.some((message: any) =>
      String(message?.codigo ?? '').includes('MSG_E0139'),
    );
    const successful = messages.some((message: any) =>
      String(message?.texto ?? '').toLocaleLowerCase('pt-BR').includes('sucesso') ||
      String(message?.codigo ?? '').toLocaleLowerCase('pt-BR').includes('sucesso'),
    );
    if (!noAmountDue && !successful) {
      const message = String(messages[0]?.texto ?? 'O Integra Contador não gerou a guia.');
      throw new BadRequestException(message.slice(0, 500));
    }

    let parsed: any;
    try {
      parsed = typeof data?.dados === 'string' ? JSON.parse(data.dados) : data?.dados;
    } catch {
      throw new ServiceUnavailableException('Resposta inválida do Integra Contador.');
    }
    const item = Array.isArray(parsed) ? parsed[0] : parsed;
    const pdf = item?.pdf ?? item?.extrato?.pdf;
    if (!pdf || typeof pdf !== 'string') {
      throw new BadRequestException('O Integra Contador não retornou o PDF da guia.');
    }
    const content = Buffer.from(pdf, 'base64');
    if (!content.length || content.subarray(0, 5).toString() !== '%PDF-') {
      throw new ServiceUnavailableException('O Integra Contador retornou um PDF inválido.');
    }
    const rawFilename = String(
      item?.nomeArquivo ?? item?.extrato?.nomeArquivo ?? `DAS_${cnpj}_${period}.pdf`,
    );
    return {
      content,
      filename: rawFilename.replace(/[\r\n"\\/]/g, '_').slice(0, 180),
    };
  }

  private required(name: string) {
    const value = process.env[name]?.trim();
    if (!value) throw new ServiceUnavailableException(`Configure ${name}.`);
    return value;
  }

  private requiredDigits(name: string, value?: string) {
    const digits = value?.replace(/\D/g, '') ?? '';
    if (digits.length !== 14) {
      throw new ServiceUnavailableException(`Configure ${name} com 14 dígitos.`);
    }
    return digits;
  }

  private isUnauthorized(error: unknown) {
    return error instanceof AxiosError && error.response?.status === 401;
  }

  private mapCommunicationError(
    error: unknown,
    fallback = 'Não foi possível comunicar com o Integra Contador.',
  ) {
    if (error instanceof BadRequestException || error instanceof ServiceUnavailableException) {
      return error;
    }
    if (error instanceof AxiosError) {
      const apiMessage = error.response?.data?.mensagens?.[0]?.texto;
      if (typeof apiMessage === 'string' && apiMessage.trim()) {
        return new BadRequestException(apiMessage.trim().slice(0, 500));
      }
    }
    return new ServiceUnavailableException(fallback);
  }
}
