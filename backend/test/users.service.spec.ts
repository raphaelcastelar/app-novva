import { BadRequestException } from "@nestjs/common";
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
