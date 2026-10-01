import { Body, Controller, Get, Headers, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiHeader, ApiTags } from '@nestjs/swagger';
import { AdminRequestQueryDto, AdminUpdateStatusDto } from './admin.dto';
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
  @Get('doctors') doctors(@Query('search') search?: string) { return this.service.doctors(search); }
  @Get('dashboard') dashboard() { return this.service.dashboard(); }
}
