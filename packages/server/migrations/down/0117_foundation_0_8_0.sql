-- Back to the database of the foundation 0.6.5, as 0116 left it. Run as the
-- superuser, like every rollback. A chain or a counter opened in this
-- transaction is written first, so that the triggers can go; the right to
-- create in public stays taken, as in opengewerk.
SET CONSTRAINTS "audit_chain_closes", "sync_counter_closes" IMMEDIATE;--> statement-breakpoint
ALTER FUNCTION public.activity_duty_not_at_a_collective() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_emptying_confirmed() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_emptying_empties() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_emptying_of(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_ended_day(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_ended_on() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_kept_once_emptied() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_of_row(jsonb) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_of_service_report(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_of_work_order(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_reopened() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_reopening_of(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_reopening_removes() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.activity_retention_ends(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.answers_about_the_assets_of_their_point() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.answers_kept_once_signed() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.answers_more_photos_at_their_activity() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.application_attachment_may_go(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.area_from_the_property() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.asset_duplicate_candidates(text[],text[]) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.asset_hangs_not_under_itself() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.asset_stays_on_its_property() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.assets_with_evidence_stay() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.board_buildings_of(uuid,uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.boards_follow_their_installation() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.boards_in_a_building_of_their_installation() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.boards_on_a_low_voltage_installation() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.booking_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.briefing_names_its_page() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.building_on_a_property_in_reach() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.certificate_of_an_emptying(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.contact_to_confirm(text) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_emptying_confirmed() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_emptying_empties() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_emptying_of(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_kept_once_emptied() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_remedied_day(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_remedied_on() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.defect_retention_ends(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.delegation_kept_as_signed() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.delegation_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.each_once(anyarray) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.empty_the_activity(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.emptying_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.evidence_emptying_confirmed() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.evidence_emptying_empties() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.evidence_emptying_of(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.evidence_retention_ends(uuid) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.evidence_stays_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.grant_default_areas(uuid,text) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.import_record() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.import_writing() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.inverters_on_a_photovoltaic_installation() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.keep_label_given() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.label_open_to_reports(text) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.label_state_in_tenant(text) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_activities_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_assets_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_below_a_contract() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_below_a_contractor() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_closures_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_contacts_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_documents_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_duties_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_labels_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_places_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_plans_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_structure_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.mark_tasks_below() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.material_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.membership_gets_default_areas() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.note_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.outside_take(text[],text[],integer[],text[],timestamp with time zone) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.own_kind_uses() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.part_of_a_collective() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.person_in_sight(text) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.print_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.print_takes_its_file() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.reading_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.record_emptying_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.record_retention_ended(text,date) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.record_retention_ends(text,date) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.record_retention_years(text) SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.record_task_author() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.refuses_an_emptied_activity() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.removed_only_with_its_activity() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.round_record_once_per_opening() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.service_report_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_areas() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_is_the_deadline_run() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_leads() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_limit_asset_kinds() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_limit_properties() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_sees_all_areas() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.session_works_here() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.signed_print_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.task_done_on() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.task_goes_after_retention() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.tenant_role_leads_alone() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.visit_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
ALTER FUNCTION public.voiding_kept_as_written() SET search_path = pg_catalog, public;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.print_takes_its_file() TO PUBLIC;--> statement-breakpoint
DROP TRIGGER IF EXISTS "audit_chain_closes" ON "audit_chains";--> statement-breakpoint
DROP TRIGGER IF EXISTS "auth_sessions_fit_their_credentials" ON "auth_sessions";--> statement-breakpoint
DROP TRIGGER IF EXISTS "sync_counter_closes" ON "sync_sequences";--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.attachment_may_go(p_attachment uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	allowed boolean;
BEGIN
	IF p_attachment IS NULL OR to_regprocedure('public.application_attachment_may_go(uuid)') IS NULL THEN
		RETURN false;
	END IF;

	EXECUTE 'SELECT public.application_attachment_may_go($1)' INTO allowed USING p_attachment;

	RETURN coalesce(allowed, false);
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.attachment_purging(p_attachment uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT p_attachment IS NOT NULL
	   AND coalesce(current_setting('app.purging_attachment', true), '') = p_attachment::text
	   AND public.attachment_may_go(p_attachment)
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.attachment_version_stays_as_written()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	IF TG_OP = 'DELETE' AND public.attachment_purging(old.attachment_id) THEN
		RETURN old;
	END IF;

	RAISE EXCEPTION 'Eine Fassung einer Datei wird weder geändert noch gelöscht.'
		USING ERRCODE = 'OG001';
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_entry_problem(entry audit_entries)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	kept_witness text;
	is_redacted boolean;
	old_nonce text;
	new_nonce text;
BEGIN
	SELECT max(r.witness), count(*) > 0 INTO kept_witness, is_redacted
	  FROM public.audit_redactions r
	 WHERE r.entry_id = entry.id;

	IF entry.fingerprint_version = 1 AND is_redacted THEN
		IF kept_witness IS DISTINCT FROM public.audit_witness(entry) THEN
			RETURN 'Der Eintrag wurde nach dem Schwärzen verändert.';
		END IF;
	ELSIF entry.hash IS DISTINCT FROM public.audit_fingerprint(entry) THEN
		RETURN 'Der Eintrag wurde nachträglich verändert.';
	END IF;

	IF entry.fingerprint_version >= 2 OR is_redacted THEN
		IF entry.fingerprint_version >= 3 THEN
			SELECT max(n.nonce) FILTER (WHERE n.side = 'old'), max(n.nonce) FILTER (WHERE n.side = 'new')
			  INTO old_nonce, new_nonce
			  FROM public.audit_value_nonces n
			 WHERE n.entry_id = entry.id;

			IF (entry.old_value IS NOT NULL AND public.audit_value_commitment(old_nonce, entry.old_value) IS DISTINCT FROM entry.old_value_digest)
			   OR (entry.new_value IS NOT NULL AND public.audit_value_commitment(new_nonce, entry.new_value) IS DISTINCT FROM entry.new_value_digest) THEN
				RETURN 'Der Eintrag wurde nachträglich verändert.';
			END IF;
		ELSIF (entry.old_value IS NOT NULL AND public.audit_value_digest(entry.old_value) IS DISTINCT FROM entry.old_value_digest)
		   OR (entry.new_value IS NOT NULL AND public.audit_value_digest(entry.new_value) IS DISTINCT FROM entry.new_value_digest) THEN
			RETURN 'Der Eintrag wurde nachträglich verändert.';
		END IF;

		IF (entry.old_value IS NULL AND entry.old_value_digest IS NOT NULL
		    AND NOT EXISTS (SELECT 1 FROM public.audit_redactions r WHERE r.entry_id = entry.id AND r.side = 'old'))
		   OR (entry.new_value IS NULL AND entry.new_value_digest IS NOT NULL
		    AND NOT EXISTS (SELECT 1 FROM public.audit_redactions r WHERE r.entry_id = entry.id AND r.side = 'new')) THEN
			RETURN 'Ein Wert des Eintrags fehlt, ohne dass er geschwärzt wurde.';
		END IF;
	END IF;

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_entry_stays()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	named_side text;
BEGIN
	IF tg_op = 'UPDATE' AND current_setting('app.redacting', true) LIKE old.id::text || ':%' THEN
		named_side := split_part(current_setting('app.redacting', true), ':', 2);

		IF EXISTS (SELECT 1 FROM public.audit_redactions r WHERE r.entry_id = old.id AND r.side = named_side)
		   AND (to_jsonb(new) - 'old_value' - 'new_value' - 'old_value_digest' - 'new_value_digest')
		     = (to_jsonb(old) - 'old_value' - 'new_value' - 'old_value_digest' - 'new_value_digest')
		   AND (CASE WHEN named_side = 'old' THEN new.old_value IS NULL ELSE new.old_value IS NOT DISTINCT FROM old.old_value END)
		   AND (CASE WHEN named_side = 'new' THEN new.new_value IS NULL ELSE new.new_value IS NOT DISTINCT FROM old.new_value END)
		   AND new.old_value_digest IS NOT DISTINCT FROM coalesce(old.old_value_digest, public.audit_value_digest(old.old_value))
		   AND new.new_value_digest IS NOT DISTINCT FROM coalesce(old.new_value_digest, public.audit_value_digest(old.new_value)) THEN
			RETURN new;
		END IF;
	END IF;

	RAISE EXCEPTION 'Das Audit-Log wird nur ergänzt. Ein Eintrag wird weder geändert noch gelöscht.'
		USING ERRCODE = 'OG002';
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_fingerprint(entry audit_entries)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public'
 SET "TimeZone" TO 'UTC'
AS $function$
	SELECT encode(sha256(convert_to(CASE entry.fingerprint_version
		WHEN 1 THEN (to_jsonb(entry) - 'hash' - 'fingerprint_version' - 'old_value_digest' - 'new_value_digest')::text
		ELSE (to_jsonb(entry) - 'hash' - 'old_value' - 'new_value')::text
	END, 'UTF8')), 'hex')
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_redaction_applied()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	PERFORM set_config('app.redacting', new.entry_id::text || ':' || new.side, true);

	UPDATE public.audit_entries e
	   SET old_value = CASE WHEN new.side = 'old' THEN NULL ELSE e.old_value END,
	       new_value = CASE WHEN new.side = 'new' THEN NULL ELSE e.new_value END,
	       old_value_digest = coalesce(e.old_value_digest, public.audit_value_digest(e.old_value)),
	       new_value_digest = coalesce(e.new_value_digest, public.audit_value_digest(e.new_value))
	 WHERE e.id = new.entry_id;

	DELETE FROM public.audit_value_nonces n
	 WHERE n.entry_id = new.entry_id AND n.side = new.side;

	PERFORM set_config('app.redacting', '', true);

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_redaction_checked()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	entry public.audit_entries;
	found_problem text;
BEGIN
	IF new.tenant_id IS DISTINCT FROM nullif(current_setting('app.tenant_id', true), '')::uuid
	   OR NOT EXISTS (
	     SELECT 1 FROM public.memberships m
	       JOIN public.tenant_roles r ON r.tenant_id = m.tenant_id AND r.key = ANY (m.roles) AND r.leads
	      WHERE m.tenant_id = new.tenant_id
	        AND m.user_id = nullif(current_setting('app.user_id', true), '')
	        AND m.blocked_at IS NULL
	        AND (m.last_day IS NULL OR m.last_day >= (now() AT TIME ZONE 'Europe/Berlin')::date)) THEN
		RAISE EXCEPTION 'Einen Wert im Änderungsprotokoll schwärzt nur, wer den Mandanten führt.'
			USING ERRCODE = 'insufficient_privilege';
	END IF;

	SELECT * INTO entry FROM public.audit_entries e
	 WHERE e.id = new.entry_id AND e.tenant_id = new.tenant_id
	   FOR UPDATE;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Diesen Eintrag gibt es im Änderungsprotokoll nicht.'
			USING ERRCODE = 'OG006';
	END IF;

	IF (new.side = 'old' AND entry.old_value IS NULL) OR (new.side = 'new' AND entry.new_value IS NULL) THEN
		RAISE EXCEPTION 'Dieser Wert ist leer oder schon geschwärzt.'
			USING ERRCODE = 'OG006';
	END IF;

	found_problem := public.audit_entry_problem(entry);

	IF found_problem IS NOT NULL THEN
		RAISE EXCEPTION 'Der Eintrag ist nicht mehr, wie er geschrieben wurde; geschwärzt wird nichts. %', found_problem
			USING ERRCODE = 'OG006';
	END IF;

	new.redacted_by := nullif(current_setting('app.user_id', true), '');

	IF entry.fingerprint_version = 1 THEN
		IF entry.old_value_digest IS NULL AND entry.new_value_digest IS NULL THEN
			entry.old_value_digest := public.audit_value_digest(entry.old_value);
			entry.new_value_digest := public.audit_value_digest(entry.new_value);
		END IF;

		new.witness := public.audit_witness(entry);
	ELSE
		new.witness := NULL;
	END IF;

	RETURN new;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_value_commitment(nonce text, value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT CASE WHEN value IS NULL OR nonce IS NULL THEN NULL
		ELSE encode(sha256(decode(nonce, 'hex') || convert_to(value, 'UTF8')), 'hex') END
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_value_digest(value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT CASE WHEN value IS NULL THEN NULL ELSE encode(sha256(convert_to(value, 'UTF8')), 'hex') END
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_witness(entry audit_entries)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public'
 SET "TimeZone" TO 'UTC'
AS $function$
	SELECT encode(sha256(convert_to((to_jsonb(entry) - 'hash' - 'old_value' - 'new_value')::text, 'UTF8')), 'hex')
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.create_first_tenant(company text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	created uuid;
BEGIN
	PERFORM pg_advisory_xact_lock(hashtext('opengewerk.first_run_setup'));

	IF NOT public.instance_is_empty() THEN
		RAISE EXCEPTION 'Diese Instanz ist bereits eingerichtet.'
			USING ERRCODE = 'OG003';
	END IF;

	created := uuidv7();

	INSERT INTO public.tenants (id, name) VALUES (created, company);

	RETURN created;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.create_tenant(company text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	created uuid;
BEGIN
	IF company IS NULL OR length(btrim(company)) = 0 OR length(btrim(company)) > 120 THEN
		RAISE EXCEPTION 'Der Name fehlt oder ist länger als 120 Zeichen.'
			USING ERRCODE = 'OG003';
	END IF;

	created := uuidv7();

	INSERT INTO public.tenants (id, name) VALUES (created, btrim(company));

	RETURN created;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.every_tenant()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT id FROM public.tenants ORDER BY id
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.file_goes_with_its_document()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	IF coalesce(current_setting('app.taking_file', true), '') = old.tenant_id::text || '/' || old.sha256 THEN
		RETURN old;
	END IF;

	RAISE EXCEPTION 'Eine Datei geht nur mit dem Dokument, das sie als Letztes nennt.'
		USING ERRCODE = 'OG001';
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.files_held(candidates text[])
 RETURNS SETOF text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT DISTINCT f.sha256 FROM public.files f WHERE f.sha256 = ANY (candidates)
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.instance_change_stays()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	RAISE EXCEPTION 'Das Protokoll der Instanz wird nur ergänzt. Ein Eintrag wird weder geändert noch gelöscht.'
		USING ERRCODE = 'OG002';
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.instance_is_empty()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT NOT EXISTS (SELECT 1 FROM public.tenants)
	   AND NOT EXISTS (SELECT 1 FROM public.auth_users)
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.invitation_for(hash text)
 RETURNS TABLE(invitation_id uuid, business uuid, company text, invited_email text, invited_name text, invited_roles text[], expires timestamp with time zone, redeemed timestamp with time zone, revoked timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT i.id, i.tenant_id, t.name, i.email, i.name, i.roles,
	       i.expires_at, i.redeemed_at, i.revoked_at
	  FROM public.invitations i
	  JOIN public.tenants t ON t.id = i.tenant_id
	 WHERE i.token_hash = hash
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.keep_label_blocked()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	IF old.blocked_at IS NOT NULL AND new.blocked_at IS DISTINCT FROM old.blocked_at THEN
		RAISE EXCEPTION 'Ein gesperrtes Etikett bleibt gesperrt.'
			USING ERRCODE = 'check_violation';
	END IF;

	RETURN new;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.next_sync_sequence(tenant uuid)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	assigned bigint;
BEGIN
	INSERT INTO public.sync_sequences (tenant_id)
	VALUES (tenant)
	ON CONFLICT (tenant_id) DO UPDATE SET next_value = sync_sequences.next_value + 1,
		updated_at = now()
	RETURNING next_value INTO assigned;

	RETURN assigned;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.purge_attachment(p_attachment uuid, p_title text)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	tenant uuid;
	named text[];
	before text := current_setting('app.purging_attachment', true);
	left_over integer;
BEGIN
	IF NOT public.attachment_may_go(p_attachment) THEN
		RAISE EXCEPTION 'Ein Dokument wird nur auf dem Weg endgültig gelöscht, den die Anwendung dafür öffnet.'
			USING ERRCODE = 'OG001';
	END IF;

	EXECUTE 'SELECT tenant_id FROM public.attachments WHERE id = $1' INTO tenant USING p_attachment;

	IF tenant IS NULL THEN
		RETURN 0;
	END IF;

	PERFORM set_config('app.purging_attachment', p_attachment::text, true);

	EXECUTE 'SELECT coalesce(array_agg(DISTINCT named.hash), ''{}'')
	           FROM (SELECT sha256 AS hash FROM public.attachment_versions WHERE attachment_id = $1
	                 UNION
	                 SELECT preview_sha256 FROM public.attachment_versions
	                  WHERE attachment_id = $1 AND preview_sha256 IS NOT NULL) AS named'
	   INTO named USING p_attachment;

	EXECUTE 'DELETE FROM public.attachment_versions WHERE attachment_id = $1' USING p_attachment;
	EXECUTE 'UPDATE public.attachments SET title = $2, deleted_at = coalesce(deleted_at, now()) WHERE id = $1'
	  USING p_attachment, p_title;

	SELECT count(*) INTO left_over FROM public.files WHERE tenant_id = tenant AND sha256 = ANY (named);

	PERFORM set_config('app.purging_attachment', coalesce(before, ''), true);

	RETURN cardinality(named) - left_over;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.record_attachment_uploader()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	new.created_by := nullif(current_setting('app.user_id', true), '');

	RETURN new;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.record_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	before_row jsonb := '{}'::jsonb;
	after_row jsonb := '{}'::jsonb;
	present jsonb;
	chain public.audit_chains;
	entry public.audit_entries;
	place bigint;
	previous text;
	changed text;
	old_nonce text;
	new_nonce text;
BEGIN
	IF tg_op <> 'INSERT' THEN
		before_row := to_jsonb(old);
	END IF;

	IF tg_op <> 'DELETE' THEN
		after_row := to_jsonb(new);
	END IF;

	present := CASE WHEN tg_op = 'DELETE' THEN before_row ELSE after_row END;

	entry.tenant_id := coalesce(present ->> 'tenant_id', present ->> 'id')::uuid;
	entry.record_id := (present ->> 'id')::uuid;
	entry.change_id := uuidv7();
	entry.table_name := tg_table_name;
	entry.operation := lower(tg_op)::public.audit_operation;
	entry.changed_at := now();
	entry.user_id := nullif(current_setting('app.user_id', true), '');
	entry.reason := nullif(current_setting('app.reason', true), '');
	entry.database_role := session_user;
	entry.fingerprint_version := 3;

	INSERT INTO public.audit_chains (tenant_id)
	VALUES (entry.tenant_id)
	ON CONFLICT (tenant_id) DO UPDATE SET updated_at = now()
	RETURNING * INTO chain;

	place := chain.next_sequence;
	previous := chain.head_hash;

	FOR changed IN
		SELECT k.field
		  FROM jsonb_object_keys(before_row || after_row) AS k(field)
		 WHERE NOT (k.field = ANY (ARRAY['updated_at', 'updated_by', 'version', 'change_sequence']))
		   AND (before_row ->> k.field) IS DISTINCT FROM (after_row ->> k.field)
		 ORDER BY k.field
	LOOP
		entry.id := uuidv7();
		entry.sequence := place;
		entry.previous_hash := previous;
		entry.field := changed;
		entry.old_value := before_row ->> changed;
		entry.new_value := after_row ->> changed;
		old_nonce := CASE WHEN entry.old_value IS NULL THEN NULL
			ELSE encode(uuid_send(gen_random_uuid()) || uuid_send(gen_random_uuid()), 'hex') END;
		new_nonce := CASE WHEN entry.new_value IS NULL THEN NULL
			ELSE encode(uuid_send(gen_random_uuid()) || uuid_send(gen_random_uuid()), 'hex') END;
		entry.old_value_digest := public.audit_value_commitment(old_nonce, entry.old_value);
		entry.new_value_digest := public.audit_value_commitment(new_nonce, entry.new_value);
		entry.hash := public.audit_fingerprint(entry);

		INSERT INTO public.audit_entries VALUES (entry.*);

		INSERT INTO public.audit_value_nonces (entry_id, tenant_id, side, nonce)
		SELECT entry.id, entry.tenant_id, s.side, s.nonce
		  FROM (VALUES ('old', old_nonce), ('new', new_nonce)) AS s(side, nonce)
		 WHERE s.nonce IS NOT NULL;

		previous := entry.hash;
		place := place + 1;
	END LOOP;

	IF place <> chain.next_sequence THEN
		UPDATE public.audit_chains
		   SET next_sequence = place, head_hash = previous, updated_at = now()
		 WHERE tenant_id = entry.tenant_id;
	END IF;

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.record_instance_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	before_row jsonb := '{}'::jsonb;
	after_row jsonb := '{}'::jsonb;
	present jsonb;
	change uuid := uuidv7();
	changed text;
BEGIN
	IF tg_op <> 'INSERT' THEN
		before_row := to_jsonb(old);
	END IF;

	IF tg_op <> 'DELETE' THEN
		after_row := to_jsonb(new);
	END IF;

	present := CASE WHEN tg_op = 'DELETE' THEN before_row ELSE after_row END;

	FOR changed IN
		SELECT k.field
		  FROM jsonb_object_keys(before_row || after_row) AS k(field)
		 WHERE NOT (k.field = ANY (ARRAY['updated_at', 'updated_by', 'version', 'change_sequence', 'mail_server_password', 'signing_key']))
		   AND (before_row ->> k.field) IS DISTINCT FROM (after_row ->> k.field)
		 ORDER BY k.field
	LOOP
		INSERT INTO public.instance_changes (change_id, table_name, record_id, operation, field,
			old_value, new_value, user_id, reason, database_role)
		VALUES (change, tg_table_name, present ->> 'id', lower(tg_op)::public.audit_operation, changed,
			before_row ->> changed, after_row ->> changed,
			nullif(current_setting('app.user_id', true), ''),
			nullif(current_setting('app.reason', true), ''),
			session_user);
	END LOOP;

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.stamp_sync_columns()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	new.updated_at := now();
	new.updated_by := nullif(current_setting('app.user_id', true), '');
	new.device_id := nullif(current_setting('app.device_id', true), '');
	new.version := CASE WHEN tg_op = 'UPDATE' THEN old.version + 1 ELSE 1 END;
	new.change_sequence := public.next_sync_sequence(new.tenant_id);

	RETURN new;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.tenant_role_stays_whole()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
	IF current_user <> 'opengewerk_app' THEN
		RETURN coalesce(new, old);
	END IF;

	IF tg_op = 'DELETE' THEN
		IF old.leads THEN
			RAISE EXCEPTION 'Eine Rolle, die einen Mandanten führt, wird nicht entfernt.'
				USING ERRCODE = 'OG004';
		END IF;

		IF EXISTS (SELECT 1 FROM public.memberships m
		            WHERE m.tenant_id = old.tenant_id AND old.key = ANY (m.roles))
		   OR EXISTS (SELECT 1 FROM public.invitations i
		               WHERE i.tenant_id = old.tenant_id AND old.key = ANY (i.roles)
		                 AND i.redeemed_at IS NULL AND i.revoked_at IS NULL AND i.expires_at > now()) THEN
			RAISE EXCEPTION 'Eine Rolle, die noch einem Zugang oder einer offenen Einladung zugeordnet ist, wird nicht entfernt.'
				USING ERRCODE = 'OG005';
		END IF;

		RETURN old;
	END IF;

	IF old.leads AND (NOT (new.rights @> old.rights) OR (old.second_factor AND NOT new.second_factor)) THEN
		RAISE EXCEPTION 'Eine Rolle, die einen Mandanten führt, behält jedes Recht und den zweiten Faktor.'
			USING ERRCODE = 'OG004';
	END IF;

	RETURN new;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.tenants_with_leads()
 RETURNS TABLE(id uuid, name text, created_at timestamp with time zone, leads text[], members bigint, invited_leads text[])
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
	SELECT t.id, t.name, t.created_at,
	       coalesce((SELECT array_agg(m.user_id ORDER BY m.created_at) FROM public.memberships m
	                  WHERE m.tenant_id = t.id AND m.blocked_at IS NULL
	                    AND (m.last_day IS NULL OR m.last_day >= (now() AT TIME ZONE 'Europe/Berlin')::date)
	                    AND EXISTS (SELECT 1 FROM public.tenant_roles r
	                                 WHERE r.tenant_id = t.id AND r.leads AND r.key = ANY (m.roles))), '{}'),
	       (SELECT count(*) FROM public.memberships m WHERE m.tenant_id = t.id),
	       coalesce((SELECT array_agg(i.email ORDER BY i.created_at) FROM public.invitations i
	                  WHERE i.tenant_id = t.id
	                    AND i.redeemed_at IS NULL AND i.revoked_at IS NULL AND i.expires_at > now()
	                    AND EXISTS (SELECT 1 FROM public.tenant_roles r
	                                 WHERE r.tenant_id = t.id AND r.leads AND r.key = ANY (i.roles))
	                    AND EXISTS (SELECT 1 FROM public.instance_operators o
	                                 WHERE o.user_id = i.invited_by)), '{}')
	  FROM public.tenants t
	 ORDER BY t.created_at, t.name
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.verify_audit_chain(tenant uuid)
 RETURNS TABLE(checked bigint, broken_at bigint, problem text)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	entry public.audit_entries;
	expected bigint := 1;
	previous text := NULL;
	found_problem text;
BEGIN
	checked := 0;
	broken_at := NULL;
	problem := NULL;

	FOR entry IN
		SELECT * FROM public.audit_entries e
		 WHERE e.tenant_id = tenant
		 ORDER BY e.sequence
	LOOP
		IF entry.sequence <> expected THEN
			broken_at := expected;
			problem := format('Eintrag %s fehlt, der nächste trägt die Nummer %s.',
				expected, entry.sequence);
			RETURN NEXT;
			RETURN;
		END IF;

		IF entry.previous_hash IS DISTINCT FROM previous THEN
			broken_at := entry.sequence;
			problem := 'Der Eintrag verweist nicht auf seinen Vorgänger.';
			RETURN NEXT;
			RETURN;
		END IF;

		found_problem := public.audit_entry_problem(entry);

		IF found_problem IS NOT NULL THEN
			broken_at := entry.sequence;
			problem := found_problem;
			RETURN NEXT;
			RETURN;
		END IF;

		checked := checked + 1;
		previous := entry.hash;
		expected := expected + 1;
	END LOOP;

	RETURN NEXT;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.version_takes_its_files()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
	hash text;
BEGIN
	IF coalesce(current_setting('app.purging_attachment', true), '') <> old.attachment_id::text THEN
		RETURN NULL;
	END IF;

	FOREACH hash IN ARRAY ARRAY[old.sha256, old.preview_sha256] LOOP
		CONTINUE WHEN hash IS NULL;

		PERFORM set_config('app.taking_file', old.tenant_id::text || '/' || hash, true);

		BEGIN
			DELETE FROM public.files WHERE tenant_id = old.tenant_id AND sha256 = hash;
		EXCEPTION WHEN foreign_key_violation OR restrict_violation THEN
			-- Another record still names the file, and it stays.
			NULL;
		END;
	END LOOP;

	PERFORM set_config('app.taking_file', '', true);

	RETURN NULL;
END;
$function$;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.audit_redaction_applied() TO PUBLIC;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.audit_redaction_checked() TO PUBLIC;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.record_change() TO PUBLIC;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.record_instance_change() TO PUBLIC;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.version_takes_its_files() TO PUBLIC;--> statement-breakpoint
DROP FUNCTION IF EXISTS public.take_sync_numbers(uuid,bigint);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.session_fits_its_credentials();--> statement-breakpoint
DROP FUNCTION IF EXISTS public.lock_sync_counter(uuid);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.lock_audit_chain(uuid);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.file_naming_lock(uuid);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.file_named_by_a_value(uuid,text);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.counter_address(text,uuid);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.close_sync_counter();--> statement-breakpoint
DROP FUNCTION IF EXISTS public.close_audit_chain();--> statement-breakpoint
DROP FUNCTION IF EXISTS public.audit_chain_head(uuid,bigint,text);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.keep_counter_hint(text,uuid,text);--> statement-breakpoint
DROP FUNCTION IF EXISTS public.counter_hint(text,uuid);--> statement-breakpoint
ALTER TABLE "sync_sequences" DROP COLUMN IF EXISTS "opened_in";--> statement-breakpoint
ALTER TABLE "auth_users" DROP COLUMN IF EXISTS "credential_generation";--> statement-breakpoint
ALTER TABLE "auth_sessions" DROP COLUMN IF EXISTS "credential_generation";--> statement-breakpoint
ALTER TABLE "audit_chains" DROP COLUMN IF EXISTS "opened_in";
