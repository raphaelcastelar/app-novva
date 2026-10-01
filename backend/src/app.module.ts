import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { HealthController } from './health.controller';
import { PrismaService } from './common/prisma.service';
import { AuthController } from './modules/auth/auth.controller';
import { AuthService } from './modules/auth/auth.service';
import { JwtAuthGuard } from './modules/auth/jwt-auth.guard';
import { UsersController } from './modules/users/users.controller';
import { UsersService } from './modules/users/users.service';
import { ResourcesController } from './modules/resources/resources.controller';
import { ResourcesService } from './modules/resources/resources.service';
import { DashboardController } from './modules/dashboard/dashboard.controller';
import { DashboardService } from './modules/dashboard/dashboard.service';
import { MailService } from './common/mail.service';
import { StorageService } from './common/storage.service';
import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { InternalTokenGuard } from './modules/admin/internal-token.guard';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: (env) => {
        if (!env.DATABASE_URL) throw new Error('DATABASE_URL é obrigatória.');
        if (!env.JWT_SECRET || env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET deve ter pelo menos 32 caracteres.');
        if (env.NODE_ENV === 'production' && (!env.APP_ORIGIN || env.APP_ORIGIN === '*')) throw new Error('APP_ORIGIN deve ser restrita em produção.');
        if (env.NODE_ENV === 'production' && (!env.INTERNAL_SERVICE_TOKEN || env.INTERNAL_SERVICE_TOKEN.length < 32)) throw new Error('INTERNAL_SERVICE_TOKEN deve ter pelo menos 32 caracteres.');
        return env;
      },
    }),
    JwtModule.register({ global: true, secret: process.env.JWT_SECRET, signOptions: { expiresIn: '15m' } }),
  ],
  controllers: [HealthController, AuthController, UsersController, ResourcesController, DashboardController, AdminController],
  providers: [PrismaService, MailService, StorageService, AuthService, JwtAuthGuard, UsersService, ResourcesService, DashboardService, AdminService, InternalTokenGuard],
})
export class AppModule {}
