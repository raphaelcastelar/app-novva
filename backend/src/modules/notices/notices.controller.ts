import { Controller, Get, Param, Post, Res, StreamableFile, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthenticatedUser, CurrentUser } from '../../common/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NoticesService } from './notices.service';

@UseGuards(JwtAuthGuard)
@Controller('notices')
export class NoticesController {
  constructor(private readonly service: NoticesService) {}
  @Get() list(@CurrentUser() user: AuthenticatedUser) { return this.service.list(user.id); }
  @Post(':id/read') read(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) { return this.service.markRead(user.id, id); }
  @Get(':id/file')
  async file(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Res({ passthrough: true }) response: Response) {
    const result = await this.service.file(user.id, id);
    response.setHeader('Content-Type', result.mimeType);
    response.setHeader('Content-Disposition', `attachment; filename*=UTF-8''${encodeURIComponent(result.originalName)}`);
    if (result.contentLength != null) response.setHeader('Content-Length', String(result.contentLength));
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(result.stream);
  }
}
