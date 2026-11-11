-- Pasta do cliente: documentos enviados pelo escritório e catálogo de pastas.
CREATE TYPE "DocumentOrigin" AS ENUM ('APP', 'OFFICE');

ALTER TABLE "documents" ADD COLUMN "origin" "DocumentOrigin" NOT NULL DEFAULT 'APP';
CREATE INDEX "documents_user_id_origin_idx" ON "documents"("user_id", "origin");

-- Tipos marcados como não solicitáveis só podem ser enviados pelo escritório.
ALTER TABLE "document_types" ADD COLUMN "requestable" BOOLEAN NOT NULL DEFAULT true;

INSERT INTO "document_types" ("id", "key", "name", "category", "validity_months", "active", "requestable", "sort_order", "updated_at") VALUES
  ('10000000-0000-4000-8000-000000000009', 'inscricao-municipal', 'Inscrição municipal', 'Empresa', NULL, true, true, 65, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000010', 'das-simples-nacional', 'DAS - Simples Nacional', 'Fiscal', NULL, true, false, 110, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000011', 'extrato-simples-nacional', 'Extrato do Simples Nacional', 'Fiscal', NULL, true, true, 120, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000012', 'recibo-pgdas-d', 'Declaração/recibo PGDAS-D', 'Fiscal', NULL, true, false, 130, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000013', 'defis', 'DEFIS - Declaração anual do Simples', 'Fiscal', NULL, true, false, 140, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000014', 'guia-parcelamento-simples', 'Guia de parcelamento do Simples', 'Fiscal', NULL, true, false, 150, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000015', 'guia-iss', 'Guia de ISS', 'Fiscal', NULL, true, false, 160, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000016', 'nota-fiscal-servico', 'Nota fiscal de serviço (NFS-e)', 'Fiscal', NULL, true, false, 170, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000017', 'recibo-pro-labore', 'Recibo de pró-labore', 'Pessoal', NULL, true, true, 210, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000018', 'guia-inss-dctfweb', 'Guia INSS (DCTFWeb)', 'Pessoal', NULL, true, false, 220, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000019', 'recibo-dctfweb', 'Recibo DCTFWeb', 'Pessoal', NULL, true, false, 230, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000020', 'guia-fgts', 'Guia FGTS', 'Pessoal', NULL, true, false, 240, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000021', 'folha-pagamento', 'Folha de pagamento', 'Pessoal', NULL, true, false, 250, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000022', 'balanco-patrimonial', 'Balanço patrimonial', 'Contábil', NULL, true, true, 310, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000023', 'dre', 'Demonstração do resultado (DRE)', 'Contábil', NULL, true, true, 320, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000024', 'balancete', 'Balancete', 'Contábil', NULL, true, false, 330, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000025', 'informe-rendimentos', 'Informe de rendimentos', 'IRPF', NULL, true, true, 410, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000026', 'recibo-entrega-irpf', 'Recibo de entrega do IRPF', 'IRPF', NULL, true, false, 420, CURRENT_TIMESTAMP),
  ('10000000-0000-4000-8000-000000000027', 'honorario-contabil', 'Honorário contábil (boleto)', 'Financeiro', NULL, true, false, 510, CURRENT_TIMESTAMP)
ON CONFLICT ("key") DO NOTHING;
