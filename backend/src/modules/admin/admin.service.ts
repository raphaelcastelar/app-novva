import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { RequestKind } from '@prisma/client';
import { PrismaService } from '../../common/prisma.service';
import { StorageService } from '../../common/storage.service';
import { isValidCpf } from '../../common/validation';
import { AdminCreateDoctorDto, AdminCreateDocumentTypeDto, AdminRequestQueryDto, AdminUpdateDocumentTypeDto, AdminUpdateStatusDto } from './admin.dto';

const CLOSED_STATUSES = new Set(['APPROVED', 'ISSUED', 'REJECTED', 'CANCELED']);
const TRANSITIONS: Record<RequestKind, Record<string, string[]>> = {
  DOCUMENT: {
    PENDING: ['REVIEW', 'REJECTED'], SENT: ['REVIEW'], REVIEW: ['APPROVED', 'REJECTED'],
    REJECTED: ['REVIEW'], APPROVED: [],
  },
  INVOICE: {
    REQUESTED: ['PROCESSING', 'REJECTED', 'CANCELED'], PROCESSING: ['ISSUED', 'REJECTED', 'CANCELED'],
    REJECTED: ['PROCESSING'], ISSUED: [], CANCELED: [],
  },
};

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService, private readonly storage: StorageService) {}

  async listRequests(query: AdminRequestQueryDto) {
    const [documents, invoices] = await Promise.all([
      query.kind === 'INVOICE' ? [] : this.prisma.document.findMany({ include: { user: { include: { profile: true } }, documentType: true }, orderBy: { createdAt: 'desc' }, take: 500 }),
      query.kind === 'DOCUMENT' ? [] : this.prisma.invoice.findMany({ include: { user: { include: { profile: true } } }, orderBy: { createdAt: 'desc' }, take: 500 }),
    ]);
    const documentEvents = await this.events('DOCUMENT', documents.map((item) => item.id));
    const invoiceEvents = await this.events('INVOICE', invoices.map((item) => item.id));
    let results = [
      ...documents.map((item) => this.documentView(item, documentEvents.get(item.id) ?? [])),
      ...invoices.map((item) => this.invoiceView(item, invoiceEvents.get(item.id) ?? [])),
    ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    if (query.status === 'OPEN') results = results.filter((item) => !CLOSED_STATUSES.has(item.status));
    else if (query.status && query.status !== 'ALL') results = results.filter((item) => item.status === query.status);
    if (query.search) {
      const term = query.search.toLocaleLowerCase('pt-BR');
      results = results.filter((item) => [item.id, item.title, item.doctor.name, item.company]
        .some((value) => value.toLocaleLowerCase('pt-BR').includes(term)));
    }
    return { count: results.length, results };
  }

  async requestDetail(id: string) {
    const [document, invoice] = await Promise.all([
      this.prisma.document.findUnique({ where: { id }, include: { user: { include: { profile: true } }, documentType: true } }),
      this.prisma.invoice.findUnique({ where: { id }, include: { user: { include: { profile: true } } } }),
    ]);
    if (document) return this.documentView(document, await this.eventList('DOCUMENT', id));
    if (invoice) return this.invoiceView(invoice, await this.eventList('INVOICE', id));
    throw new NotFoundException('Solicitação não encontrada.');
  }

  async updateStatus(id: string, dto: AdminUpdateStatusDto, actor = 'Equipe Novva') {
    const [document, invoice] = await Promise.all([
      this.prisma.document.findUnique({ where: { id } }),
      this.prisma.invoice.findUnique({ where: { id } }),
    ]);
    const kind: RequestKind = document ? 'DOCUMENT' : 'INVOICE';
    const item = document ?? invoice;
    if (!item) throw new NotFoundException('Solicitação não encontrada.');
    const current = item.status;
    if (dto.status !== current && !(TRANSITIONS[kind][current] ?? []).includes(dto.status)) {
      throw new BadRequestException(`Transição de ${current} para ${dto.status} não permitida.`);
    }
    const notificationBody = dto.note?.trim() || `Sua solicitação foi atualizada para ${dto.status}.`;
    await this.prisma.$transaction(async (transaction) => {
      if (kind === 'DOCUMENT') await transaction.document.update({ where: { id }, data: { status: dto.status as any } });
      else await transaction.invoice.update({ where: { id }, data: { status: dto.status as any } });
      await transaction.requestEvent.create({ data: { requestKind: kind, requestId: id, status: dto.status, note: dto.note, actor } });
      await transaction.notification.create({ data: { userId: item.userId, title: 'Solicitação atualizada', body: notificationBody, kind: 'request_status' } });
      await transaction.auditLog.create({ data: { action: 'REQUEST_STATUS_UPDATED', entity: kind, entityId: id, metadata: { previousStatus: current, status: dto.status, note: dto.note ?? '', actor } } });
    });
    return this.requestDetail(id);
  }

  async storeDocumentFile(id: string, file: Express.Multer.File, actor = 'Equipe Novva') {
    const item = await this.prisma.document.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Solicitação de documento não encontrada.');
    const key = await this.storage.storeDocument(item.userId, id, file);
    try {
      await this.prisma.$transaction(async (transaction) => {
        await transaction.document.update({ where: { id }, data: { fileKey: key, mimeType: file.mimetype, originalName: file.originalname, fileUploadedAt: new Date() } });
        await transaction.requestEvent.create({ data: { requestKind: 'DOCUMENT', requestId: id, status: item.status, note: `Arquivo ${file.originalname} anexado`, actor } });
        await transaction.auditLog.create({ data: { action: 'DOCUMENT_FILE_ATTACHED', entity: 'DOCUMENT', entityId: id, metadata: { originalName: file.originalname, mimeType: file.mimetype, actor } } });
      });
      await this.storage.deleteDocument(item.fileKey);
      return this.requestDetail(id);
    } catch (error) {
      await this.storage.deleteDocument(key);
      throw error;
    }
  }

  async documentFile(id: string) {
    const item = await this.prisma.document.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Solicitação de documento não encontrada.');
    if (!item.fileKey || !item.mimeType || !item.originalName) throw new NotFoundException('Arquivo não enviado.');
    return { ...await this.storage.readDocument(item.fileKey), mimeType: item.mimeType, originalName: item.originalName };
  }

  async doctors(search?: string) {
    const users = await this.prisma.user.findMany({
      where: search ? { name: { contains: search, mode: 'insensitive' } } : undefined,
      include: { profile: true, _count: { select: { documents: true, invoices: true } }, documents: { select: { status: true } }, invoices: { select: { status: true } } },
      orderBy: { name: 'asc' },
    });
    return users.map((user) => ({
      id: user.id, name: user.name, initials: this.initials(user.name), crm: user.profile?.crm ?? '',
      specialty: user.profile?.specialty ?? '', email: user.email, company: user.profile?.companyName ?? '',
      requests: user._count.documents + user._count.invoices,
      open: [...user.documents, ...user.invoices].filter((request) => !CLOSED_STATUSES.has(request.status)).length,
      status: user.status,
    }));
  }

  async createDoctor(dto: AdminCreateDoctorDto, actor = 'Equipe Novva') {
    if (!isValidCpf(dto.cpf)) throw new BadRequestException('CPF inválido.');
    const email = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ cpf: dto.cpf }, { email: { equals: email, mode: 'insensitive' } }] },
      select: { cpf: true, email: true },
    });
    if (existing?.cpf === dto.cpf) throw new ConflictException('Já existe um médico com este CPF.');
    if (existing) throw new ConflictException('Já existe um médico com este e-mail.');

    const user = await this.prisma.$transaction(async (transaction) => {
      const created = await transaction.user.create({
        data: {
          cpf: dto.cpf,
          name: dto.name.trim(),
          email,
          phone: dto.phone?.trim() || null,
          profile: {
            create: {
              crm: dto.crm?.trim() || null,
              specialty: dto.specialty?.trim() || null,
              companyName: dto.companyName.trim(),
            },
          },
        },
        include: { profile: true },
      });
      await transaction.auditLog.create({
        data: {
          userId: created.id,
          action: 'DOCTOR_CREATED_BY_ADMIN',
          entity: 'User',
          entityId: created.id,
          metadata: { actor },
        },
      });
      return created;
    });
    return {
      id: user.id, name: user.name, initials: this.initials(user.name), crm: user.profile?.crm ?? '',
      specialty: user.profile?.specialty ?? '', email: user.email, company: user.profile?.companyName ?? '',
      requests: 0, open: 0, status: user.status, needsPasswordCreation: true,
    };
  }

  async documentTypes() {
    return this.prisma.documentType.findMany({ orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] });
  }

  async createDocumentType(dto: AdminCreateDocumentTypeDto, actor = 'Equipe Novva') {
    const name = dto.name.trim();
    const category = dto.category.trim();
    if (!name || !category) throw new BadRequestException('Nome e categoria são obrigatórios.');
    const duplicate = await this.prisma.documentType.findFirst({ where: { name: { equals: name, mode: 'insensitive' } } });
    if (duplicate) throw new ConflictException('Já existe um tipo de documento com esse nome.');
    const baseKey = this.slug(name) || 'documento';
    let key = baseKey;
    let suffix = 2;
    while (await this.prisma.documentType.findUnique({ where: { key } })) key = `${baseKey}-${suffix++}`;
    const item = await this.prisma.documentType.create({
      data: { key, name, category, validityMonths: dto.validityMonths ?? null, active: dto.active ?? true, sortOrder: dto.sortOrder ?? 0 },
    });
    await this.prisma.auditLog.create({ data: { action: 'DOCUMENT_TYPE_CREATED', entity: 'DocumentType', entityId: item.id, metadata: { actor } } });
    return item;
  }

  async updateDocumentType(id: string, dto: AdminUpdateDocumentTypeDto, actor = 'Equipe Novva') {
    const current = await this.prisma.documentType.findUnique({ where: { id } });
    if (!current) throw new NotFoundException('Tipo de documento não encontrado.');
    const name = dto.name?.trim();
    const category = dto.category?.trim();
    if (name === '' || category === '') throw new BadRequestException('Nome e categoria não podem ficar vazios.');
    if (name && name.toLocaleLowerCase('pt-BR') !== current.name.toLocaleLowerCase('pt-BR')) {
      const duplicate = await this.prisma.documentType.findFirst({ where: { id: { not: id }, name: { equals: name, mode: 'insensitive' } } });
      if (duplicate) throw new ConflictException('Já existe um tipo de documento com esse nome.');
    }
    const item = await this.prisma.documentType.update({
      where: { id },
      data: {
        ...(name !== undefined ? { name } : {}),
        ...(category !== undefined ? { category } : {}),
        ...('validityMonths' in dto ? { validityMonths: dto.validityMonths ?? null } : {}),
        ...(dto.active !== undefined ? { active: dto.active } : {}),
        ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
      },
    });
    await this.prisma.auditLog.create({ data: { action: 'DOCUMENT_TYPE_UPDATED', entity: 'DocumentType', entityId: id, metadata: { actor, changes: dto as any } } });
    return item;
  }

  async notices() {
    const items = await this.prisma.notice.findMany({
      include: { recipients: { include: { user: { include: { profile: true } } }, orderBy: { user: { name: 'asc' } } } },
      orderBy: { createdAt: 'desc' },
    });
    return items.map((item) => this.noticeView(item));
  }

  async createNotice(body: Record<string, string>, file?: Express.Multer.File, actor = 'Equipe Novva') {
    const payload = await this.noticePayload(body);
    const item = await this.prisma.notice.create({
      data: {
        title: payload.title, description: payload.description, active: payload.active, createdBy: actor,
        recipients: { create: payload.recipientIds.map((userId) => ({ userId })) },
      },
    });
    let storedKey: string | undefined;
    try {
      if (file) {
        storedKey = await this.storage.storeNotice(item.id, file);
        await this.prisma.notice.update({ where: { id: item.id }, data: { attachmentKey: storedKey, attachmentOriginalName: file.originalname, attachmentMimeType: file.mimetype } });
      }
      await this.prisma.auditLog.create({ data: { action: 'NOTICE_CREATED', entity: 'Notice', entityId: item.id, metadata: { actor, recipientCount: payload.recipientIds.length } } });
      return (await this.notices()).find((notice) => notice.id === item.id);
    } catch (error) {
      await this.prisma.notice.delete({ where: { id: item.id } }).catch(() => undefined);
      await this.storage.deleteDocument(storedKey);
      throw error;
    }
  }

  async updateNotice(id: string, body: Record<string, string>, file?: Express.Multer.File, actor = 'Equipe Novva') {
    const current = await this.prisma.notice.findUnique({ where: { id } });
    if (!current) throw new NotFoundException('Aviso não encontrado.');
    const payload = await this.noticePayload(body);
    let newKey: string | undefined;
    if (file) newKey = await this.storage.storeNotice(id, file);
    try {
      await this.prisma.$transaction(async (transaction) => {
        await transaction.notice.update({
          where: { id },
          data: {
            title: payload.title, description: payload.description, active: payload.active,
            ...(newKey ? { attachmentKey: newKey, attachmentOriginalName: file!.originalname, attachmentMimeType: file!.mimetype } : {}),
            ...(body.removeAttachment === 'true' && !newKey ? { attachmentKey: null, attachmentOriginalName: null, attachmentMimeType: null } : {}),
          },
        });
        await transaction.noticeRecipient.deleteMany({ where: { noticeId: id, userId: { notIn: payload.recipientIds } } });
        for (const userId of payload.recipientIds) {
          await transaction.noticeRecipient.upsert({
            where: { noticeId_userId: { noticeId: id, userId } }, update: {}, create: { noticeId: id, userId },
          });
        }
        await transaction.auditLog.create({ data: { action: 'NOTICE_UPDATED', entity: 'Notice', entityId: id, metadata: { actor, recipientCount: payload.recipientIds.length } } });
      });
      if ((newKey || body.removeAttachment === 'true') && current.attachmentKey) await this.storage.deleteDocument(current.attachmentKey);
      return (await this.notices()).find((notice) => notice.id === id);
    } catch (error) {
      if (newKey) await this.storage.deleteDocument(newKey);
      throw error;
    }
  }

  async removeNotice(id: string, actor = 'Equipe Novva') {
    const item = await this.prisma.notice.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Aviso não encontrado.');
    await this.prisma.$transaction(async (transaction) => {
      await transaction.notice.delete({ where: { id } });
      await transaction.auditLog.create({ data: { action: 'NOTICE_DELETED', entity: 'Notice', entityId: id, metadata: { actor } } });
    });
    await this.storage.deleteDocument(item.attachmentKey);
  }

  async noticeFile(id: string) {
    const item = await this.prisma.notice.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Aviso não encontrado.');
    if (!item.attachmentKey || !item.attachmentMimeType || !item.attachmentOriginalName) throw new NotFoundException('Aviso sem anexo.');
    return { ...await this.storage.readDocument(item.attachmentKey), mimeType: item.attachmentMimeType, originalName: item.attachmentOriginalName };
  }

  private async noticePayload(body: Record<string, string>) {
    const title = (body.title ?? '').trim();
    const description = (body.description ?? '').trim();
    if (!title || !description) throw new BadRequestException('Título e descrição são obrigatórios.');
    if (title.length > 160) throw new BadRequestException('O título deve ter no máximo 160 caracteres.');
    let recipientIds: string[];
    try { recipientIds = JSON.parse(body.recipientIds ?? '[]'); } catch { throw new BadRequestException('Destinatários inválidos.'); }
    if (!Array.isArray(recipientIds)) throw new BadRequestException('Destinatários inválidos.');
    recipientIds = [...new Set(recipientIds)].filter((value) => typeof value === 'string');
    if (!recipientIds.length) throw new BadRequestException('Selecione ao menos um médico.');
    const count = await this.prisma.user.count({ where: { id: { in: recipientIds }, status: 'ACTIVE' } });
    if (count !== recipientIds.length) throw new BadRequestException('Um ou mais destinatários são inválidos ou estão bloqueados.');
    return { title, description, recipientIds, active: body.active !== 'false' };
  }

  private noticeView(item: any) {
    return {
      id: item.id, title: item.title, description: item.description, active: item.active,
      attachment: item.attachmentKey ? { originalName: item.attachmentOriginalName, mimeType: item.attachmentMimeType } : null,
      recipients: item.recipients.map((recipient: any) => ({ id: recipient.user.id, name: recipient.user.name, email: recipient.user.email, company: recipient.user.profile?.companyName ?? '', status: recipient.user.status, readAt: recipient.readAt })),
      recipientCount: item.recipients.length, readCount: item.recipients.filter((recipient: any) => recipient.readAt).length,
      createdBy: item.createdBy, createdAt: item.createdAt, updatedAt: item.updatedAt,
    };
  }

  async dashboard() {
    const { results } = await this.listRequests({});
    const now = new Date();
    const dayKey = (date: Date) => date.toISOString().slice(0, 10);
    const volume = Array.from({ length: 7 }, (_, index) => {
      const day = new Date(now); day.setUTCDate(now.getUTCDate() - (6 - index));
      return results.filter((item) => dayKey(new Date(item.createdAt)) === dayKey(day)).length;
    });
    const open = results.filter((item) => !CLOSED_STATUSES.has(item.status));
    const completedToday = results.filter((item) => ['APPROVED', 'ISSUED'].includes(item.status) && dayKey(new Date(item.updatedAt)) === dayKey(now)).length;
    const documents = results.filter((item) => item.kind === 'DOCUMENT').length;
    const invoices = results.length - documents;
    return {
      metrics: { open: open.length, urgent: open.filter((item) => item.priority === 'HIGH').length, completedToday, averageTime: '—' },
      volume,
      categories: [
        { label: 'Notas fiscais', value: invoices, color: '#0b7558' },
        { label: 'Documentos', value: documents, color: '#28a77c' },
      ],
      team: [], recent: results.slice(0, 5),
    };
  }

  private async events(kind: RequestKind, ids: string[]) {
    const grouped = new Map<string, any[]>();
    if (!ids.length) return grouped;
    const events = await this.prisma.requestEvent.findMany({ where: { requestKind: kind, requestId: { in: ids } }, orderBy: { createdAt: 'asc' } });
    for (const event of events) grouped.set(event.requestId, [...(grouped.get(event.requestId) ?? []), event]);
    return grouped;
  }

  private eventList(kind: RequestKind, id: string) {
    return this.prisma.requestEvent.findMany({ where: { requestKind: kind, requestId: id }, orderBy: { createdAt: 'asc' } });
  }

  private timeline(createdAt: Date, events: any[]) {
    return [
      { label: 'Solicitação recebida pelo app', at: createdAt, done: true },
      ...events.map((event) => ({ label: event.note || `Status atualizado para ${event.status}`, at: event.createdAt, done: true })),
    ];
  }

  private doctor(user: any) {
    return { id: user.id, name: user.name, initials: this.initials(user.name), crm: user.profile?.crm ?? '', company: user.profile?.companyName ?? '' };
  }

  documentView(item: any, events: any[]) {
    return {
      uuid: item.id, id: `DOC-${item.id.slice(0, 8).toUpperCase()}`, kind: 'DOCUMENT', title: item.title,
      doctor: this.doctor(item.user), company: item.user.profile?.companyName ?? '', amount: null,
      status: item.status, priority: 'NORMAL', createdAt: item.createdAt, updatedAt: item.updatedAt,
      dueAt: new Date(item.createdAt.getTime() + 24 * 60 * 60 * 1000), category: item.category,
      description: item.description ?? '', details: { Categoria: item.category, Competência: item.month && item.year ? `${String(item.month).padStart(2, '0')}/${item.year}` : 'Não informada' },
      attachment: item.fileKey ? { originalName: item.originalName, mimeType: item.mimeType, uploadedAt: item.fileUploadedAt } : null,
      documentType: item.documentType ? { id: item.documentType.id, name: item.documentType.name, validityMonths: item.documentType.validityMonths } : null,
      timeline: this.timeline(item.createdAt, events),
    };
  }

  private invoiceView(item: any, events: any[]) {
    return {
      uuid: item.id, id: `NFS-${item.id.slice(0, 8).toUpperCase()}`, kind: 'INVOICE', title: 'Emissão de nota fiscal',
      doctor: this.doctor(item.user), company: item.user.profile?.companyName ?? '', amount: Number(item.amount),
      status: item.status, priority: 'NORMAL', createdAt: item.createdAt, updatedAt: item.updatedAt,
      dueAt: new Date(item.createdAt.getTime() + 8 * 60 * 60 * 1000), category: '', description: item.description,
      details: { 'CNPJ do tomador': item.takerCnpj, Município: item.municipality, 'Data do serviço': item.serviceDate.toISOString().slice(0, 10), 'Código de tributação': item.taxationCode },
      timeline: this.timeline(item.createdAt, events),
    };
  }

  private initials(name: string) { return name.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join('').toUpperCase(); }
  private slug(value: string) { return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, ''); }
}
