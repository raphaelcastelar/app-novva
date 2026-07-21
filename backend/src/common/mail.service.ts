import { Injectable, Logger } from '@nestjs/common';
import nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  async sendPasswordReset(to: string, name: string, token: string) {
    if (!process.env.SMTP_HOST) {
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
    const url = `${process.env.PASSWORD_RESET_URL}?token=${encodeURIComponent(token)}`;
    await transport.sendMail({
      from: process.env.MAIL_FROM,
      to,
      subject: 'Redefinição de senha — Novva',
      text: `Olá, ${name}. Redefina sua senha pelo link: ${url}. O link expira em 30 minutos.`,
    });
  }
}
