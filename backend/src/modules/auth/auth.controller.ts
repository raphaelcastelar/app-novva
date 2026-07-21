import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, AuthenticatedUser } from '../../common/current-user.decorator';
import { AuthService } from './auth.service';
import { ChangePasswordDto, CpfDto, CreatePasswordDto, LoginDto, RefreshDto, ResetPasswordDto } from './auth.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly service: AuthService) {}
  @Post('verify-cpf') @HttpCode(200) verifyCpf(@Body() dto: CpfDto) { return this.service.verifyCpf(dto.cpf); }
  @Post('login') @HttpCode(200) login(@Body() dto: LoginDto) { return this.service.login(dto.cpf, dto.password); }
  @Post('create-password') @HttpCode(200) createPassword(@Body() dto: CreatePasswordDto) { return this.service.createPassword(dto.cpf, dto.password); }
  @Post('refresh') @HttpCode(200) refresh(@Body() dto: RefreshDto) { return this.service.refresh(dto.refreshToken); }
  @Post('forgot-password') @HttpCode(202) forgot(@Body() dto: CpfDto) { return this.service.forgotPassword(dto.cpf); }
  @Post('reset-password') @HttpCode(200) reset(@Body() dto: ResetPasswordDto) { return this.service.resetPassword(dto.token, dto.password); }
  @Post('change-password') @UseGuards(JwtAuthGuard) @ApiBearerAuth() @HttpCode(204)
  change(@CurrentUser() user: AuthenticatedUser, @Body() dto: ChangePasswordDto) { return this.service.changePassword(user.id, dto); }
  @Post('logout') @UseGuards(JwtAuthGuard) @ApiBearerAuth() @HttpCode(204)
  logout(@Body() dto: RefreshDto) { return this.service.logout(dto.refreshToken); }
}
