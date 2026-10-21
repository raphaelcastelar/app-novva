ALTER TABLE "invoices" ADD COLUMN "taker_name" VARCHAR(180);

CREATE TABLE "takers" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(180) NOT NULL,
    "cnpj" VARCHAR(14) NOT NULL,
    "municipality" VARCHAR(120) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "takers_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "takers_user_id_cnpj_key" ON "takers"("user_id", "cnpj");
CREATE INDEX "takers_user_id_name_idx" ON "takers"("user_id", "name");

ALTER TABLE "takers" ADD CONSTRAINT "takers_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
