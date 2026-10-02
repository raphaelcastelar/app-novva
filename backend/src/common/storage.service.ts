import { BadRequestException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { DeleteObjectCommand, GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { createReadStream } from 'fs';
import { mkdir, stat, unlink, writeFile } from 'fs/promises';
import { Readable } from 'stream';
import { extname, isAbsolute, join, normalize, resolve, sep } from 'path';
import { randomUUID } from 'crypto';

export const DOCUMENT_MAX_BYTES = 10 * 1024 * 1024;
const MIME_EXTENSIONS: Record<string, string> = {
  'application/pdf': 'pdf',
  'image/jpeg': 'jpg',
  'image/png': 'png',
};

export type StoredDocument = {
  stream: Readable;
  contentLength?: number;
};

@Injectable()
export class StorageService {
  private driver() { return (process.env.STORAGE_DRIVER ?? 'local').toLowerCase(); }
  private localRoot() { return resolve(process.env.LOCAL_STORAGE_PATH ?? '/data/documents'); }

  private s3Client() {
    if (!process.env.S3_BUCKET || !process.env.S3_REGION) {
      throw new ServiceUnavailableException('Armazenamento S3 não configurado.');
    }
    return new S3Client({
      region: process.env.S3_REGION,
      endpoint: process.env.S3_ENDPOINT,
      forcePathStyle: process.env.S3_FORCE_PATH_STYLE === 'true',
    });
  }

  async storeDocument(userId: string, documentId: string, file: Express.Multer.File) {
    this.validateFile(file);
    const extension = MIME_EXTENSIONS[file.mimetype];
    const key = `users/${userId}/documents/${documentId}/${randomUUID()}.${extension}`;

    if (this.driver() === 's3') {
      await this.s3Client().send(new PutObjectCommand({
        Bucket: process.env.S3_BUCKET!, Key: key, Body: file.buffer,
        ContentType: file.mimetype,
      }));
      return key;
    }

    const filePath = this.localPath(key);
    await mkdir(resolve(filePath, '..'), { recursive: true, mode: 0o700 });
    await writeFile(filePath, file.buffer, { mode: 0o600 });
    return key;
  }

  async readDocument(key: string): Promise<StoredDocument> {
    if (this.driver() === 's3') {
      const object = await this.s3Client().send(new GetObjectCommand({
        Bucket: process.env.S3_BUCKET!, Key: key,
      }));
      if (!object.Body) throw new NotFoundException('Arquivo não encontrado.');
      return { stream: object.Body as Readable, contentLength: object.ContentLength };
    }

    const filePath = this.localPath(key);
    try {
      const metadata = await stat(filePath);
      return { stream: createReadStream(filePath), contentLength: metadata.size };
    } catch (error: any) {
      if (error?.code === 'ENOENT') throw new NotFoundException('Arquivo não encontrado.');
      throw error;
    }
  }

  async deleteDocument(key?: string | null) {
    if (!key) return;
    if (this.driver() === 's3') {
      await this.s3Client().send(new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: key }));
      return;
    }
    try { await unlink(this.localPath(key)); }
    catch (error: any) { if (error?.code !== 'ENOENT') throw error; }
  }

  async uploadUrl(userId: string, documentId: string, originalName: string, mimeType: string) {
    if (this.driver() !== 's3') throw new BadRequestException('Upload por URL disponível somente com armazenamento S3.');
    const extension = MIME_EXTENSIONS[mimeType]
      ?? (extname(originalName).slice(1).replace(/[^a-zA-Z0-9]/g, '').slice(0, 10) || 'bin');
    const key = `users/${userId}/documents/${documentId}/${randomUUID()}.${extension}`;
    const url = await getSignedUrl(this.s3Client(), new PutObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: key, ContentType: mimeType }), { expiresIn: 300 });
    return { key, url, method: 'PUT', expiresIn: 300, headers: { 'Content-Type': mimeType } };
  }

  async downloadUrl(key: string) {
    if (this.driver() !== 's3') throw new BadRequestException('Download por URL disponível somente com armazenamento S3.');
    return { url: await getSignedUrl(this.s3Client(), new GetObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: key }), { expiresIn: 300 }), expiresIn: 300 };
  }

  private validateFile(file?: Express.Multer.File) {
    if (!file?.buffer?.length) throw new BadRequestException('Selecione um arquivo.');
    if (file.size > DOCUMENT_MAX_BYTES) throw new BadRequestException('O arquivo deve ter no máximo 10 MB.');
    if (!MIME_EXTENSIONS[file.mimetype]) throw new BadRequestException('Envie um arquivo PDF, JPEG ou PNG.');

    const valid = file.mimetype === 'application/pdf'
      ? file.buffer.subarray(0, 5).toString() === '%PDF-'
      : file.mimetype === 'image/jpeg'
        ? file.buffer[0] === 0xff && file.buffer[1] === 0xd8 && file.buffer[2] === 0xff
        : file.buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    if (!valid) throw new BadRequestException('O conteúdo do arquivo não corresponde ao formato informado.');
  }

  private localPath(key: string) {
    const sanitized = normalize(key).replace(/^([/\\])+/, '');
    if (!key || isAbsolute(key) || sanitized.startsWith(`..${sep}`) || sanitized === '..') {
      throw new BadRequestException('Chave de arquivo inválida.');
    }
    const fullPath = resolve(join(this.localRoot(), sanitized));
    if (!fullPath.startsWith(`${this.localRoot()}${sep}`)) throw new BadRequestException('Chave de arquivo inválida.');
    return fullPath;
  }
}
