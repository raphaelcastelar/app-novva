import { IsString, Length, Matches, MinLength } from 'class-validator';

export class CpfDto { @Matches(/^\d{11}$/) cpf!: string; }
export class LoginDto extends CpfDto { @IsString() @MinLength(8) password!: string; }
export class CreatePasswordDto extends LoginDto {}
export class RefreshDto { @IsString() @MinLength(32) refreshToken!: string; }
export class ResetPasswordDto { @IsString() token!: string; @IsString() @MinLength(8) password!: string; }
export class ChangePasswordDto {
  @IsString() currentPassword!: string;
  @IsString() @MinLength(8) @Length(8, 128) newPassword!: string;
}
