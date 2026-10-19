import { Body, Controller, Delete, HttpCode, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser, CurrentUser } from '../../common/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RegisterPushDeviceDto, RemovePushDeviceDto } from './push-device.dto';
import { PushNotificationsService } from './push-notifications.service';

@ApiTags('push-devices')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('devices')
export class PushDevicesController {
  constructor(private readonly pushNotifications: PushNotificationsService) {}

  @Put('current')
  register(@CurrentUser() user: AuthenticatedUser, @Body() dto: RegisterPushDeviceDto) {
    return this.pushNotifications.registerDevice(user.id, dto);
  }

  @Delete('current')
  @HttpCode(204)
  remove(@CurrentUser() user: AuthenticatedUser, @Body() dto: RemovePushDeviceDto) {
    return this.pushNotifications.removeDevice(user.id, dto.token);
  }
}
