import { PushNotificationsService } from '../src/modules/push-devices/push-notifications.service';

describe('PushNotificationsService device registration', () => {
  it('associates the FCM token with the authenticated user', async () => {
    const upsert = jest.fn().mockResolvedValue({
      id: 'device-id', platform: 'IOS', enabled: true, lastSeenAt: new Date(),
    });
    const service = new PushNotificationsService({ pushDevice: { upsert } } as any);

    await service.registerDevice('user-id', {
      token: 'a-valid-fcm-registration-token',
      platform: 'IOS' as any,
    });

    expect(upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { token: 'a-valid-fcm-registration-token' },
      update: expect.objectContaining({ userId: 'user-id', enabled: true }),
      create: expect.objectContaining({ userId: 'user-id', platform: 'IOS' }),
    }));
  });

  it('disables only a token owned by the authenticated user', async () => {
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const service = new PushNotificationsService({ pushDevice: { updateMany } } as any);

    await service.removeDevice('user-id', 'a-valid-fcm-registration-token');

    expect(updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-id', token: 'a-valid-fcm-registration-token' },
      data: { enabled: false },
    });
  });
});
