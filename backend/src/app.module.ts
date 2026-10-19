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
import { NoticesController } from './modules/notices/notices.controller';
import { NoticesService } from './modules/notices/notices.service';
import { SerproService } from './common/serpro.service';
import { PushDevicesController } from './modules/push-devices/push-devices.controller';
import { PushNotificationsService } from './modules/push-devices/push-notifications.service';

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
        if (env.SERPRO_ENABLED === 'true') {
          if (!env.SERPRO_CONSUMER_KEY || !env.SERPRO_CONSUMER_SECRET) throw new Error('Credenciais do Integra Contador são obrigatórias.');
          if (!/^\d{14}$/.test(String(env.SERPRO_CONTRACTOR_CNPJ ?? '').replace(/\D/g, ''))) throw new Error('SERPRO_CONTRACTOR_CNPJ deve ter 14 dígitos.');
          if (!env.SERPRO_CERT_PEM && !env.SERPRO_CERT_PATH) throw new Error('Certificado do Integra Contador é obrigatório.');
          if (!env.SERPRO_PRIVATE_KEY_PEM && !env.SERPRO_PRIVATE_KEY_PATH) throw new Error('Chave privada do Integra Contador é obrigatória.');
        }
        if (env.PUSH_NOTIFICATIONS_ENABLED === 'true') {
          const hasEncodedAccount = Boolean(env.FIREBASE_SERVICE_ACCOUNT_BASE64);
          const hasSeparateCredentials = Boolean(env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY);
          if (!hasEncodedAccount && !hasSeparateCredentials) {
            throw new Error('Configure FIREBASE_SERVICE_ACCOUNT_BASE64 ou as três credenciais FIREBASE_* para ativar notificações push.');
          }
        }
        return env;
      },
    }),
    JwtModule.register({ global: true, secret: process.env.JWT_SECRET, signOptions: { expiresIn: '15m' } }),
  ],
  controllers: [HealthController, AuthController, UsersController, ResourcesController, DashboardController, AdminController, NoticesController, PushDevicesController],
  providers: [PrismaService, MailService, StorageService, SerproService, AuthService, JwtAuthGuard, UsersService, ResourcesService, DashboardService, AdminService, InternalTokenGuard, NoticesService, PushNotificationsService],
})
export class AppModule {}
