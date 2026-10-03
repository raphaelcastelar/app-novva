import { IsEmail, IsIn, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

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
  @IsString() @MaxLength(160) name!: string;
  @IsEmail() @MaxLength(254) email!: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
  @IsOptional() @IsString() @MaxLength(40) crm?: string;
  @IsOptional() @IsString() @MaxLength(100) specialty?: string;
  @IsString() @MaxLength(180) companyName!: string;
}
