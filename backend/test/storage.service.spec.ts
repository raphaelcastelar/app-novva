import { mkdtemp, rm } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { BadRequestException } from '@nestjs/common';
import { StorageService } from '../src/common/storage.service';

describe('StorageService local driver', () => {
  let directory: string;
  let service: StorageService;

  beforeEach(async () => {
    directory = await mkdtemp(join(tmpdir(), 'novva-storage-'));
    process.env.STORAGE_DRIVER = 'local';
    process.env.LOCAL_STORAGE_PATH = directory;
    service = new StorageService();
  });

  afterEach(async () => {
    await rm(directory, { recursive: true, force: true });
    delete process.env.STORAGE_DRIVER;
    delete process.env.LOCAL_STORAGE_PATH;
  });

  it('stores and reads a valid PDF under an opaque key', async () => {
    const buffer = Buffer.from('%PDF-1.7\nnovva');
    const file = {
      buffer, size: buffer.length, mimetype: 'application/pdf', originalname: 'resultado.pdf',
    } as Express.Multer.File;

    const key = await service.storeDocument('user-id', 'document-id', file);
    const stored = await service.readDocument(key);
    const chunks: Buffer[] = [];
    for await (const chunk of stored.stream) chunks.push(Buffer.from(chunk));

    expect(key).toMatch(/^users\/user-id\/documents\/document-id\/[a-f0-9-]+\.pdf$/);
    expect(Buffer.concat(chunks)).toEqual(buffer);
    expect(stored.contentLength).toBe(buffer.length);
  });

  it('rejects a file whose content does not match its MIME type', async () => {
    const buffer = Buffer.from('not a pdf');
    const file = {
      buffer, size: buffer.length, mimetype: 'application/pdf', originalname: 'fraude.pdf',
    } as Express.Multer.File;

    await expect(service.storeDocument('user-id', 'document-id', file))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects path traversal when reading local files', async () => {
    await expect(service.readDocument('../secret.txt'))
      .rejects.toBeInstanceOf(BadRequestException);
  });
});
