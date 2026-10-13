import { BadRequestException } from '@nestjs/common';
import { ResourcesService } from '../src/modules/resources/resources.service';

describe('ResourcesService DAS generation', () => {
  it('generates and persists a DAS for the active company', async () => {
    const created = {
      id: 'obligation-id',
      userId: 'user-id',
      name: 'DAS Simples Nacional',
      kind: 'DAS',
      competenceMonth: 10,
      competenceYear: 2026,
      dueDate: new Date(Date.UTC(2026, 10, 20)),
      amount: 0,
      status: 'OPEN',
      paymentCode: null,
      pdfKey: 'stored-pdf-key',
      generatedAt: new Date(),
      paidAt: null,
    };
    const transaction = {
      obligation: {
        create: jest.fn().mockResolvedValue(created),
      },
      notification: {
        create: jest.fn().mockResolvedValue({}),
      },
    };
    const prisma = {
      obligation: { findFirst: jest.fn().mockResolvedValue(null) },
      cnpj: {
        findFirst: jest.fn().mockResolvedValue({ cnpj: '12345678000190' }),
      },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const storage = {
      storeObligationPdf: jest.fn().mockResolvedValue('stored-pdf-key'),
      deleteDocument: jest.fn().mockResolvedValue(undefined),
    };
    const serpro = {
      generateDas: jest.fn().mockResolvedValue({
        content: Buffer.from('%PDF-generated'),
        filename: 'DAS.pdf',
      }),
    };
    const service = new ResourcesService(
      prisma as any,
      storage as any,
      serpro as any,
    );

    const result = await service.generateObligation('user-id', {
      month: 10,
      year: 2026,
    });

    expect(serpro.generateDas).toHaveBeenCalledWith(
      '12345678000190',
      '202610',
    );
    expect(storage.storeObligationPdf).toHaveBeenCalledWith(
      'user-id',
      expect.any(String),
      expect.any(Buffer),
    );
    expect(transaction.obligation.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: 'user-id',
        kind: 'DAS',
        competenceMonth: 10,
        competenceYear: 2026,
        pdfKey: 'stored-pdf-key',
      }),
    });
    expect(result).toMatchObject({ hasFile: true, amount: 0 });
  });

  it('requires an active CNPJ', async () => {
    const prisma = {
      obligation: { findFirst: jest.fn().mockResolvedValue(null) },
      cnpj: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const serpro = { generateDas: jest.fn() };
    const service = new ResourcesService(
      prisma as any,
      {} as any,
      serpro as any,
    );

    await expect(
      service.generateObligation('user-id', { month: 10, year: 2026 }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(serpro.generateDas).not.toHaveBeenCalled();
  });

  it('does not recalculate a guide without a PDF', async () => {
    const prisma = {
      obligation: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'obligation-id',
          kind: 'DAS',
          pdfKey: null,
          dueDate: new Date(Date.UTC(2026, 9, 20)),
          competenceMonth: 10,
          competenceYear: 2026,
        }),
      },
    };
    const serpro = { generateDas: jest.fn() };
    const service = new ResourcesService(
      prisma as any,
      {} as any,
      serpro as any,
    );

    await expect(
      service.recalculateObligation('user-id', 'obligation-id'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(serpro.generateDas).not.toHaveBeenCalled();
  });
});
