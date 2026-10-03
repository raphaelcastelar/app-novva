import { ConflictException } from '@nestjs/common';
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
    const service = new AdminService(prisma as any, {} as any);

    const result = await service.createDoctor(dto, 'Matheus Eler');

    expect(transaction.user.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.not.objectContaining({ passwordHash: expect.anything() }),
    }));
    expect(result).toMatchObject({ id: 'doctor-id', email: 'nova@example.com', needsPasswordCreation: true });
    expect(transaction.auditLog.create).toHaveBeenCalled();
  });

  it('rejects a duplicated CPF', async () => {
    const prisma = { user: { findFirst: jest.fn().mockResolvedValue({ cpf: dto.cpf, email: 'other@example.com' }) } };
    const service = new AdminService(prisma as any, {} as any);
    await expect(service.createDoctor(dto)).rejects.toBeInstanceOf(ConflictException);
  });
});
