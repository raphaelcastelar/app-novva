import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { RequestKind } from '@prisma/client';
import { PrismaService } from '../../common/prisma.service';
import { AdminRequestQueryDto, AdminUpdateStatusDto } from './admin.dto';

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
  constructor(private readonly prisma: PrismaService) {}

  async listRequests(query: AdminRequestQueryDto) {
    const [documents, invoices] = await Promise.all([
      query.kind === 'INVOICE' ? [] : this.prisma.document.findMany({ include: { user: { include: { profile: true } } }, orderBy: { createdAt: 'desc' }, take: 500 }),
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
      this.prisma.document.findUnique({ where: { id }, include: { user: { include: { profile: true } } } }),
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
}
