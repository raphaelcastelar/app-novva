import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { isValidCnpj } from '../../common/validation';
import { CreateCnpjDto, UpdateCnpjDto, UpdateProfileDto, UpdateUserDto } from './users.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}
  private select = { id: true, cpf: true, name: true, email: true, phone: true, status: true, createdAt: true } as const;
  me(id: string) { return this.prisma.user.findUniqueOrThrow({ where: { id }, select: this.select }); }
  async update(id: string, dto: UpdateUserDto) {
    try { return await this.prisma.user.update({ where: { id }, data: dto, select: this.select }); }
    catch (error: any) { if (error?.code === 'P2002') throw new ConflictException('E-mail já cadastrado.'); throw error; }
  }
  async remove(id: string) {
    await this.prisma.$transaction([
      this.prisma.auditLog.create({ data: { action: 'ACCOUNT_DELETED', entity: 'User', entityId: id } }),
      this.prisma.user.delete({ where: { id } }),
    ]);
  }
  async profile(userId: string) {
    return (await this.prisma.medicalProfile.findUnique({ where: { userId } })) ?? { userId, crm: null, specialty: null, taxRegime: null, companyName: null };
  }
  updateProfile(userId: string, dto: UpdateProfileDto) {
    return this.prisma.medicalProfile.upsert({ where: { userId }, create: { userId, ...dto }, update: dto });
  }
  cnpjs(userId: string) { return this.prisma.cnpj.findMany({ where: { userId }, orderBy: [{ active: 'desc' }, { createdAt: 'desc' }] }); }
  async createCnpj(userId: string, dto: CreateCnpjDto) {
    if (!isValidCnpj(dto.cnpj)) throw new BadRequestException('CNPJ inválido.');
    const count = await this.prisma.cnpj.count({ where: { userId } });
    try { return await this.prisma.cnpj.create({ data: { userId, ...dto, active: count === 0 } }); }
    catch (error: any) { if (error?.code === 'P2002') throw new ConflictException('CNPJ já cadastrado.'); throw error; }
  }
  async updateCnpj(userId: string, id: string, dto: UpdateCnpjDto) {
    await this.assertCnpj(userId, id); return this.prisma.cnpj.update({ where: { id }, data: dto });
  }
  async activateCnpj(userId: string, id: string) {
    await this.assertCnpj(userId, id);
    return this.prisma.$transaction(async tx => {
      await tx.cnpj.updateMany({ where: { userId }, data: { active: false } });
      return tx.cnpj.update({ where: { id }, data: { active: true } });
    });
  }
  async deleteCnpj(userId: string, id: string) {
    const item = await this.assertCnpj(userId, id);
    if (item.active) throw new BadRequestException('Ative outro CNPJ antes de excluir este.');
    await this.prisma.cnpj.delete({ where: { id } });
  }
  private async assertCnpj(userId: string, id: string) {
    const item = await this.prisma.cnpj.findFirst({ where: { id, userId } });
    if (!item) throw new NotFoundException('CNPJ não encontrado.'); return item;
  }
}
