CREATE TABLE "document_types" (
  "id" UUID NOT NULL,
  "key" VARCHAR(100) NOT NULL,
  "name" VARCHAR(160) NOT NULL,
  "category" VARCHAR(100) NOT NULL DEFAULT 'Documentos',
  "validity_months" INTEGER,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "document_types_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "document_types_key_key" ON "document_types"("key");
CREATE INDEX "document_types_active_sort_order_idx" ON "document_types"("active", "sort_order");

ALTER TABLE "documents" ADD COLUMN "document_type_id" UUID;
ALTER TABLE "documents" ADD COLUMN "file_uploaded_at" TIMESTAMP(3);
CREATE INDEX "documents_document_type_id_idx" ON "documents"("document_type_id");
ALTER TABLE "documents" ADD CONSTRAINT "documents_document_type_id_fkey"
  FOREIGN KEY ("document_type_id") REFERENCES "document_types"("id") ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO "document_types" ("id", "key", "name", "category", "validity_months", "active", "sort_order", "updated_at") VALUES
  ('10000000-0000-4000-8000-000000000001', 'cartao-cnpj', 'Cartão CNPJ', 'Empresa', NULL, true, 10, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000002', 'certidao-regularidade', 'Certidão de regularidade', 'Fiscal', 6, true, 20, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000003', 'contrato-social', 'Contrato social', 'Empresa', NULL, true, 30, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000004', 'alteracao-contratual', 'Alteração contratual', 'Empresa', NULL, true, 40, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000005', 'declaracao-imposto-renda', 'Declaração de Imposto de Renda', 'IRPF', NULL, true, 50, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000006', 'registro-junta-comercial', 'Registro na Junta Comercial', 'Empresa', NULL, true, 60, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000007', 'alvara-funcionamento', 'Alvará de funcionamento', 'Clínica', NULL, true, 70, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000008', 'outro-documento', 'Outro documento', 'Outros', NULL, true, 80, CURRENT_TIMESTAMP);

UPDATE "documents" SET "document_type_id" = '10000000-0000-4000-8000-000000000001'
WHERE lower("title") LIKE '%cnpj%';
UPDATE "documents" SET "document_type_id" = '10000000-0000-4000-8000-000000000002'
WHERE lower("title") LIKE '%certid_o%regularidade%';
UPDATE "documents" SET "document_type_id" = '10000000-0000-4000-8000-000000000003'
WHERE lower("title") = 'contrato social';
UPDATE "documents" AS document
SET "file_uploaded_at" = COALESCE(
  (
    SELECT MAX(event."created_at")
    FROM "request_events" AS event
    WHERE event."request_kind" = 'DOCUMENT'
      AND event."request_id" = document."id"
      AND event."note" LIKE 'Arquivo %'
  ),
  document."updated_at"
)
WHERE document."file_key" IS NOT NULL;
