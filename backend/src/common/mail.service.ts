import { Injectable, Logger } from '@nestjs/common';
import nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  private escapeHtml(value: string) {
    return value.replace(/[&<>'"]/g, (character) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;',
    })[character] ?? character);
  }

  async sendPasswordReset(to: string, name: string, token: string) {
    const required = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASSWORD', 'MAIL_FROM', 'PASSWORD_RESET_URL'] as const;
    const missing = required.filter((key) => !process.env[key]);
    if (missing.length) {
      if (process.env.NODE_ENV === 'production') throw new Error('SMTP não configurado.');
      this.logger.warn(`E-mail não enviado em desenvolvimento. Token de ${to}: ${token}`);
      return;
    }
    const transport = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT ?? 587),
      secure: process.env.SMTP_SECURE === 'true',
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD },
    });
    const resetUrl = new URL(process.env.PASSWORD_RESET_URL!);
    resetUrl.searchParams.set('token', token);
    const url = resetUrl.toString();
    const safeName = this.escapeHtml(name);
    await transport.sendMail({
      from: process.env.MAIL_FROM,
      to,
      subject: 'Redefinição de senha — Novva',
      text: `Olá, ${name}.\n\nRecebemos uma solicitação para redefinir sua senha da Novva. Acesse ${url}\n\nO link expira em 30 minutos e só pode ser usado uma vez. Se você não fez esta solicitação, ignore este e-mail.`,
      html: `<p>Olá, ${safeName}.</p><p>Recebemos uma solicitação para redefinir sua senha da Novva.</p><p><a href="${url}">Criar nova senha</a></p><p>O link expira em 30 minutos e só pode ser usado uma vez. Se você não fez esta solicitação, ignore este e-mail.</p>`,
    });
  }
}
