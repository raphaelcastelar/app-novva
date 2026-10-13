import { ResourcesService } from '../src/modules/resources/resources.service';

describe('ResourcesService document validity', () => {
  it('calculates expiration from the file attachment time', async () => {
    const item = {
      id: 'document-id', userId: 'user-id', title: 'Certidão de regularidade',
      category: 'Fiscal', status: 'APPROVED', fileKey: 'private/file.pdf',
      fileUploadedAt: new Date('2025-01-31T12:00:00.000Z'),
      documentType: { id: 'type-id', key: 'certidao-regularidade', name: 'Certidão de regularidade', category: 'Fiscal', validityMonths: 6 },
    };
    const prisma = {
      document: {
        findMany: jest.fn().mockResolvedValue([item]),
        count: jest.fn().mockResolvedValue(1),
      },
      $transaction: jest.fn().mockResolvedValue([[item], 1]),
    };
    const service = new ResourcesService(prisma as any, {} as any, {} as any);

    const result = await service.documents('user-id', { page: 1, limit: 30 });

    expect(result.items[0]).toMatchObject({
      hasFile: true,
      validityMonths: 6,
      possiblyExpired: true,
    });
    expect(result.items[0].expiresAt.toISOString()).toBe('2025-07-31T12:00:00.000Z');
    expect(result.items[0]).not.toHaveProperty('fileKey');
  });

  it('only exposes active document types to the app', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const service = new ResourcesService({ documentType: { findMany } } as any, {} as any, {} as any);

    await service.documentTypes();

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { active: true } }));
  });
});
