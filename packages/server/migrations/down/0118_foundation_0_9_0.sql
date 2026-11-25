-- Back to the database of the foundation 0.8.0, as 0117 left it. Run as the
-- superuser, like every rollback. The rows of the logs of updates go without
-- asking; what they said stays in the log of the instance and in the audit log
-- of every tenant. The nominal voltage and the selective RCD go with their
-- columns.
DROP TRIGGER IF EXISTS "audit_changes" ON "update_notices";--> statement-breakpoint
DROP POLICY IF EXISTS "tenant_isolation" ON "update_notices";--> statement-breakpoint
DROP TABLE IF EXISTS "update_notices";--> statement-breakpoint
DROP TRIGGER IF EXISTS "instance_changes" ON "instance_updates";--> statement-breakpoint
DROP POLICY IF EXISTS "outside_any_tenant" ON "instance_updates";--> statement-breakpoint
DROP TABLE IF EXISTS "instance_updates";--> statement-breakpoint
ALTER TABLE "circuits" DROP CONSTRAINT "circuits_selective_rcd_has_type";--> statement-breakpoint
ALTER TABLE "circuits" DROP COLUMN "rcd_selective";--> statement-breakpoint
ALTER TABLE "circuits" DROP COLUMN "voltage_class";--> statement-breakpoint
DROP TYPE "public"."circuit_voltage_class";
