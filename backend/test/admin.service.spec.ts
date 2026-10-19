import { BadRequestException, ConflictException } from '@nestjs/common';
import { AdminService } from '../src/modules/admin/admin.service';

describe('AdminService doctor registration', () => {
  const dto = {
    cpf: '52998224725', name: 'Dra. Nova Médica', email: 'NOVA@EXAMPLE.COM',
    phone: '11999999999', crm: 'CRM 123-SP', specialty: 'Clínica médica',
    companyName: 'Nova Medicina Ltda.',
  };

  it('creates a doctor without a password for first access', async () => {
    const transaction = {
      user: { create: jest.fn().mockResolvedValue({
        id: 'doctor-id', name: dto.name, email: 'nova@example.com', status: 'ACTIVE',
        profile: { crm: dto.crm, specialty: dto.specialty, companyName: dto.companyName },
      }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      user: { findFirst: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const service = new AdminService(prisma as any, {} as any, {} as any);

    const result = await service.createDoctor(dto, 'Matheus Eler');

    expect(transaction.user.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.not.objectContaining({ passwordHash: expect.anything() }),
    }));
    expect(result).toMatchObject({ id: 'doctor-id', email: 'nova@example.com', needsPasswordCreation: true });
    expect(transaction.auditLog.create).toHaveBeenCalled();
  });

  it('rejects a duplicated CPF', async () => {
    const prisma = { user: { findFirst: jest.fn().mockResolvedValue({ cpf: dto.cpf, email: 'other@example.com' }) } };
    const service = new AdminService(prisma as any, {} as any, {} as any);
    await expect(service.createDoctor(dto)).rejects.toBeInstanceOf(ConflictException);
  });
});

describe('AdminService document types', () => {
  it('creates a type without validity when the field is omitted', async () => {
    const created = { id: 'type-id', key: 'contrato-social', name: 'Contrato social', category: 'Empresa', validityMonths: null, active: true, sortOrder: 10 };
    const prisma = {
      documentType: {
        findFirst: jest.fn().mockResolvedValue(null),
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue(created),
      },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const service = new AdminService(prisma as any, {} as any, {} as any);

    const result = await service.createDocumentType({ name: 'Contrato social', category: 'Empresa', sortOrder: 10 });

    expect(result).toEqual(created);
    expect(prisma.documentType.create).toHaveBeenCalledWith({ data: expect.objectContaining({ validityMonths: null }) });
  });
});

describe('AdminService document availability notifications', () => {
  it('does not notify while the file is only being attached', async () => {
    const item = {
      id: 'document-id', userId: 'user-id', title: 'Certidão negativa',
      status: 'REVIEW', fileKey: null,
    };
    const transaction = {
      document: { update: jest.fn().mockResolvedValue(item) },
      requestEvent: { create: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      document: { findUnique: jest.fn().mockResolvedValue(item) },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const storage = {
      storeDocument: jest.fn().mockResolvedValue('users/user-id/documents/document-id/file.pdf'),
      deleteDocument: jest.fn().mockResolvedValue(undefined),
    };
    const pushNotifications = { sendDocumentAvailable: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma as any, storage as any, pushNotifications as any);
    jest.spyOn(service, 'requestDetail').mockResolvedValue({ id: item.id } as any);

    await service.storeDocumentFile(item.id, {
      originalname: 'certidao.pdf', mimetype: 'application/pdf',
    } as Express.Multer.File);

    expect(transaction.document.update).toHaveBeenCalled();
    expect(pushNotifications.sendDocumentAvailable).not.toHaveBeenCalled();
  });

  it('notifies after saving the document as completed with an attachment', async () => {
    const item = {
      id: 'document-id', userId: 'user-id', title: 'Certidão negativa',
      status: 'REVIEW', fileKey: 'users/user-id/documents/document-id/file.pdf',
      mimeType: 'application/pdf', originalName: 'certidao.pdf',
    };
    const transaction = {
      document: { update: jest.fn().mockResolvedValue({ ...item, status: 'APPROVED' }) },
      requestEvent: { create: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
      notification: { create: jest.fn().mockResolvedValue({ id: 'notification-id' }) },
    };
    const prisma = {
      document: { findUnique: jest.fn().mockResolvedValue(item) },
      invoice: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const pushNotifications = { sendDocumentAvailable: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma as any, {} as any, pushNotifications as any);
    jest.spyOn(service, 'requestDetail').mockResolvedValue({ id: item.id } as any);

    await service.updateStatus(item.id, { status: 'APPROVED' });

    expect(transaction.notification.create).toHaveBeenCalledWith({
      data: {
        userId: 'user-id',
        title: 'Documento disponível',
        body: 'O documento Certidão negativa está pronto e pode ser acessado no app.',
        kind: 'document_available',
      },
    });
    expect(pushNotifications.sendDocumentAvailable).toHaveBeenCalledWith({
      userId: 'user-id',
      documentId: 'document-id',
      documentTitle: 'Certidão negativa',
      notificationId: 'notification-id',
    });
  });

  it('rejects completion when the document has no attachment', async () => {
    const item = {
      id: 'document-id', userId: 'user-id', title: 'Certidão negativa',
      status: 'REVIEW', fileKey: null, mimeType: null, originalName: null,
    };
    const prisma = {
      document: { findUnique: jest.fn().mockResolvedValue(item) },
      invoice: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn(),
    };
    const pushNotifications = { sendDocumentAvailable: jest.fn() };
    const service = new AdminService(prisma as any, {} as any, pushNotifications as any);

    await expect(service.updateStatus(item.id, { status: 'APPROVED' }))
      .rejects.toBeInstanceOf(BadRequestException);

    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(pushNotifications.sendDocumentAvailable).not.toHaveBeenCalled();
  });

  it('does not send the ready notification again for an already completed document', async () => {
    const item = {
      id: 'document-id', userId: 'user-id', title: 'Certidão negativa',
      status: 'APPROVED', fileKey: 'file.pdf', mimeType: 'application/pdf', originalName: 'certidao.pdf',
    };
    const transaction = {
      document: { update: jest.fn().mockResolvedValue(item) },
      requestEvent: { create: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
      notification: { create: jest.fn().mockResolvedValue({ id: 'notification-id' }) },
    };
    const prisma = {
      document: { findUnique: jest.fn().mockResolvedValue(item) },
      invoice: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn((callback) => callback(transaction)),
    };
    const pushNotifications = { sendDocumentAvailable: jest.fn() };
    const service = new AdminService(prisma as any, {} as any, pushNotifications as any);
    jest.spyOn(service, 'requestDetail').mockResolvedValue({ id: item.id } as any);

    await service.updateStatus(item.id, { status: 'APPROVED', note: 'Observação adicional' });

    expect(transaction.notification.create).toHaveBeenCalledWith({
      data: {
        userId: 'user-id', title: 'Solicitação atualizada',
        body: 'Observação adicional', kind: 'request_status',
      },
    });
    expect(pushNotifications.sendDocumentAvailable).not.toHaveBeenCalled();
  });
});
