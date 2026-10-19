import { PushPlatform } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class RegisterPushDeviceDto {
  @IsString()
  @MinLength(20)
  @MaxLength(4096)
  token!: string;

  @IsEnum(PushPlatform)
  platform!: PushPlatform;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  appVersion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  deviceId?: string;
}

export class RemovePushDeviceDto {
  @IsString()
  @MinLength(20)
  @MaxLength(4096)
  token!: string;
}
