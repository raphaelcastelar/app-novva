import { Type } from 'class-transformer';
import { IsBoolean, IsEmail, IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

export class AdminRequestQueryDto {
  @IsOptional() @IsIn(['ALL', 'DOCUMENT', 'INVOICE']) kind?: string;
  @IsOptional() @IsString() @MaxLength(30) status?: string;
  @IsOptional() @IsString() @MaxLength(160) search?: string;
}

export class AdminUpdateStatusDto {
  @IsString() @MaxLength(30) status!: string;
  @IsOptional() @IsString() @MaxLength(2000) note?: string;
}

export class AdminCreateDoctorDto {
  @Matches(/^\d{11}$/) cpf!: string;
  @Matches(/^\d{14}$/) cnpj!: string;
  @IsString() @MaxLength(160) name!: string;
  @IsEmail() @MaxLength(254) email!: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
  @IsOptional() @IsString() @MaxLength(40) crm?: string;
  @IsOptional() @IsString() @MaxLength(100) specialty?: string;
  @IsString() @MaxLength(180) companyName!: string;
}

export class AdminCreateDocumentTypeDto {
  @IsString() @MaxLength(160) name!: string;
  @IsString() @MaxLength(100) category!: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(120) validityMonths?: number | null;
  @IsOptional() @IsBoolean() active?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(10000) sortOrder?: number;
}

export class AdminUpdateDocumentTypeDto {
  @IsOptional() @IsString() @MaxLength(160) name?: string;
  @IsOptional() @IsString() @MaxLength(100) category?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(120) validityMonths?: number | null;
  @IsOptional() @IsBoolean() active?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(10000) sortOrder?: number;
}
