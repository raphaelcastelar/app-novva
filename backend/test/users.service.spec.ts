import { BadRequestException, ConflictException } from "@nestjs/common";
import * as argon2 from "argon2";
import { UsersService } from "../src/modules/users/users.service";

describe("UsersService account deletion", () => {
  it("requires the current password and removes records and files", async () => {
    const passwordHash = await argon2.hash("senha-segura");
    const transaction = {
      requestEvent: { deleteMany: jest.fn().mockResolvedValue({ count: 2 }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
      user: { delete: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      user: {
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          passwordHash,
          documents: [
            { id: "document-id", fileKey: "users/user-id/document.pdf" },
          ],
          invoices: [{ id: "invoice-id", pdfKey: null }],
          obligations: [],
        }),
      },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const storage = { deleteDocument: jest.fn().mockResolvedValue(undefined) };
    const service = new UsersService(prisma as any, storage as any);

    await service.remove("user-id", "senha-segura");

    expect(transaction.requestEvent.deleteMany).toHaveBeenCalledWith({
      where: {
        OR: [
          { requestKind: "DOCUMENT", requestId: { in: ["document-id"] } },
          { requestKind: "INVOICE", requestId: { in: ["invoice-id"] } },
        ],
      },
    });
    expect(transaction.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: "ACCOUNT_DELETED",
        entityId: "user-id",
      }),
    });
    expect(transaction.user.delete).toHaveBeenCalledWith({
      where: { id: "user-id" },
    });
    expect(storage.deleteDocument).toHaveBeenCalledWith(
      "users/user-id/document.pdf",
    );
  });

  it("rejects deletion when the password is incorrect", async () => {
    const prisma = {
      user: {
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          passwordHash: await argon2.hash("senha-correta"),
          documents: [],
          invoices: [],
          obligations: [],
        }),
      },
    };
    const storage = { deleteDocument: jest.fn() };
    const service = new UsersService(prisma as any, storage as any);

    await expect(
      service.remove("user-id", "senha-errada"),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(storage.deleteDocument).not.toHaveBeenCalled();
  });
});

describe("UsersService takers", () => {
  it("creates a valid taker for the authenticated user", async () => {
    const created = {
      id: "taker-id",
      userId: "user-id",
      name: "Hospital Vida",
      cnpj: "11222333000181",
      municipality: "Campos dos Goytacazes",
    };
    const prisma = {
      taker: { create: jest.fn().mockResolvedValue(created) },
    };
    const service = new UsersService(prisma as any, {} as any);

    await expect(
      service.createTaker("user-id", {
        name: created.name,
        cnpj: created.cnpj,
        municipality: created.municipality,
      }),
    ).resolves.toEqual(created);
    expect(prisma.taker.create).toHaveBeenCalledWith({
      data: {
        userId: "user-id",
        name: created.name,
        cnpj: created.cnpj,
        municipality: created.municipality,
      },
    });
  });

  it("rejects an invalid or duplicated taker CNPJ", async () => {
    const prisma = {
      taker: {
        create: jest.fn().mockRejectedValue({ code: "P2002" }),
      },
    };
    const service = new UsersService(prisma as any, {} as any);

    await expect(
      service.createTaker("user-id", {
        name: "Inválido",
        cnpj: "11111111111111",
        municipality: "Campos dos Goytacazes",
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createTaker("user-id", {
        name: "Duplicado",
        cnpj: "11222333000181",
        municipality: "Campos dos Goytacazes",
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it("only deletes a taker owned by the authenticated user", async () => {
    const prisma = {
      taker: {
        findFirst: jest.fn().mockResolvedValue({
          id: "taker-id",
          userId: "user-id",
        }),
        delete: jest.fn().mockResolvedValue({}),
      },
    };
    const service = new UsersService(prisma as any, {} as any);

    await service.deleteTaker("user-id", "taker-id");

    expect(prisma.taker.findFirst).toHaveBeenCalledWith({
      where: { id: "taker-id", userId: "user-id" },
    });
    expect(prisma.taker.delete).toHaveBeenCalledWith({
      where: { id: "taker-id" },
    });
  });
});
