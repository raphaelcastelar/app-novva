import { IsDateString, IsIn, IsInt, IsNumber, IsOptional, IsString, Length, Max, MaxLength, Min } from 'class-validator';
export class PageDto { @IsOptional() @IsInt() @Min(1) page = 1; @IsOptional() @IsInt() @Min(1) @Max(100) limit = 30; }
export class CreateDocumentDto {
  @IsString() @MaxLength(160) title!: string; @IsString() @MaxLength(100) category!: string;
  @IsOptional() @IsString() description?: string; @IsOptional() @IsInt() @Min(1) @Max(12) month?: number;
  @IsOptional() @IsInt() @Min(2000) @Max(2200) year?: number;
}
export class CreateInvoiceDto {
  @IsString() @Length(14,14) takerCnpj!: string; @IsString() @MaxLength(120) municipality!: string;
  @IsDateString() serviceDate!: string; @IsNumber() @Min(0.01) amount!: number;
  @IsString() @MaxLength(30) taxationCode!: string; @IsString() @MaxLength(2000) description!: string;
  @IsOptional() @IsString() issueTime?: string;
}
export class SendMessageDto { @IsString() @MaxLength(4000) body!: string; }
export class DocumentUploadDto {
  @IsString() @MaxLength(255) originalName!: string;
  @IsIn(['application/pdf','image/jpeg','image/png']) mimeType!: string;
}
export class ConfirmDocumentUploadDto extends DocumentUploadDto { @IsString() @MaxLength(1000) key!: string; }
