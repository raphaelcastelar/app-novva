import nodemailer from 'nodemailer';
import { MailService } from '../src/common/mail.service';

describe('MailService', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = {
      ...originalEnv,
      NODE_ENV: 'production',
      SMTP_HOST: 'smtp.example.com',
      SMTP_PORT: '465',
      SMTP_SECURE: 'true',
      SMTP_USER: 'novva@example.com',
      SMTP_PASSWORD: 'secret',
      MAIL_FROM: 'Novva <novva@example.com>',
      PASSWORD_RESET_URL: 'https://api.example.com/redefinir-senha',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
    jest.restoreAllMocks();
  });

  it('sends a single-use reset link without exposing HTML from the user name', async () => {
    const sendMail = jest.fn().mockResolvedValue({ messageId: 'message-id' });
    const createTransport = jest.spyOn(nodemailer, 'createTransport')
      .mockReturnValue({ sendMail } as never);

    await new MailService().sendPasswordReset(
      'doctor@example.com',
      '<Matheus>',
      'token+/safe',
    );

    expect(createTransport).toHaveBeenCalledWith(expect.objectContaining({
      host: 'smtp.example.com', port: 465, secure: true,
    }));
    expect(sendMail).toHaveBeenCalledWith(expect.objectContaining({
      to: 'doctor@example.com',
      html: expect.stringContaining('&lt;Matheus&gt;'),
      text: expect.stringContaining('token%2B%2Fsafe'),
    }));
  });

  it('fails safely in production when SMTP configuration is incomplete', async () => {
    delete process.env.SMTP_PASSWORD;

    await expect(new MailService().sendPasswordReset('doctor@example.com', 'Doctor', 'token'))
      .rejects.toThrow('SMTP não configurado.');
  });
});
