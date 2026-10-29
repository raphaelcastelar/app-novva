import { BadRequestException } from '@nestjs/common';
import { SerproService } from '../src/common/serpro.service';

describe('SerproService DAS response parsing', () => {
  const service = new SerproService();

  it('reports that no DAS exists when the period has no amount due', () => {
    const response = {
      mensagens: [{
        codigo: '[Aviso-PGDASD-MSG_E0139]',
        texto: 'MSG_E0139 - Não foi gerado DAS por não haver valor devido para o período informado.',
      }],
      dados: '',
    };

    expect(() => (service as any).parseGeneratedDas(response, '11222333000181', '202609'))
      .toThrow(new BadRequestException(
        'Não foi gerado DAS por não haver valor devido para o período informado.',
      ));
  });

  it('returns the PDF when Serpro reports a successful generation', () => {
    const pdf = Buffer.from('%PDF-1.4\nDAS').toString('base64');
    const response = {
      mensagens: [{ codigo: '[Sucesso-PGDASD]', texto: 'Operação efetuada com sucesso.' }],
      dados: JSON.stringify([{ pdf, nomeArquivo: 'DAS-09-2026.pdf' }]),
    };

    const result = (service as any).parseGeneratedDas(
      response,
      '11222333000181',
      '202609',
    );

    expect(result.filename).toBe('DAS-09-2026.pdf');
    expect(result.content.subarray(0, 5).toString()).toBe('%PDF-');
  });
});
