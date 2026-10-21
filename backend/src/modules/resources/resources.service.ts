import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../common/prisma.service';
import { SerproService } from '../../common/serpro.service';
import { isValidCnpj } from '../../common/validation';
import { ConfirmDocumentUploadDto, CreateDocumentDto, CreateInvoiceDto, DocumentUploadDto, GenerateObligationDto, PageDto, SaveInvoiceDraftDto } from './resources.dto';
import { StorageService } from '../../common/storage.service';

@Injectable()
export class ResourcesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly serpro: SerproService,
  ) {}
  private paging(q: PageDto) { return { skip: (q.page - 1) * q.limit, take: q.limit }; }
  private async page<T>(items: T[], total: number, q: PageDto) { return { items, meta: { page: q.page, limit: q.limit, total, pages: Math.ceil(total / q.limit) } }; }
  async documentTypes() {
    return this.prisma.documentType.findMany({
      where: { active: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      select: { id: true, key: true, name: true, category: true, validityMonths: true },
    });
  }
  async documents(userId: string, q: PageDto) { const where = { userId }; const [items,total] = await this.prisma.$transaction([this.prisma.document.findMany({ where, include:{documentType:true}, ...this.paging(q), orderBy:{createdAt:'desc'} }),this.prisma.document.count({where})]); return this.page(items.map((item) => this.documentView(item)),total,q); }
  async createDocument(userId: string, dto: CreateDocumentDto) {
    const documentType = dto.documentTypeId
      ? await this.prisma.documentType.findFirst({ where: { id: dto.documentTypeId, active: true } })
      : null;
    if (dto.documentTypeId && !documentType) throw new BadRequestException('Tipo de documento indisponível.');
    const { documentTypeId: _documentTypeId, ...legacyData } = dto;
    const item = await this.prisma.document.create({
      data: {
        userId,
        ...legacyData,
        ...(documentType ? {
          documentTypeId: documentType.id,
          title: documentType.name,
          category: documentType.category,
        } : {}),
      },
      include: { documentType: true },
    });
    await this.prisma.requestEvent.create({ data: { requestKind: 'DOCUMENT', requestId: item.id, status: item.status, note: 'Solicitação recebida pelo app' } });
    return this.documentView(item);
  }
  async document(userId: string, id: string) { return this.documentView(await this.ownedDocument(userId, id)); }
  async documentUploadUrl(userId:string,id:string,dto:DocumentUploadDto){await this.ownedDocument(userId,id);return this.storage.uploadUrl(userId,id,dto.originalName,dto.mimeType);}
  async confirmDocumentUpload(userId:string,id:string,dto:ConfirmDocumentUploadDto){await this.ownedDocument(userId,id);const prefix=`users/${userId}/documents/${id}/`;if(!dto.key.startsWith(prefix))throw new BadRequestException('Chave de arquivo inválida.');return this.prisma.document.update({where:{id},data:{fileKey:dto.key,mimeType:dto.mimeType,originalName:dto.originalName,fileUploadedAt:new Date(),status:'SENT'},include:{documentType:true}}).then((item) => this.documentView(item));}
  async documentDownloadUrl(userId:string,id:string){const item=await this.ownedDocument(userId,id);if(!item.fileKey)throw new NotFoundException('Arquivo não enviado.');return this.storage.downloadUrl(item.fileKey);}
  async storeDocumentFile(userId: string, id: string, file: Express.Multer.File) {
    const item = await this.ownedDocument(userId, id);
    const key = await this.storage.storeDocument(userId, id, file);
    try {
      const updated = await this.prisma.$transaction(async (transaction) => {
        const document = await transaction.document.update({ where: { id }, data: { fileKey: key, mimeType: file.mimetype, originalName: file.originalname, fileUploadedAt: new Date(), status: 'SENT' }, include: { documentType: true } });
        await transaction.requestEvent.create({ data: { requestKind: 'DOCUMENT', requestId: id, status: 'SENT', note: 'Arquivo enviado pelo aplicativo' } });
        return document;
      });
      await this.storage.deleteDocument(item.fileKey);
      return this.documentView(updated);
    } catch (error) {
      await this.storage.deleteDocument(key);
      throw error;
    }
  }
  async documentFile(userId: string, id: string) {
    const item = await this.ownedDocument(userId, id);
    if (!item.fileKey || !item.mimeType || !item.originalName) throw new NotFoundException('Arquivo não enviado.');
    return { ...await this.storage.readDocument(item.fileKey), mimeType: item.mimeType, originalName: item.originalName };
  }
  async obligations(userId: string, q: PageDto) { const where={userId}; const [items,total]=await this.prisma.$transaction([this.prisma.obligation.findMany({where,...this.paging(q),orderBy:{dueDate:'desc'}}),this.prisma.obligation.count({where})]); return this.page(items.map((item) => this.obligationView(item)),total,q); }
  async generateObligation(userId: string, dto: GenerateObligationDto) {
    const competenceStart = new Date(Date.UTC(dto.year, dto.month - 1, 1));
    const competenceEnd = new Date(Date.UTC(dto.year, dto.month, 1));
    const existing = await this.prisma.obligation.findFirst({
      where: {
        userId,
        kind: 'DAS',
        OR: [
          { competenceYear: dto.year, competenceMonth: dto.month },
          {
            competenceYear: null,
            competenceMonth: null,
            dueDate: { gte: competenceStart, lt: competenceEnd },
          },
        ],
      },
    });
    if (existing?.pdfKey) {
      throw new BadRequestException('A guia já foi gerada. Use a opção Recalcular guia.');
    }
    return this.issueDas(userId, dto, existing);
  }
  async recalculateObligation(userId: string, id: string) {
    const item = await this.owned(
      this.prisma.obligation.findFirst({ where: { id, userId, kind: 'DAS' } }),
      'Guia',
    );
    if (!item.pdfKey) {
      throw new BadRequestException('Gere a guia antes de recalculá-la.');
    }
    return this.issueDas(userId, {
      month: item.competenceMonth ?? item.dueDate.getUTCMonth() + 1,
      year: item.competenceYear ?? item.dueDate.getUTCFullYear(),
    }, item);
  }
  obligation(userId:string,id:string){return this.owned(this.prisma.obligation.findFirst({where:{id,userId}}),'Obrigação').then((item) => this.obligationView(item));}
  async obligationFile(userId:string,id:string){const item=await this.owned(this.prisma.obligation.findFirst({where:{id,userId}}),'Obrigação');if(!item.pdfKey)throw new NotFoundException('Guia ainda não disponível.');const year=item.competenceYear??item.dueDate.getUTCFullYear();const month=item.competenceMonth??item.dueDate.getUTCMonth()+1;return {...await this.storage.readDocument(item.pdfKey),originalName:`DAS-${year}-${String(month).padStart(2,'0')}.pdf`};}
  async markObligationPaid(userId:string,id:string){await this.obligation(userId,id);return this.prisma.obligation.update({where:{id},data:{status:'PAID',paidAt:new Date()}}).then((item) => this.obligationView(item));}
  async invoices(userId:string,q:PageDto){const where={userId};const [items,total]=await this.prisma.$transaction([this.prisma.invoice.findMany({where,...this.paging(q),orderBy:{createdAt:'desc'}}),this.prisma.invoice.count({where})]);return this.page(items.map(this.decimal),total,q);}
  async createInvoice(userId:string,dto:CreateInvoiceDto){
    if(!isValidCnpj(dto.takerCnpj))throw new BadRequestException('CNPJ do tomador inválido.');
    const item=await this.prisma.invoice.create({data:{userId,...dto,serviceDate:new Date(dto.serviceDate)}});
    await this.prisma.requestEvent.create({data:{requestKind:'INVOICE',requestId:item.id,status:item.status,note:'Solicitação recebida pelo app'}});
    await this.prisma.invoiceDraft.deleteMany({where:{userId}});
    return this.decimal(item);
  }
  invoice(userId:string,id:string){return this.owned(this.prisma.invoice.findFirst({where:{id,userId}}),'Nota fiscal').then(this.decimal);}
  async invoiceDraft(userId:string){const item=await this.prisma.invoiceDraft.findUnique({where:{userId}});return item?this.decimal(item):null;}
  async saveInvoiceDraft(userId:string,dto:SaveInvoiceDraftDto){
    if(!isValidCnpj(dto.takerCnpj))throw new BadRequestException('CNPJ do tomador inválido.');
    const data={takerCnpj:dto.takerCnpj,takerName:dto.takerName,municipality:dto.municipality,serviceDate:new Date(dto.serviceDate),amount:dto.amount,taxationCode:dto.taxationCode,description:dto.description};
    const item=await this.prisma.invoiceDraft.upsert({where:{userId},create:{userId,...data},update:data});
    return this.decimal(item);
  }
  deleteInvoiceDraft(userId:string){return this.prisma.invoiceDraft.deleteMany({where:{userId}});}
  invoiceDescriptionFavorites(userId:string){return this.prisma.invoiceDescriptionFavorite.findMany({where:{userId},orderBy:{createdAt:'asc'}});}
  favoriteInvoiceDescription(userId:string,description:string){const value=description.trim();return this.prisma.invoiceDescriptionFavorite.upsert({where:{userId_description:{userId,description:value}},create:{userId,description:value},update:{}});}
  async removeInvoiceDescriptionFavorite(userId:string,id:string){await this.owned(this.prisma.invoiceDescriptionFavorite.findFirst({where:{id,userId}}),'Favorito');await this.prisma.invoiceDescriptionFavorite.delete({where:{id}});}
  async payments(userId:string,q:PageDto){const where={userId};const [items,total]=await this.prisma.$transaction([this.prisma.payment.findMany({where,...this.paging(q),orderBy:{dueDate:'desc'}}),this.prisma.payment.count({where})]);return this.page(items.map(this.decimal),total,q);}
  async reports(userId:string){const [paid,open,invoices]=await Promise.all([this.prisma.payment.aggregate({where:{userId,status:'PAID'},_sum:{amount:true},_count:true}),this.prisma.payment.aggregate({where:{userId,status:{in:['OPEN','OVERDUE']}},_sum:{amount:true},_count:true}),this.prisma.invoice.aggregate({where:{userId,status:'ISSUED'},_sum:{amount:true},_count:true})]);return {paid:{count:paid._count,total:Number(paid._sum.amount??0)},open:{count:open._count,total:Number(open._sum.amount??0)},invoices:{count:invoices._count,total:Number(invoices._sum.amount??0)}};}
  async messages(userId:string,q:PageDto){const conversation=await this.prisma.conversation.upsert({where:{userId},create:{userId},update:{}});const where={conversationId:conversation.id};const [items,total]=await this.prisma.$transaction([this.prisma.message.findMany({where,...this.paging(q),orderBy:{createdAt:'desc'}}),this.prisma.message.count({where})]);return this.page(items,total,q);}
  async sendMessage(userId:string,body:string){const conversation=await this.prisma.conversation.upsert({where:{userId},create:{userId},update:{}});return this.prisma.message.create({data:{conversationId:conversation.id,sender:'USER',body}});}
  async notifications(userId:string,q:PageDto){const where={userId};const [items,total,unread]=await this.prisma.$transaction([this.prisma.notification.findMany({where,...this.paging(q),orderBy:{createdAt:'desc'}}),this.prisma.notification.count({where}),this.prisma.notification.count({where:{userId,readAt:null}})]);return {...await this.page(items,total,q),unread};}
  async readNotification(userId:string,id:string){await this.owned(this.prisma.notification.findFirst({where:{id,userId}}),'Notificação');return this.prisma.notification.update({where:{id},data:{readAt:new Date()}});}
  async readAllNotifications(userId:string){await this.prisma.notification.updateMany({where:{userId,readAt:null},data:{readAt:new Date()}});}
  private async owned<T>(promise:Promise<T|null>,label:string){const item=await promise;if(!item)throw new NotFoundException(`${label} não encontrado.`);return item;}
  private ownedDocument(userId: string, id: string) { return this.owned(this.prisma.document.findFirst({ where: { id, userId }, include: { documentType: true } }), 'Documento'); }
  private documentView(item: any) {
    const { fileKey: _fileKey, documentType, ...data } = item;
    const validityMonths = documentType?.validityMonths ?? null;
    const expiresAt = item.fileUploadedAt && validityMonths
      ? this.addMonths(item.fileUploadedAt, validityMonths)
      : null;
    return {
      ...data,
      documentType: documentType ? {
        id: documentType.id, key: documentType.key, name: documentType.name,
        category: documentType.category, validityMonths,
      } : null,
      validityMonths,
      expiresAt,
      possiblyExpired: Boolean(expiresAt && expiresAt.getTime() < Date.now()),
      hasFile: Boolean(_fileKey),
    };
  }
  private addMonths(value: Date, months: number) {
    const result = new Date(value);
    const day = result.getUTCDate();
    result.setUTCDate(1);
    result.setUTCMonth(result.getUTCMonth() + months);
    const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
    result.setUTCDate(Math.min(day, lastDay));
    return result;
  }
  private async issueDas(
    userId: string,
    dto: GenerateObligationDto,
    existing: { id: string; pdfKey: string | null } | null,
  ) {
    const company = await this.prisma.cnpj.findFirst({
      where: { userId, active: true },
      select: { cnpj: true },
    });
    if (!company) {
      throw new BadRequestException('Selecione um CNPJ ativo antes de gerar a guia.');
    }
    const period = `${dto.year}${String(dto.month).padStart(2, '0')}`;
    const generated = await this.serpro.generateDas(company.cnpj, period);
    const obligationId = existing?.id ?? randomUUID();
    const newKey = await this.storage.storeObligationPdf(userId, obligationId, generated.content);
    const dueDate = new Date(Date.UTC(dto.year, dto.month, 20));
    const status = this.obligationStatusFor(dueDate);
    const item = await this.prisma.$transaction(async (transaction) => {
        const obligation = existing
          ? await transaction.obligation.update({
              where: { id: existing.id },
              data: {
                name: 'DAS Simples Nacional',
                competenceMonth: dto.month,
                competenceYear: dto.year,
                dueDate,
                amount: 0,
                status,
                paymentCode: null,
                pdfKey: newKey,
                generatedAt: new Date(),
                paidAt: null,
              },
            })
          : await transaction.obligation.create({
              data: {
                id: obligationId,
                userId,
                name: 'DAS Simples Nacional',
                kind: 'DAS',
                competenceMonth: dto.month,
                competenceYear: dto.year,
                dueDate,
                amount: 0,
                status,
                pdfKey: newKey,
                generatedAt: new Date(),
              },
            });
        await transaction.notification.create({
          data: {
            userId,
            title: existing ? 'Guia recalculada' : 'Guia gerada',
            body: `O DAS de ${String(dto.month).padStart(2, '0')}/${dto.year} está disponível para download.`,
            kind: existing ? 'obligation_recalculated' : 'obligation_generated',
          },
        });
        return obligation;
      }).catch(async (error) => {
      await this.storage.deleteDocument(newKey);
      throw error;
    });
    await this.storage.deleteDocument(existing?.pdfKey).catch(() => undefined);
    return this.obligationView(item);
  }
  private obligationStatusFor(dueDate: Date) {
    const today = new Date();
    const todayUtc = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
    const differenceDays = Math.ceil((dueDate.getTime() - todayUtc) / 86_400_000);
    if (differenceDays < 0) return 'OVERDUE' as const;
    if (differenceDays <= 10) return 'DUE_SOON' as const;
    return 'OPEN' as const;
  }
  private obligationView<T extends { amount: any; pdfKey?: string | null }>(item: T) { const { pdfKey: _pdfKey, ...data } = item; return { ...data, amount: Number(item.amount), hasFile: Boolean(_pdfKey) }; }
  private decimal<T extends {amount:any}>(item:T){return {...item,amount:Number(item.amount)};}
}
