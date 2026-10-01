CREATE TYPE "RequestKind" AS ENUM ('DOCUMENT', 'INVOICE');

CREATE TABLE "request_events" (
    "id" UUID NOT NULL,
    "request_kind" "RequestKind" NOT NULL,
    "request_id" UUID NOT NULL,
    "status" VARCHAR(30) NOT NULL,
    "note" TEXT,
    "actor" VARCHAR(160),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "request_events_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "request_events_request_kind_request_id_created_at_idx"
ON "request_events"("request_kind", "request_id", "created_at");
