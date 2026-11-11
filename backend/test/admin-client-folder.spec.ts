import { BadRequestException } from '@nestjs/common';
import { AdminService } from '../src/modules/admin/admin.service';

describe('AdminService client folder', () => {
  const file = {
    originalname: 'honorario-10-2026.pdf', mimetype: 'application/pdf',
    buffer: Buffer.from('%PDF-1.4'), size: 8,
  } as Express.Multer.File;
  const honorario = { id: 'type-id', key: 'honorario-contabil', name: 'Honorário contábil (boleto)', category: 'Financeiro', active: true };

  function setup(existing: any = null) {
    const transaction = {
      document: {
        create: jest.fn(({ data }) => Promise.resolve({ ...data, documentType: honorario })),
        update: jest.fn(({ data }) => Promise.resolve({ id: existing?.id, ...data, documentType: honorario })),
      },
      requestEvent: { create: jest.fn().mockResolvedValue({}) },
      notification: { create: jest.fn().mockResolvedValue({ id: 'notification-id' }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'doctor-id' }) },
      documentType: { findFirst: jest.fn().mockResolvedValue(honorario) },
      document: { findFirst: jest.fn().mockResolvedValue(existing) },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const storage = {
      storeDocument: jest.fn().mockResolvedValue('users/doctor-id/documents/new.pdf'),
      deleteDocument: jest.fn().mockResolvedValue(undefined),
    };
    const push = { sendDocumentAvailable: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma as any, storage as any, push as any);
    return { service, prisma, storage, push, transaction };
  }

  it('publishes an office document as available and notifies the doctor', async () => {
    const { service, transaction, push, prisma } = setup();

    const result = await service.sendClientDocument('doctor-id', { documentTypeKey: 'honorario-contabil', month: 10, year: 2026 }, file, 'Admin');

    expect(prisma.documentType.findFirst).toHaveBeenCalledWith({ where: { key: 'honorario-contabil' } });
    expect(transaction.document.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ userId: 'doctor-id', origin: 'OFFICE', status: 'APPROVED', month: 10, year: 2026, category: 'Financeiro' }),
    }));
    expect(push.sendDocumentAvailable).toHaveBeenCalledWith(expect.objectContaining({ userId: 'doctor-id', notificationId: 'notification-id' }));
    expect(result).toMatchObject({ origin: 'OFFICE', month: 10, year: 2026, documentType: { key: 'honorario-contabil' } });
  });

  it('replaces the file of the same type and competence instead of duplicating it', async () => {
    const { service, transaction, storage } = setup({ id: 'existing-id', fileKey: 'users/doctor-id/documents/old.pdf' });

    await service.sendClientDocument('doctor-id', { documentTypeKey: 'honorario-contabil', month: 10, year: 2026 }, file);

    expect(transaction.document.create).not.toHaveBeenCalled();
    expect(transaction.document.update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'existing-id' } }));
    expect(storage.deleteDocument).toHaveBeenCalledWith('users/doctor-id/documents/old.pdf');
  });

  it('requires month and year together', async () => {
    const { service, storage } = setup();
    await expect(service.sendClientDocument('doctor-id', { documentTypeKey: 'honorario-contabil', month: 10 }, file))
      .rejects.toBeInstanceOf(BadRequestException);
    expect(storage.storeDocument).not.toHaveBeenCalled();
  });

  it('removes the stored file when persisting fails', async () => {
    const { service, prisma, storage, push } = setup();
    prisma.$transaction.mockRejectedValueOnce(new Error('db down'));
    await expect(service.sendClientDocument('doctor-id', { documentTypeKey: 'honorario-contabil' }, file)).rejects.toThrow('db down');
    expect(storage.deleteDocument).toHaveBeenCalledWith('users/doctor-id/documents/new.pdf');
    expect(push.sendDocumentAvailable).not.toHaveBeenCalled();
  });

  it('only removes documents sent by the office', async () => {
    const { service, prisma } = setup();
    prisma.document.findFirst.mockResolvedValueOnce({ id: 'doc', userId: 'doctor-id', origin: 'APP' });
    await expect(service.removeClientDocument('doctor-id', 'doc')).rejects.toBeInstanceOf(BadRequestException);
  });
});
