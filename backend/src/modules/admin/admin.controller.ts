import { BadRequestException, Body, Controller, Delete, Get, Headers, HttpCode, Param, Patch, Post, Query, Res, StreamableFile, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiHeader, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { DOCUMENT_MAX_BYTES } from '../../common/storage.service';
import { AdminCreateDoctorDto, AdminCreateDocumentTypeDto, AdminRequestQueryDto, AdminUpdateDoctorDto, AdminUpdateDocumentTypeDto, AdminUpdateStatusDto } from './admin.dto';
import { AdminService } from './admin.service';
import { InternalTokenGuard } from './internal-token.guard';

@ApiTags('internal-admin')
@ApiHeader({ name: 'X-Internal-Service-Token', required: true })
@UseGuards(InternalTokenGuard)
@Controller('internal/admin')
export class AdminController {
  constructor(private readonly service: AdminService) {}

  @Get('requests') list(@Query() query: AdminRequestQueryDto) { return this.service.listRequests(query); }
  @Get('requests/:id') detail(@Param('id') id: string) { return this.service.requestDetail(id); }
  @Patch('requests/:id/status') update(
    @Param('id') id: string,
    @Body() dto: AdminUpdateStatusDto,
    @Headers('x-admin-actor') actor?: string,
  ) { return this.service.updateStatus(id, dto, actor); }
  @Post('requests/:id/file')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: DOCUMENT_MAX_BYTES } }))
  uploadFile(@Param('id') id: string, @UploadedFile() file?: Express.Multer.File, @Headers('x-admin-actor') actor?: string) {
    if (!file) throw new BadRequestException('Selecione um arquivo.');
    return this.service.storeDocumentFile(id, file, actor);
  }
  @Get('requests/:id/file')
  async file(@Param('id') id: string, @Res({ passthrough: true }) response: Response) {
    const result = await this.service.documentFile(id);
    response.setHeader('Content-Type', result.mimeType);
    response.setHeader('Content-Disposition', contentDisposition(result.originalName));
    if (result.contentLength != null) response.setHeader('Content-Length', String(result.contentLength));
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(result.stream);
  }
  @Get('doctors') doctors(@Query('search') search?: string) { return this.service.doctors(search); }
  @Post('doctors') createDoctor(@Body() dto: AdminCreateDoctorDto, @Headers('x-admin-actor') actor?: string) {
    return this.service.createDoctor(dto, actor);
  }
  @Get('doctors/:id') doctor(@Param('id') id: string) { return this.service.doctorDetail(id); }
  @Patch('doctors/:id') updateDoctor(
    @Param('id') id: string,
    @Body() dto: AdminUpdateDoctorDto,
    @Headers('x-admin-actor') actor?: string,
  ) { return this.service.updateDoctor(id, dto, actor); }
  @Delete('doctors/:id') @HttpCode(204)
  removeDoctor(@Param('id') id: string, @Headers('x-admin-actor') actor?: string) {
    return this.service.removeDoctor(id, actor);
  }
  @Get('document-types') documentTypes() { return this.service.documentTypes(); }
  @Post('document-types') createDocumentType(@Body() dto: AdminCreateDocumentTypeDto, @Headers('x-admin-actor') actor?: string) {
    return this.service.createDocumentType(dto, actor);
  }
  @Patch('document-types/:id') updateDocumentType(
    @Param('id') id: string,
    @Body() dto: AdminUpdateDocumentTypeDto,
    @Headers('x-admin-actor') actor?: string,
  ) { return this.service.updateDocumentType(id, dto, actor); }
  @Get('notices') notices() { return this.service.notices(); }
  @Post('notices')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: DOCUMENT_MAX_BYTES } }))
  createNotice(@Body() body: Record<string, string>, @UploadedFile() file?: Express.Multer.File, @Headers('x-admin-actor') actor?: string) {
    return this.service.createNotice(body, file, actor);
  }
  @Patch('notices/:id')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: DOCUMENT_MAX_BYTES } }))
  updateNotice(@Param('id') id: string, @Body() body: Record<string, string>, @UploadedFile() file?: Express.Multer.File, @Headers('x-admin-actor') actor?: string) {
    return this.service.updateNotice(id, body, file, actor);
  }
  @Delete('notices/:id') @HttpCode(204)
  removeNotice(@Param('id') id: string, @Headers('x-admin-actor') actor?: string) { return this.service.removeNotice(id, actor); }
  @Get('notices/:id/file')
  async noticeFile(@Param('id') id: string, @Res({ passthrough: true }) response: Response) {
    const result = await this.service.noticeFile(id);
    response.setHeader('Content-Type', result.mimeType);
    response.setHeader('Content-Disposition', contentDisposition(result.originalName));
    if (result.contentLength != null) response.setHeader('Content-Length', String(result.contentLength));
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(result.stream);
  }
  @Get('dashboard') dashboard() { return this.service.dashboard(); }
}

function contentDisposition(originalName: string) {
  const fallback = originalName.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 180) || 'documento';
  return `attachment; filename="${fallback}"; filename*=UTF-8''${encodeURIComponent(originalName)}`;
}
