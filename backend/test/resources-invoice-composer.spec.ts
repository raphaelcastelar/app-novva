import { ResourcesService } from '../src/modules/resources/resources.service';

describe('ResourcesService invoice composer', () => {
  it('persists one draft per user', async () => {
    const saved = {
      id: 'draft-id',
      userId: 'user-id',
      amount: 1250,
    };
    const prisma = {
      invoiceDraft: { upsert: jest.fn().mockResolvedValue(saved) },
    };
    const service = new ResourcesService(prisma as any, {} as any, {} as any);

    await service.saveInvoiceDraft('user-id', {
      takerCnpj: '11222333000181',
      takerName: 'Hospital Vida',
      municipality: 'Campos dos Goytacazes',
      serviceDate: '2026-10-21',
      amount: 1250,
      taxationCode: '04.01.01 Medicina',
      description: 'Atendimento médico especializado.',
    });

    expect(prisma.invoiceDraft.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-id' },
        create: expect.objectContaining({
          userId: 'user-id',
          takerCnpj: '11222333000181',
        }),
      }),
    );
  });

  it('stores a favorite without duplicating its description', async () => {
    const prisma = {
      invoiceDescriptionFavorite: {
        upsert: jest.fn().mockResolvedValue({
          id: 'favorite-id',
          description: 'Descrição favorita',
        }),
      },
    };
    const service = new ResourcesService(prisma as any, {} as any, {} as any);

    await service.favoriteInvoiceDescription(
      'user-id',
      '  Descrição favorita  ',
    );

    expect(prisma.invoiceDescriptionFavorite.upsert).toHaveBeenCalledWith({
      where: {
        userId_description: {
          userId: 'user-id',
          description: 'Descrição favorita',
        },
      },
      create: {
        userId: 'user-id',
        description: 'Descrição favorita',
      },
      update: {},
    });
  });
});
