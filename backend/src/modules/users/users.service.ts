import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import * as argon2 from "argon2";
import { PrismaService } from "../../common/prisma.service";
import { StorageService } from "../../common/storage.service";
import { isValidCnpj } from "../../common/validation";
import {
  CreateCnpjDto,
  UpdateCnpjDto,
  UpdateProfileDto,
  UpdateUserDto,
} from "./users.dto";

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}
  private select = {
    id: true,
    cpf: true,
    name: true,
    email: true,
    phone: true,
    status: true,
    createdAt: true,
  } as const;
  me(id: string) {
    return this.prisma.user.findUniqueOrThrow({
      where: { id },
      select: this.select,
    });
  }
  async update(id: string, dto: UpdateUserDto) {
    try {
      return await this.prisma.user.update({
        where: { id },
        data: dto,
        select: this.select,
      });
    } catch (error: any) {
      if (error?.code === "P2002")
        throw new ConflictException("E-mail já cadastrado.");
      throw error;
    }
  }
  async remove(id: string, password: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id },
      select: {
        passwordHash: true,
        documents: { select: { id: true, fileKey: true } },
        invoices: { select: { id: true, pdfKey: true } },
        obligations: { select: { pdfKey: true } },
      },
    });
    if (
      !user.passwordHash ||
      !(await argon2.verify(user.passwordHash, password))
    ) {
      throw new BadRequestException("Senha incorreta.");
    }

    const documentIds = user.documents.map((item) => item.id);
    const invoiceIds = user.invoices.map((item) => item.id);
    const eventFilters = [
      ...(documentIds.length
        ? [{ requestKind: "DOCUMENT" as const, requestId: { in: documentIds } }]
        : []),
      ...(invoiceIds.length
        ? [{ requestKind: "INVOICE" as const, requestId: { in: invoiceIds } }]
        : []),
    ];
    const fileKeys = [
      ...user.documents.map((item) => item.fileKey),
      ...user.invoices.map((item) => item.pdfKey),
      ...user.obligations.map((item) => item.pdfKey),
    ].filter((key): key is string => Boolean(key));

    await this.prisma.$transaction(async (transaction) => {
      if (eventFilters.length) {
        await transaction.requestEvent.deleteMany({
          where: { OR: eventFilters },
        });
      }
      await transaction.auditLog.create({
        data: {
          action: "ACCOUNT_DELETED",
          entity: "User",
          entityId: id,
          metadata: { filesScheduledForDeletion: fileKeys.length },
        },
      });
      await transaction.user.delete({ where: { id } });
    });

    await Promise.allSettled(
      fileKeys.map((key) => this.storage.deleteDocument(key)),
    );
  }
  async profile(userId: string) {
    return (
      (await this.prisma.medicalProfile.findUnique({ where: { userId } })) ?? {
        userId,
        crm: null,
        specialty: null,
        taxRegime: null,
        companyName: null,
      }
    );
  }
  updateProfile(userId: string, dto: UpdateProfileDto) {
    return this.prisma.medicalProfile.upsert({
      where: { userId },
      create: { userId, ...dto },
      update: dto,
    });
  }
  cnpjs(userId: string) {
    return this.prisma.cnpj.findMany({
      where: { userId },
      orderBy: [{ active: "desc" }, { createdAt: "desc" }],
    });
  }
  async createCnpj(userId: string, dto: CreateCnpjDto) {
    if (!isValidCnpj(dto.cnpj)) throw new BadRequestException("CNPJ inválido.");
    const count = await this.prisma.cnpj.count({ where: { userId } });
    try {
      return await this.prisma.cnpj.create({
        data: { userId, ...dto, active: count === 0 },
      });
    } catch (error: any) {
      if (error?.code === "P2002")
        throw new ConflictException("CNPJ já cadastrado.");
      throw error;
    }
  }
  async updateCnpj(userId: string, id: string, dto: UpdateCnpjDto) {
    await this.assertCnpj(userId, id);
    return this.prisma.cnpj.update({ where: { id }, data: dto });
  }
  async activateCnpj(userId: string, id: string) {
    await this.assertCnpj(userId, id);
    return this.prisma.$transaction(async (tx) => {
      await tx.cnpj.updateMany({ where: { userId }, data: { active: false } });
      return tx.cnpj.update({ where: { id }, data: { active: true } });
    });
  }
  async deleteCnpj(userId: string, id: string) {
    const item = await this.assertCnpj(userId, id);
    if (item.active)
      throw new BadRequestException("Ative outro CNPJ antes de excluir este.");
    await this.prisma.cnpj.delete({ where: { id } });
  }
  private async assertCnpj(userId: string, id: string) {
    const item = await this.prisma.cnpj.findFirst({ where: { id, userId } });
    if (!item) throw new NotFoundException("CNPJ não encontrado.");
    return item;
  }
}
