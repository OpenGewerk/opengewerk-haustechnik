-- The database of the foundation 0.9.0 (opengewerk 0.8.0 to 0.9.0), as the
-- migrations 0153 and 0156 of the repository opengewerk bring it to the
-- Handwerkersoftware; every application follows the blocks with a migration
-- of its own (ADR 0010 there).
--
-- - Two facts of a circuit (0153 there, opengewerk#1021): its nominal voltage
--   after Table 6.1 of DIN VDE 0100-600 and whether its RCD is selective. A
--   circuit from before is up to 500 V with an RCD of the general kind.
-- - How an update from the area of the instance ended (0156 there,
--   opengewerk#1093): `instance_updates` outside any tenant, with the trigger
--   of the instance, and `update_notices` in every tenant, with the audit
--   trigger. This application binds no update of the instance yet and writes
--   no such rows; the tables are the foundation's, and its blocks name them.
--
-- Everything down to the policies comes from the schema. What follows them is
-- written by hand: FORCE, the grant and the trigger of each table. A row says
-- how a run ended, so the grant stops at INSERT. No row is touched.
CREATE TYPE "public"."circuit_voltage_class" AS ENUM('up_to_500', 'selv_pelv', 'above_500');--> statement-breakpoint
CREATE TABLE "instance_updates" (
	"id" uuid PRIMARY KEY NOT NULL,
	"to_version" text NOT NULL,
	"from_version" text,
	"succeeded" boolean NOT NULL,
	"stopped_in" text,
	"finished_at" timestamp with time zone NOT NULL,
	CONSTRAINT "instance_updates_stopped_somewhere" CHECK ("instance_updates"."succeeded" = ("instance_updates"."stopped_in" is null))
);
--> statement-breakpoint
ALTER TABLE "instance_updates" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "update_notices" (
	"id" uuid PRIMARY KEY DEFAULT uuidv7() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"run_id" uuid NOT NULL,
	"to_version" text NOT NULL,
	"from_version" text,
	"succeeded" boolean NOT NULL,
	"stopped_in" text,
	"finished_at" timestamp with time zone NOT NULL,
	CONSTRAINT "update_notices_once" UNIQUE("tenant_id","run_id"),
	CONSTRAINT "update_notices_stopped_somewhere" CHECK ("update_notices"."succeeded" = ("update_notices"."stopped_in" is null))
);
--> statement-breakpoint
ALTER TABLE "update_notices" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "circuits" ADD COLUMN "voltage_class" "circuit_voltage_class" DEFAULT 'up_to_500' NOT NULL;--> statement-breakpoint
ALTER TABLE "circuits" ADD COLUMN "rcd_selective" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "update_notices" ADD CONSTRAINT "update_notices_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "circuits" ADD CONSTRAINT "circuits_selective_rcd_has_type" CHECK (not "circuits"."rcd_selective" or "circuits"."rcd_type" is not null);--> statement-breakpoint
CREATE POLICY "outside_any_tenant" ON "instance_updates" AS PERMISSIVE FOR ALL TO "opengewerk_app" USING (nullif(current_setting('app.tenant_id', true), '') is null) WITH CHECK (nullif(current_setting('app.tenant_id', true), '') is null);--> statement-breakpoint
CREATE POLICY "tenant_isolation" ON "update_notices" AS PERMISSIVE FOR ALL TO "opengewerk_app" USING ("update_notices"."tenant_id" = nullif(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK ("update_notices"."tenant_id" = nullif(current_setting('app.tenant_id', true), '')::uuid);--> statement-breakpoint

ALTER TABLE "instance_updates" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
GRANT SELECT, INSERT ON "instance_updates" TO "opengewerk_app";--> statement-breakpoint
CREATE TRIGGER "instance_changes" AFTER INSERT OR UPDATE OR DELETE ON "instance_updates"
	FOR EACH ROW EXECUTE FUNCTION "record_instance_change"();--> statement-breakpoint

ALTER TABLE "update_notices" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
GRANT SELECT, INSERT ON "update_notices" TO "opengewerk_app";--> statement-breakpoint
CREATE TRIGGER "audit_changes" AFTER INSERT OR UPDATE OR DELETE ON "update_notices"
	FOR EACH ROW EXECUTE FUNCTION "record_change"();
