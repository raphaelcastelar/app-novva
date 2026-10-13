ALTER TABLE "obligations"
ADD COLUMN "competence_month" INTEGER,
ADD COLUMN "competence_year" INTEGER,
ADD COLUMN "generated_at" TIMESTAMP(3);

ALTER TABLE "obligations"
ADD CONSTRAINT "obligations_competence_month_check"
CHECK ("competence_month" IS NULL OR "competence_month" BETWEEN 1 AND 12);

CREATE UNIQUE INDEX "obligations_user_id_kind_competence_year_competence_month_key"
ON "obligations"("user_id", "kind", "competence_year", "competence_month");
