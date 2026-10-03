import {
  IsEmail,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  MinLength,
} from "class-validator";

export class DeleteAccountDto {
  @IsString() @MinLength(8) @MaxLength(128) password!: string;
}

export class UpdateUserDto {
  @IsOptional() @IsString() @MinLength(2) @MaxLength(160) name?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() @MaxLength(20) phone?: string;
}
export class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(40) crm?: string;
  @IsOptional() @IsString() @MaxLength(100) specialty?: string;
  @IsOptional() @IsString() @MaxLength(80) taxRegime?: string;
  @IsOptional() @IsString() @MaxLength(180) companyName?: string;
}
export class CreateCnpjDto {
  @IsString() @MinLength(2) @MaxLength(100) nickname!: string;
  @IsString() @Length(14, 14) cnpj!: string;
  @IsOptional() @IsString() @MaxLength(180) companyName?: string;
}
export class UpdateCnpjDto {
  @IsOptional() @IsString() @MinLength(2) @MaxLength(100) nickname?: string;
  @IsOptional() @IsString() @MaxLength(180) companyName?: string;
}
