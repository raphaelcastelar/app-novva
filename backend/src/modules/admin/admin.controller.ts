import { BadRequestException, Body, Controller, Get, Headers, Param, Patch, Post, Query, Res, StreamableFile, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiHeader, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { DOCUMENT_MAX_BYTES } from '../../common/storage.service';
import { AdminCreateDoctorDto, AdminRequestQueryDto, AdminUpdateStatusDto } from './admin.dto';
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
  @Get('dashboard') dashboard() { return this.service.dashboard(); }
}

function contentDisposition(originalName: string) {
  const fallback = originalName.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 180) || 'documento';
  return `attachment; filename="${fallback}"; filename*=UTF-8''${encodeURIComponent(originalName)}`;
}
