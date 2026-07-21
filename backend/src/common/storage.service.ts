import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { PutObjectCommand, GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';

@Injectable()
export class StorageService {
  private client() {
    if (!process.env.S3_BUCKET || !process.env.S3_REGION) throw new ServiceUnavailableException('Armazenamento de arquivos não configurado.');
    return new S3Client({ region: process.env.S3_REGION, endpoint: process.env.S3_ENDPOINT, forcePathStyle: process.env.S3_FORCE_PATH_STYLE === 'true' });
  }
  async uploadUrl(userId: string, documentId: string, originalName: string, mimeType: string) {
    const extension = originalName.split('.').pop()?.replace(/[^a-zA-Z0-9]/g, '').slice(0, 10) || 'bin';
    const key = `users/${userId}/documents/${documentId}/${randomUUID()}.${extension}`;
    const url = await getSignedUrl(this.client(), new PutObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: key, ContentType: mimeType }), { expiresIn: 300 });
    return { key, url, method: 'PUT', expiresIn: 300, headers: { 'Content-Type': mimeType } };
  }
  async downloadUrl(key: string) {
    return { url: await getSignedUrl(this.client(), new GetObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: key }), { expiresIn: 300 }), expiresIn: 300 };
  }
}
