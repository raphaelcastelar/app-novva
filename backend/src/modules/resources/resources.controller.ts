import { BadRequestException, Body, Controller, Get, HttpCode, Param, Patch, Post, Query, Res, StreamableFile, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { AuthenticatedUser, CurrentUser } from '../../common/current-user.decorator';
import { DOCUMENT_MAX_BYTES } from '../../common/storage.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ConfirmDocumentUploadDto, CreateDocumentDto, CreateInvoiceDto, DocumentUploadDto, PageDto, SendMessageDto } from './resources.dto';
import { ResourcesService } from './resources.service';

@ApiTags('resources') @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Controller()
export class ResourcesController {
  constructor(private readonly service: ResourcesService) {}
  @Get('documents') documents(@CurrentUser() u: AuthenticatedUser, @Query() q: PageDto) { return this.service.documents(u.id, q); }
  @Post('documents') createDocument(@CurrentUser() u: AuthenticatedUser, @Body() dto: CreateDocumentDto) { return this.service.createDocument(u.id, dto); }
  @Get('documents/:id') document(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string) { return this.service.document(u.id, id); }
  @Post('documents/:id/file')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: DOCUMENT_MAX_BYTES } }))
  uploadFile(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Selecione um arquivo.');
    return this.service.storeDocumentFile(u.id, id, file);
  }
  @Get('documents/:id/file')
  async file(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string, @Res({ passthrough: true }) response: Response) {
    const result = await this.service.documentFile(u.id, id);
    response.setHeader('Content-Type', result.mimeType);
    response.setHeader('Content-Disposition', contentDisposition(result.originalName));
    if (result.contentLength != null) response.setHeader('Content-Length', String(result.contentLength));
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(result.stream);
  }
  @Post('documents/:id/upload-url') uploadUrl(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string, @Body() dto: DocumentUploadDto) { return this.service.documentUploadUrl(u.id, id, dto); }
  @Post('documents/:id/confirm-upload') confirmUpload(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string, @Body() dto: ConfirmDocumentUploadDto) { return this.service.confirmDocumentUpload(u.id, id, dto); }
  @Get('documents/:id/download-url') downloadUrl(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string) { return this.service.documentDownloadUrl(u.id, id); }
  @Get('obligations') obligations(@CurrentUser() u: AuthenticatedUser, @Query() q: PageDto) { return this.service.obligations(u.id, q); }
  @Get('obligations/:id') obligation(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string) { return this.service.obligation(u.id, id); }
  @Post('obligations/:id/paid') markPaid(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string) { return this.service.markObligationPaid(u.id, id); }
  @Get('invoices') invoices(@CurrentUser() u: AuthenticatedUser, @Query() q: PageDto) { return this.service.invoices(u.id, q); }
  @Post('invoices') createInvoice(@CurrentUser() u: AuthenticatedUser, @Body() dto: CreateInvoiceDto) { return this.service.createInvoice(u.id, dto); }
  @Get('invoices/:id') invoice(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string) { return this.service.invoice(u.id, id); }
  @Get('payments') payments(@CurrentUser() u: AuthenticatedUser, @Query() q: PageDto) { return this.service.payments(u.id, q); }
  @Get('reports/summary') reports(@CurrentUser() u: AuthenticatedUser) { return this.service.reports(u.id); }
  @Get('chat/messages') messages(@CurrentUser() u: AuthenticatedUser, @Query() q: PageDto) { return this.service.messages(u.id, q); }
  @Post('chat/messages') send(@CurrentUser() u: AuthenticatedUser, @Body() dto: SendMessageDto) { return this.service.sendMessage(u.id, dto.body); }
  @Get('notifications') notifications(@CurrentUser() u: AuthenticatedUser, @Query() q: PageDto) { return this.service.notifications(u.id, q); }
  @Patch('notifications/:id/read') read(@CurrentUser() u: AuthenticatedUser, @Param('id') id: string) { return this.service.readNotification(u.id, id); }
  @Post('notifications/read-all') @HttpCode(204) readAll(@CurrentUser() u: AuthenticatedUser) { return this.service.readAllNotifications(u.id); }
}

function contentDisposition(originalName: string) {
  const fallback = originalName.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 180) || 'documento';
  return `attachment; filename="${fallback}"; filename*=UTF-8''${encodeURIComponent(originalName)}`;
}
