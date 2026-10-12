import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { StorageService } from '../../common/storage.service';

@Injectable()
export class NoticesService {
  constructor(private readonly prisma: PrismaService, private readonly storage: StorageService) {}

  async list(userId: string) {
    const recipients = await this.prisma.noticeRecipient.findMany({
      where: { userId, notice: { active: true } }, include: { notice: true }, orderBy: { notice: { createdAt: 'desc' } },
    });
    return recipients.map(({ notice, readAt }) => ({
      id: notice.id, title: notice.title, description: notice.description, createdAt: notice.createdAt,
      isRead: Boolean(readAt), readAt, hasAttachment: Boolean(notice.attachmentKey), attachmentOriginalName: notice.attachmentOriginalName,
    }));
  }

  async markRead(userId: string, noticeId: string) {
    const recipient = await this.owned(userId, noticeId);
    if (!recipient.readAt) await this.prisma.noticeRecipient.update({ where: { noticeId_userId: { noticeId, userId } }, data: { readAt: new Date() } });
    return { read: true };
  }

  async file(userId: string, noticeId: string) {
    const { notice } = await this.owned(userId, noticeId);
    if (!notice.attachmentKey || !notice.attachmentMimeType || !notice.attachmentOriginalName) throw new NotFoundException('Aviso sem anexo.');
    return { ...await this.storage.readDocument(notice.attachmentKey), mimeType: notice.attachmentMimeType, originalName: notice.attachmentOriginalName };
  }

  private async owned(userId: string, noticeId: string) {
    const item = await this.prisma.noticeRecipient.findUnique({ where: { noticeId_userId: { noticeId, userId } }, include: { notice: true } });
    if (!item || !item.notice.active) throw new NotFoundException('Aviso não encontrado.');
    return item;
  }
}
