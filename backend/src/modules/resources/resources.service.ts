import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { isValidCnpj } from '../../common/validation';
import { ConfirmDocumentUploadDto, CreateDocumentDto, CreateInvoiceDto, DocumentUploadDto, PageDto } from './resources.dto';
import { StorageService } from '../../common/storage.service';

@Injectable()
export class ResourcesService {
  constructor(private readonly prisma: PrismaService, private readonly storage: StorageService) {}
  private paging(q: PageDto) { return { skip: (q.page - 1) * q.limit, take: q.limit }; }
  private async page<T>(items: T[], total: number, q: PageDto) { return { items, meta: { page: q.page, limit: q.limit, total, pages: Math.ceil(total / q.limit) } }; }
  async documents(userId: string, q: PageDto) { const where = { userId }; const [items,total] = await this.prisma.$transaction([this.prisma.document.findMany({ where, ...this.paging(q), orderBy:{createdAt:'desc'} }),this.prisma.document.count({where})]); return this.page(items.map((item) => this.documentView(item)),total,q); }
  async createDocument(userId: string, dto: CreateDocumentDto) {
    const item = await this.prisma.document.create({ data: { userId, ...dto } });
    await this.prisma.requestEvent.create({ data: { requestKind: 'DOCUMENT', requestId: item.id, status: item.status, note: 'Solicitação recebida pelo app' } });
    return this.documentView(item);
  }
  async document(userId: string, id: string) { return this.documentView(await this.ownedDocument(userId, id)); }
  async documentUploadUrl(userId:string,id:string,dto:DocumentUploadDto){await this.ownedDocument(userId,id);return this.storage.uploadUrl(userId,id,dto.originalName,dto.mimeType);}
  async confirmDocumentUpload(userId:string,id:string,dto:ConfirmDocumentUploadDto){await this.ownedDocument(userId,id);const prefix=`users/${userId}/documents/${id}/`;if(!dto.key.startsWith(prefix))throw new BadRequestException('Chave de arquivo inválida.');return this.prisma.document.update({where:{id},data:{fileKey:dto.key,mimeType:dto.mimeType,originalName:dto.originalName,status:'SENT'}}).then((item) => this.documentView(item));}
  async documentDownloadUrl(userId:string,id:string){const item=await this.ownedDocument(userId,id);if(!item.fileKey)throw new NotFoundException('Arquivo não enviado.');return this.storage.downloadUrl(item.fileKey);}
  async storeDocumentFile(userId: string, id: string, file: Express.Multer.File) {
    const item = await this.ownedDocument(userId, id);
    const key = await this.storage.storeDocument(userId, id, file);
    try {
      const updated = await this.prisma.$transaction(async (transaction) => {
        const document = await transaction.document.update({ where: { id }, data: { fileKey: key, mimeType: file.mimetype, originalName: file.originalname, status: 'SENT' } });
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
  async obligations(userId: string, q: PageDto) { const where={userId}; const [items,total]=await this.prisma.$transaction([this.prisma.obligation.findMany({where,...this.paging(q),orderBy:{dueDate:'desc'}}),this.prisma.obligation.count({where})]); return this.page(items.map(this.decimal),total,q); }
  obligation(userId:string,id:string){return this.owned(this.prisma.obligation.findFirst({where:{id,userId}}),'Obrigação').then(this.decimal);}
  async markObligationPaid(userId:string,id:string){await this.obligation(userId,id);return this.prisma.obligation.update({where:{id},data:{status:'PAID',paidAt:new Date()}}).then(this.decimal);}
  async invoices(userId:string,q:PageDto){const where={userId};const [items,total]=await this.prisma.$transaction([this.prisma.invoice.findMany({where,...this.paging(q),orderBy:{createdAt:'desc'}}),this.prisma.invoice.count({where})]);return this.page(items.map(this.decimal),total,q);}
  async createInvoice(userId:string,dto:CreateInvoiceDto){
    if(!isValidCnpj(dto.takerCnpj))throw new BadRequestException('CNPJ do tomador inválido.');
    const item=await this.prisma.invoice.create({data:{userId,...dto,serviceDate:new Date(dto.serviceDate)}});
    await this.prisma.requestEvent.create({data:{requestKind:'INVOICE',requestId:item.id,status:item.status,note:'Solicitação recebida pelo app'}});
    return this.decimal(item);
  }
  invoice(userId:string,id:string){return this.owned(this.prisma.invoice.findFirst({where:{id,userId}}),'Nota fiscal').then(this.decimal);}
  async payments(userId:string,q:PageDto){const where={userId};const [items,total]=await this.prisma.$transaction([this.prisma.payment.findMany({where,...this.paging(q),orderBy:{dueDate:'desc'}}),this.prisma.payment.count({where})]);return this.page(items.map(this.decimal),total,q);}
  async reports(userId:string){const [paid,open,invoices]=await Promise.all([this.prisma.payment.aggregate({where:{userId,status:'PAID'},_sum:{amount:true},_count:true}),this.prisma.payment.aggregate({where:{userId,status:{in:['OPEN','OVERDUE']}},_sum:{amount:true},_count:true}),this.prisma.invoice.aggregate({where:{userId,status:'ISSUED'},_sum:{amount:true},_count:true})]);return {paid:{count:paid._count,total:Number(paid._sum.amount??0)},open:{count:open._count,total:Number(open._sum.amount??0)},invoices:{count:invoices._count,total:Number(invoices._sum.amount??0)}};}
  async messages(userId:string,q:PageDto){const conversation=await this.prisma.conversation.upsert({where:{userId},create:{userId},update:{}});const where={conversationId:conversation.id};const [items,total]=await this.prisma.$transaction([this.prisma.message.findMany({where,...this.paging(q),orderBy:{createdAt:'desc'}}),this.prisma.message.count({where})]);return this.page(items,total,q);}
  async sendMessage(userId:string,body:string){const conversation=await this.prisma.conversation.upsert({where:{userId},create:{userId},update:{}});return this.prisma.message.create({data:{conversationId:conversation.id,sender:'USER',body}});}
  async notifications(userId:string,q:PageDto){const where={userId};const [items,total,unread]=await this.prisma.$transaction([this.prisma.notification.findMany({where,...this.paging(q),orderBy:{createdAt:'desc'}}),this.prisma.notification.count({where}),this.prisma.notification.count({where:{userId,readAt:null}})]);return {...await this.page(items,total,q),unread};}
  async readNotification(userId:string,id:string){await this.owned(this.prisma.notification.findFirst({where:{id,userId}}),'Notificação');return this.prisma.notification.update({where:{id},data:{readAt:new Date()}});}
  async readAllNotifications(userId:string){await this.prisma.notification.updateMany({where:{userId,readAt:null},data:{readAt:new Date()}});}
  private async owned<T>(promise:Promise<T|null>,label:string){const item=await promise;if(!item)throw new NotFoundException(`${label} não encontrado.`);return item;}
  private ownedDocument(userId: string, id: string) { return this.owned(this.prisma.document.findFirst({ where: { id, userId } }), 'Documento'); }
  private documentView<T extends { fileKey?: string | null }>(item: T) { const { fileKey: _fileKey, ...data } = item; return { ...data, hasFile: Boolean(_fileKey) }; }
  private decimal<T extends {amount:any}>(item:T){return {...item,amount:Number(item.amount)};}
}
