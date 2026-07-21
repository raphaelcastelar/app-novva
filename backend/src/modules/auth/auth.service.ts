import { BadRequestException, ConflictException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { createHash, randomBytes } from 'crypto';
import { PrismaService } from '../../common/prisma.service';
import { isValidCpf } from '../../common/validation';
import { ChangePasswordDto } from './auth.dto';
import { MailService } from '../../common/mail.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService, private readonly jwt: JwtService, private readonly mail: MailService) {}
  private hashToken(token: string) { return createHash('sha256').update(token).digest('hex'); }
  private publicUser(user: { id: string; cpf: string; name: string; email: string; phone: string | null; passwordHash: string | null }) {
    return { id: user.id, cpf: user.cpf, name: user.name, email: user.email, phone: user.phone, needsPasswordCreation: !user.passwordHash };
  }
  async verifyCpf(cpf: string) {
    if (!isValidCpf(cpf)) throw new BadRequestException('CPF inválido.');
    const user = await this.prisma.user.findUnique({ where: { cpf } });
    if (!user) throw new NotFoundException('CPF não encontrado.');
    return this.publicUser(user);
  }
  async login(cpf: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { cpf } });
    if (!user?.passwordHash || user.status !== 'ACTIVE' || !(await argon2.verify(user.passwordHash, password)))
      throw new UnauthorizedException('CPF ou senha inválidos.');
    return this.createSession(user);
  }
  async createPassword(cpf: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { cpf } });
    if (!user) throw new NotFoundException('CPF não encontrado.');
    if (user.passwordHash) throw new ConflictException('Usuário já possui senha.');
    const updated = await this.prisma.user.update({ where: { id: user.id }, data: { passwordHash: await argon2.hash(password, { type: argon2.argon2id }) } });
    return this.createSession(updated);
  }
  private async createSession(user: { id: string; cpf: string; name: string; email: string; phone: string | null; passwordHash: string | null }) {
    const accessToken = await this.jwt.signAsync({ sub: user.id, id: user.id, cpf: user.cpf });
    const refreshToken = randomBytes(48).toString('base64url');
    const days = Number(process.env.REFRESH_TOKEN_DAYS ?? 30);
    await this.prisma.refreshToken.create({ data: { userId: user.id, tokenHash: this.hashToken(refreshToken), expiresAt: new Date(Date.now() + days * 86400000) } });
    return { accessToken, refreshToken, expiresIn: 900, user: this.publicUser(user) };
  }
  async refresh(token: string) {
    const stored = await this.prisma.refreshToken.findUnique({ where: { tokenHash: this.hashToken(token) }, include: { user: true } });
    if (!stored || stored.revokedAt || stored.expiresAt <= new Date() || stored.user.status !== 'ACTIVE') throw new UnauthorizedException('Refresh token inválido.');
    await this.prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
    return this.createSession(stored.user);
  }
  async logout(token: string) { await this.prisma.refreshToken.updateMany({ where: { tokenHash: this.hashToken(token), revokedAt: null }, data: { revokedAt: new Date() } }); }
  async forgotPassword(cpf: string) {
    const user = await this.prisma.user.findUnique({ where: { cpf } });
    if (user) {
      const raw = randomBytes(32).toString('base64url');
      await this.prisma.passwordResetToken.create({ data: { userId: user.id, tokenHash: this.hashToken(raw), expiresAt: new Date(Date.now() + 30 * 60000) } });
      await this.mail.sendPasswordReset(user.email, user.name, raw);
      if (process.env.NODE_ENV !== 'production') return { message: 'Se o CPF existir, as instruções serão enviadas.', developmentToken: raw };
    }
    return { message: 'Se o CPF existir, as instruções serão enviadas.' };
  }
  async resetPassword(token: string, password: string) {
    const stored = await this.prisma.passwordResetToken.findUnique({ where: { tokenHash: this.hashToken(token) } });
    if (!stored || stored.usedAt || stored.expiresAt <= new Date()) throw new BadRequestException('Token inválido ou expirado.');
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: stored.userId }, data: { passwordHash: await argon2.hash(password, { type: argon2.argon2id }) } }),
      this.prisma.passwordResetToken.update({ where: { id: stored.id }, data: { usedAt: new Date() } }),
      this.prisma.refreshToken.updateMany({ where: { userId: stored.userId, revokedAt: null }, data: { revokedAt: new Date() } }),
    ]);
    return { message: 'Senha redefinida.' };
  }
  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!user.passwordHash || !(await argon2.verify(user.passwordHash, dto.currentPassword))) throw new UnauthorizedException('Senha atual incorreta.');
    if (dto.currentPassword === dto.newPassword) throw new BadRequestException('A nova senha deve ser diferente.');
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: userId }, data: { passwordHash: await argon2.hash(dto.newPassword, { type: argon2.argon2id }) } }),
      this.prisma.refreshToken.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } }),
      this.prisma.auditLog.create({ data: { userId, action: 'PASSWORD_CHANGED', entity: 'User', entityId: userId } }),
    ]);
  }
}
