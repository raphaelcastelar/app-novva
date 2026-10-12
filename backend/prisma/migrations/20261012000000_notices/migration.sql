CREATE TABLE "notices" (
    "id" UUID NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "description" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "attachment_key" TEXT,
    "attachment_original_name" VARCHAR(255),
    "attachment_mime_type" VARCHAR(100),
    "created_by" VARCHAR(160),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "notices_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "notice_recipients" (
    "notice_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "read_at" TIMESTAMP(3),
    CONSTRAINT "notice_recipients_pkey" PRIMARY KEY ("notice_id", "user_id")
);

CREATE INDEX "notices_active_created_at_idx" ON "notices"("active", "created_at" DESC);
CREATE INDEX "notice_recipients_user_id_read_at_idx" ON "notice_recipients"("user_id", "read_at");
ALTER TABLE "notice_recipients" ADD CONSTRAINT "notice_recipients_notice_id_fkey" FOREIGN KEY ("notice_id") REFERENCES "notices"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "notice_recipients" ADD CONSTRAINT "notice_recipients_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
