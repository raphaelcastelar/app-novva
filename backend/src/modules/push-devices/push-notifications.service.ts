import { Injectable, Logger } from '@nestjs/common';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { BatchResponse, getMessaging } from 'firebase-admin/messaging';
import { PrismaService } from '../../common/prisma.service';
import { RegisterPushDeviceDto } from './push-device.dto';

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

@Injectable()
export class PushNotificationsService {
  private readonly logger = new Logger(PushNotificationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  registerDevice(userId: string, dto: RegisterPushDeviceDto) {
    const token = dto.token.trim();
    return this.prisma.pushDevice.upsert({
      where: { token },
      update: {
        userId,
        platform: dto.platform,
        appVersion: dto.appVersion?.trim() || null,
        deviceId: dto.deviceId?.trim() || null,
        enabled: true,
        lastSeenAt: new Date(),
      },
      create: {
        userId,
        token,
        platform: dto.platform,
        appVersion: dto.appVersion?.trim() || null,
        deviceId: dto.deviceId?.trim() || null,
      },
      select: { id: true, platform: true, enabled: true, lastSeenAt: true },
    });
  }

  async removeDevice(userId: string, token: string) {
    await this.prisma.pushDevice.updateMany({
      where: { userId, token: token.trim() },
      data: { enabled: false },
    });
  }

  async sendDocumentAvailable(input: {
    userId: string;
    documentId: string;
    documentTitle: string;
    body: string;
    notificationId: string;
  }) {
    if (process.env.PUSH_NOTIFICATIONS_ENABLED !== 'true') {
      this.logger.debug('Push ignorado porque PUSH_NOTIFICATIONS_ENABLED não está ativo.');
      return;
    }

    try {
      this.ensureFirebaseApp();
      const devices = await this.prisma.pushDevice.findMany({
        where: { userId: input.userId, enabled: true },
        select: { token: true },
      });
      if (devices.length === 0) return;

      const tokens = devices.map((device) => device.token);
      for (let offset = 0; offset < tokens.length; offset += 500) {
        const batchTokens = tokens.slice(offset, offset + 500);
        const response = await getMessaging().sendEachForMulticast({
          tokens: batchTokens,
          notification: {
            title: 'Documento disponível',
            body: input.body,
          },
          data: {
            type: 'document_available',
            entityId: input.documentId,
            notificationId: input.notificationId,
          },
          apns: { payload: { aps: { sound: 'default' } } },
        });
        await this.disableInvalidTokens(batchTokens, response);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Falha ao enviar notificação do documento ${input.documentId}: ${message}`);
    }
  }

  private ensureFirebaseApp() {
    if (getApps().length > 0) return;
    const encodedAccount = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    if (encodedAccount) {
      const account = JSON.parse(Buffer.from(encodedAccount, 'base64').toString('utf8'));
      initializeApp({ credential: cert(account) });
      return;
    }
    initializeApp({
      credential: cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
  }

  private async disableInvalidTokens(tokens: string[], response: BatchResponse) {
    const invalidTokens = response.responses.flatMap((result, index) =>
      !result.success && result.error && INVALID_TOKEN_CODES.has(result.error.code)
        ? [tokens[index]]
        : [],
    );
    if (invalidTokens.length === 0) return;
    await this.prisma.pushDevice.updateMany({
      where: { token: { in: invalidTokens } },
      data: { enabled: false },
    });
  }
}
