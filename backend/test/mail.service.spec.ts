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

  it('sends through Google Apps Script over HTTPS when selected', async () => {
    process.env.MAIL_DRIVER = 'google_apps_script';
    process.env.GOOGLE_APPS_SCRIPT_URL = 'https://script.google.com/macros/s/deployment/exec';
    process.env.GOOGLE_APPS_SCRIPT_SECRET = 'a-secure-shared-secret';
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), { status: 200 }),
    );

    await new MailService().sendPasswordReset('doctor@example.com', 'Doctor', 'safe-token');

    expect(fetchMock).toHaveBeenCalledWith(
      process.env.GOOGLE_APPS_SCRIPT_URL,
      expect.objectContaining({ method: 'POST', redirect: 'follow' }),
    );
    const request = fetchMock.mock.calls[0][1];
    const body = JSON.parse(String(request?.body));
    expect(body).toEqual(expect.objectContaining({
      secret: 'a-secure-shared-secret',
      to: 'doctor@example.com',
      name: 'Doctor',
    }));
    expect(body.resetUrl).toContain('token=safe-token');
  });
});
