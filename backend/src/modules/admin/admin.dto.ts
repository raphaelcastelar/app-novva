import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class AdminRequestQueryDto {
  @IsOptional() @IsIn(['ALL', 'DOCUMENT', 'INVOICE']) kind?: string;
  @IsOptional() @IsString() @MaxLength(30) status?: string;
  @IsOptional() @IsString() @MaxLength(160) search?: string;
}

export class AdminUpdateStatusDto {
  @IsString() @MaxLength(30) status!: string;
  @IsOptional() @IsString() @MaxLength(2000) note?: string;
}
