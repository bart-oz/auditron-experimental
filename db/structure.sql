CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" uuid NOT NULL PRIMARY KEY, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Auditron'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" uuid NOT NULL PRIMARY KEY, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" uuid NOT NULL, "blob_id" uuid NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Auditron'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Auditron'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" uuid NOT NULL PRIMARY KEY, "blob_id" uuid NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Auditron'*/;
CREATE TABLE IF NOT EXISTS "users" ("id" uuid NOT NULL PRIMARY KEY, "email" varchar NOT NULL, "password_digest" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='Auditron'*/;
CREATE TABLE IF NOT EXISTS "api_keys" ("id" uuid NOT NULL PRIMARY KEY, "user_id" uuid NOT NULL, "token_digest" varchar, "name" varchar, "last_used_at" datetime(6), "expires_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_32c28d0dc2"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_api_keys_on_user_id" ON "api_keys" ("user_id") /*application='Auditron'*/;
CREATE UNIQUE INDEX "index_api_keys_on_token_digest" ON "api_keys" ("token_digest") /*application='Auditron'*/;
CREATE TABLE IF NOT EXISTS "reconciliations" ("id" uuid NOT NULL PRIMARY KEY, "user_id" uuid NOT NULL, "status" integer DEFAULT 0 NOT NULL, "bank_only_count" integer DEFAULT 0, "processor_only_count" integer DEFAULT 0, "matched_count" integer DEFAULT 0, "discrepancy_count" integer DEFAULT 0, "report" text, "error_message" text, "processed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_5b0ae5cf13"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_reconciliations_on_user_id" ON "reconciliations" ("user_id") /*application='Auditron'*/;
CREATE INDEX "index_reconciliations_on_user_id_and_status" ON "reconciliations" ("user_id", "status") /*application='Auditron'*/;
CREATE INDEX "index_reconciliations_on_user_id_and_created_at" ON "reconciliations" ("user_id", "created_at") /*application='Auditron'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20251215001906'),
('20251215001856'),
('20251215001843'),
('20251215001836'),
('20251215000100');

