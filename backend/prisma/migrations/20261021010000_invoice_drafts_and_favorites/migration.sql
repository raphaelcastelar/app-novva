CREATE TABLE "invoice_drafts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "taker_cnpj" VARCHAR(14) NOT NULL,
    "taker_name" VARCHAR(180) NOT NULL,
    "municipality" VARCHAR(120) NOT NULL,
    "service_date" DATE NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "taxation_code" VARCHAR(30) NOT NULL,
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "invoice_drafts_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "invoice_description_favorites" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "description" VARCHAR(2000) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "invoice_description_favorites_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "invoice_drafts_user_id_key" ON "invoice_drafts"("user_id");
CREATE UNIQUE INDEX "invoice_description_favorites_user_id_description_key" ON "invoice_description_favorites"("user_id", "description");
CREATE INDEX "invoice_description_favorites_user_id_created_at_idx" ON "invoice_description_favorites"("user_id", "created_at");

ALTER TABLE "invoice_drafts" ADD CONSTRAINT "invoice_drafts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "invoice_description_favorites" ADD CONSTRAINT "invoice_description_favorites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
