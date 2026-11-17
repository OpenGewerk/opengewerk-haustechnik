-- The database of the foundation 0.8.0 (opengewerk 0.6.5 to 0.8.0), as the
-- migrations 0137, 0140, 0142, 0148, 0149 and 0150 of the repository
-- opengewerk bring it to the Handwerkersoftware; every application follows the
-- blocks with a migration of its own (ADR 0010 there).
--
-- - The count of an account's credentials (0137 there, opengewerk#898): a
--   session written in the moment the credentials were taken back does not
--   count. The sessions of before get the count their account has.
-- - A file goes for good only once nothing names it, and never while somebody
--   is about to name it (0140 and 0142 there, opengewerk#911): the lock of the
--   tenant's chain of the log, taken in the order every logged change takes it.
--   Here that holds for a key only. This application does not answer
--   `application_file_named_by_a_value` yet, so a file that only a value names,
--   as an evidence names its files in its state, is not held by it
--   (opengewerk-haustechnik#622).
-- - The counter of the sync and the chain of the log go through the address
--   the transaction holds and are written once, before the commit (0148 and
--   0149 there, opengewerk#953).
-- - Every trigger function of the foundation that runs as the owner is closed
--   to every role but the owner, no role but the owner creates in public, and
--   every function names the temporary schema last in its search path (0150
--   there, opengewerk#975). That holds for the functions of this application
--   as well; `print_takes_its_file` (0106), which runs as the owner and takes
--   rows out of `files`, was open to every role and is closed here.
--
-- Row level security is lifted on the sessions for the statement that fills
-- them, because as the owner under FORCE it would find no row and say
-- nothing.
ALTER TABLE "audit_chains" ADD COLUMN "opened_in" "xid8";--> statement-breakpoint
ALTER TABLE "auth_sessions" ADD COLUMN "credential_generation" integer;--> statement-breakpoint
ALTER TABLE "auth_users" ADD COLUMN "credential_generation" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "sync_sequences" ADD COLUMN "opened_in" "xid8";--> statement-breakpoint
ALTER TABLE "auth_sessions" NO FORCE ROW LEVEL SECURITY;--> statement-breakpoint
UPDATE "auth_sessions" s SET "credential_generation" = u."credential_generation"
	FROM "auth_users" u WHERE u."id" = s."user_id";--> statement-breakpoint
ALTER TABLE "auth_sessions" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.counter_hint(kind text, tenant uuid)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT current_setting('opengewerk_' || kind || '.t' || replace(tenant::text, '-', ''), true);
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.keep_counter_hint(kind text, tenant uuid, hint text)
 RETURNS void
 LANGUAGE sql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT set_config('opengewerk_' || kind || '.t' || replace(tenant::text, '-', ''), hint, true);
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_chain_head(tenant uuid, committed_place bigint, committed_hash text, OUT place bigint, OUT previous text)
 RETURNS record
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
 SET enable_seqscan TO 'off'
 SET enable_bitmapscan TO 'off'
 SET enable_sort TO 'off'
AS $function$
DECLARE
	held text := public.counter_hint('audit_head', tenant);
	last record;
BEGIN
	place := committed_place;
	previous := committed_hash;

	IF held = 'opened' THEN
		RETURN;
	END IF;

	IF held ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
		SELECT e.tenant_id, e.sequence, e.hash INTO last FROM public.audit_entries e WHERE e.id = held::uuid;

		IF FOUND AND last.tenant_id = tenant AND last.sequence >= committed_place THEN
			place := last.sequence + 1;
			previous := last.hash;
			RETURN;
		END IF;
	END IF;

	SELECT e.sequence + 1, e.hash INTO place, previous
	  FROM public.audit_entries e
	 WHERE e.tenant_id = tenant AND e.sequence >= committed_place
	 ORDER BY e.sequence DESC
	 LIMIT 1;

	IF NOT FOUND THEN
		place := committed_place;
		previous := committed_hash;
	END IF;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.close_audit_chain()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
 SET enable_seqscan TO 'off'
 SET enable_bitmapscan TO 'off'
 SET enable_sort TO 'off'
AS $function$
DECLARE
	chain record;
	place bigint;
	previous text;
BEGIN
	SELECT c.next_sequence, c.head_hash, c.ctid AS address INTO chain
	  FROM public.audit_chains c
	 WHERE c.tenant_id = new.tenant_id FOR NO KEY UPDATE;

	IF NOT FOUND THEN
		RETURN NULL;
	END IF;

	SELECT e.sequence + 1, e.hash INTO place, previous
	  FROM public.audit_entries e
	 WHERE e.tenant_id = new.tenant_id AND e.sequence >= chain.next_sequence
	 ORDER BY e.sequence DESC
	 LIMIT 1;

	IF NOT FOUND THEN
		place := chain.next_sequence;
		previous := chain.head_hash;
	END IF;

	UPDATE public.audit_chains
	   SET next_sequence = place, head_hash = previous, opened_in = NULL, updated_at = now()
	 WHERE ctid = chain.address AND tenant_id = new.tenant_id;

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.close_sync_counter()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
 SET enable_seqscan TO 'off'
AS $function$
BEGIN
	UPDATE public.sync_sequences
	   SET next_value = currval(pg_catalog.format('%I.%I', 'public', 'sync_counter_t' || replace(new.tenant_id::text, '-', ''))::regclass),
	       opened_in = NULL,
	       updated_at = now()
	 WHERE tenant_id = new.tenant_id AND opened_in = pg_current_xact_id();

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.counter_address(kind text, tenant uuid)
 RETURNS tid
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
DECLARE
	parts text[] := regexp_match(public.counter_hint(kind, tenant), '^\((\d{1,10}),(\d{1,5})\)$');
BEGIN
	-- Within the range of a `tid` as well, so that a made-up address finds
	-- nothing rather than failing the cast.
	IF parts IS NOT NULL AND parts[1]::bigint <= 4294967295 AND parts[2]::integer <= 65535 THEN
		RETURN ('(' || parts[1] || ',' || parts[2] || ')')::tid;
	END IF;

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.file_named_by_a_value(p_tenant uuid, p_hash text)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
DECLARE
	named boolean;
BEGIN
	PERFORM public.lock_sync_counter(p_tenant);
	PERFORM public.lock_audit_chain(p_tenant);

	IF to_regprocedure('public.application_file_named_by_a_value(uuid,text)') IS NULL THEN
		RETURN false;
	END IF;

	EXECUTE 'SELECT public.application_file_named_by_a_value($1, $2)' INTO named USING p_tenant, p_hash;

	RETURN coalesce(named, false);
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.file_naming_lock(p_tenant uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
BEGIN
	IF p_tenant IS NULL OR p_tenant::text IS DISTINCT FROM nullif(current_setting('app.tenant_id', true), '') THEN
		RAISE EXCEPTION 'Gesperrt wird nur für den Mandanten der Transaktion.'
			USING ERRCODE = 'OG001';
	END IF;

	PERFORM public.lock_sync_counter(p_tenant);
	PERFORM public.lock_audit_chain(p_tenant);
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.lock_audit_chain(tenant uuid, OUT next_sequence bigint, OUT head_hash text, OUT opened_in xid8, OUT address tid)
 RETURNS record
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
 SET enable_seqscan TO 'off'
 SET enable_indexscan TO 'off'
 SET enable_bitmapscan TO 'off'
AS $function$
BEGIN
	address := public.counter_address('audit', tenant);

	IF address IS NOT NULL THEN
		SELECT c.next_sequence, c.head_hash, c.opened_in, c.ctid INTO next_sequence, head_hash, opened_in, address
		  FROM public.audit_chains c
		 WHERE c.ctid = address AND c.tenant_id = tenant FOR NO KEY UPDATE;
	END IF;

	IF address IS NULL THEN
		SELECT c.next_sequence, c.head_hash, c.opened_in, c.ctid INTO next_sequence, head_hash, opened_in, address
		  FROM public.audit_chains c
		 WHERE c.tenant_id = tenant FOR NO KEY UPDATE;

		IF NOT FOUND THEN
			INSERT INTO public.audit_chains AS c (tenant_id)
			VALUES (tenant)
			ON CONFLICT (tenant_id) DO UPDATE SET updated_at = now()
			RETURNING c.next_sequence, c.head_hash, c.opened_in, c.ctid INTO next_sequence, head_hash, opened_in, address;
		END IF;

		PERFORM public.keep_counter_hint('audit', tenant, address::text);
	END IF;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.lock_sync_counter(tenant uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
 SET enable_seqscan TO 'off'
 SET enable_indexscan TO 'off'
 SET enable_bitmapscan TO 'off'
AS $function$
DECLARE
	address tid := public.counter_address('sync', tenant);
BEGIN
	IF address IS NOT NULL THEN
		SELECT ctid INTO address FROM public.sync_sequences
		 WHERE ctid = address AND tenant_id = tenant FOR NO KEY UPDATE;
	END IF;

	IF address IS NULL THEN
		SELECT ctid INTO address FROM public.sync_sequences WHERE tenant_id = tenant FOR NO KEY UPDATE;

		IF NOT FOUND THEN
			INSERT INTO public.sync_sequences (tenant_id, next_value) VALUES (tenant, 0) ON CONFLICT (tenant_id) DO NOTHING;
			SELECT ctid INTO address FROM public.sync_sequences WHERE tenant_id = tenant FOR NO KEY UPDATE;
		END IF;

		PERFORM public.keep_counter_hint('sync', tenant, address::text);
	END IF;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.session_fits_its_credentials()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
DECLARE
	standing integer;
BEGIN
	SELECT u.credential_generation INTO standing
	  FROM public.auth_users u
	 WHERE u.id = NEW.user_id
	   FOR SHARE;

	IF NEW.credential_generation IS NOT NULL
	   AND (standing IS NULL OR NEW.credential_generation <> standing) THEN
		RAISE EXCEPTION 'Die Anmeldung begann vor einer Änderung der Zugangsdaten und gilt nicht. Bitte noch einmal anmelden.'
			USING ERRCODE = 'OG015';
	END IF;

	RETURN NEW;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.take_sync_numbers(tenant uuid, amount bigint)
 RETURNS bigint
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'pg_temp'
 SET enable_seqscan TO 'off'
AS $function$
DECLARE
	counter text := pg_catalog.format('%I.%I', 'public', 'sync_counter_t' || replace(tenant::text, '-', ''));
	opened xid8;
	committed bigint;
	first bigint;
BEGIN
	SELECT opened_in INTO opened FROM public.sync_sequences WHERE tenant_id = tenant;

	IF opened IS NOT DISTINCT FROM pg_current_xact_id() THEN
		first := nextval(counter::regclass);

		IF amount > 1 THEN
			PERFORM setval(counter::regclass, first + amount - 1, true);
		END IF;

		RETURN first;
	END IF;

	-- On first use the row is made with no number handed out yet, so that the
	-- first is still 1. The lock waits for whoever has the counter open and
	-- then reads the last number that one committed.
	INSERT INTO public.sync_sequences (tenant_id, next_value) VALUES (tenant, 0)
	ON CONFLICT (tenant_id) DO NOTHING;

	SELECT next_value INTO committed FROM public.sync_sequences WHERE tenant_id = tenant FOR NO KEY UPDATE;

	IF to_regclass(counter) IS NULL THEN
		EXECUTE pg_catalog.format('CREATE SEQUENCE %s AS bigint MINVALUE 0', counter);
	ELSIF NOT EXISTS (
		SELECT 1
		  FROM pg_catalog.pg_class c
		 WHERE c.oid = to_regclass(counter)::oid
		   AND c.relkind = 'S'
		   AND c.relowner = (SELECT t.relowner FROM pg_catalog.pg_class t WHERE t.oid = 'public.sync_sequences'::regclass::oid)
	) THEN
		RAISE EXCEPTION 'Der Zähler des Abgleichs eines Mandanten ist keine Sequenz des Eigentümers der Tabellen: %', counter;
	END IF;

	PERFORM setval(counter::regclass, committed, true);
	first := nextval(counter::regclass);

	IF amount > 1 THEN
		PERFORM setval(counter::regclass, first + amount - 1, true);
	END IF;

	UPDATE public.sync_sequences SET opened_in = pg_current_xact_id(), updated_at = now()
	 WHERE tenant_id = tenant;

	RETURN first;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.attachment_may_go(p_attachment uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT p_attachment IS NOT NULL
	   AND coalesce(current_setting('app.purging_attachment', true), '') = p_attachment::text
	   AND public.attachment_may_go(p_attachment)
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.attachment_version_stays_as_written()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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

	-- The counter of the sync and the chain of the log before the entry
	-- (opengewerk#914): a deletion holds both when it blacks out the entries of
	-- what it deletes, and a redaction that held the entry first and then
	-- waited for them, to log itself, would wait in a circle with it.
	PERFORM public.lock_sync_counter(new.tenant_id);
	PERFORM public.lock_audit_chain(new.tenant_id);

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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT CASE WHEN value IS NULL OR nonce IS NULL THEN NULL
		ELSE encode(sha256(decode(nonce, 'hex') || convert_to(value, 'UTF8')), 'hex') END
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_value_digest(value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT CASE WHEN value IS NULL THEN NULL ELSE encode(sha256(convert_to(value, 'UTF8')), 'hex') END
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.audit_witness(entry audit_entries)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
 SET "TimeZone" TO 'UTC'
AS $function$
	SELECT encode(sha256(convert_to((to_jsonb(entry) - 'hash' - 'old_value' - 'new_value')::text, 'UTF8')), 'hex')
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.create_first_tenant(company text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT id FROM public.tenants ORDER BY id
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.file_goes_with_its_document()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT DISTINCT f.sha256 FROM public.files f WHERE f.sha256 = ANY (candidates)
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.instance_change_stays()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
	SELECT NOT EXISTS (SELECT 1 FROM public.tenants)
	   AND NOT EXISTS (SELECT 1 FROM public.auth_users)
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.invitation_for(hash text)
 RETURNS TABLE(invitation_id uuid, business uuid, company text, invited_email text, invited_name text, invited_roles text[], expires timestamp with time zone, redeemed timestamp with time zone, revoked timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
BEGIN
	RETURN public.take_sync_numbers(tenant, 1::bigint);
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.purge_attachment(p_attachment uuid, p_title text)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
DECLARE
	before_row jsonb := '{}'::jsonb;
	after_row jsonb := '{}'::jsonb;
	present jsonb;
	chain record;
	head record;
	entry public.audit_entries;
	wrote boolean := false;
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

	-- The counter of the sync before the chain (opengewerk#914): a change of a
	-- row that travels has locked the counter already (`stamp_sync_columns`),
	-- and every other logged change takes it here as well, so that all of them
	-- take the two in one order and no two transactions of a tenant wait for
	-- each other in a circle. Locked without being moved; a row created here
	-- has handed out no number yet, so that the first is still 1.
	PERFORM public.lock_sync_counter(entry.tenant_id);

	-- The first change of the transaction starts at the head of the row and
	-- opens the chain; every further one starts after its own last entry, and
	-- the head reaches the row before the commit (`close_audit_chain`,
	-- opengewerk#953).
	chain := public.lock_audit_chain(entry.tenant_id);
	place := chain.next_sequence;
	previous := chain.head_hash;

	IF chain.opened_in = pg_current_xact_id() THEN
		head := public.audit_chain_head(entry.tenant_id, chain.next_sequence, chain.head_hash);
		place := head.place;
		previous := head.previous;
	END IF;

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
		wrote := true;
	END LOOP;

	IF wrote THEN
		PERFORM public.keep_counter_hint('audit_head', entry.tenant_id, entry.id::text);
	ELSIF chain.opened_in IS DISTINCT FROM pg_current_xact_id() THEN
		PERFORM public.keep_counter_hint('audit_head', entry.tenant_id, 'opened');
	END IF;

	-- Opened after the entries and after the hint: whoever has the trigger
	-- fire at once (`SET CONSTRAINTS ... IMMEDIATE`) has it write the head
	-- with them, not before them.
	IF chain.opened_in IS DISTINCT FROM pg_current_xact_id() THEN
		UPDATE public.audit_chains SET opened_in = pg_current_xact_id(), updated_at = now()
		 WHERE ctid = chain.address AND tenant_id = entry.tenant_id
		RETURNING ctid INTO chain.address;

		PERFORM public.keep_counter_hint('audit', entry.tenant_id, chain.address::text);
	END IF;

	RETURN NULL;
END;
$function$;--> statement-breakpoint
CREATE OR REPLACE FUNCTION public.record_instance_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
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
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
DECLARE
	hash text;
BEGIN
	IF coalesce(current_setting('app.purging_attachment', true), '') <> old.attachment_id::text THEN
		RETURN NULL;
	END IF;

	FOREACH hash IN ARRAY ARRAY[old.sha256, old.preview_sha256] LOOP
		CONTINUE WHEN hash IS NULL;
		CONTINUE WHEN public.file_named_by_a_value(old.tenant_id, hash);

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
CREATE CONSTRAINT TRIGGER audit_chain_closes AFTER UPDATE ON public.audit_chains DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.opened_in IS NOT NULL) AND (new.opened_in IS DISTINCT FROM old.opened_in))) EXECUTE FUNCTION close_audit_chain();--> statement-breakpoint
CREATE TRIGGER auth_sessions_fit_their_credentials BEFORE INSERT OR UPDATE OF credential_generation ON public.auth_sessions FOR EACH ROW EXECUTE FUNCTION session_fits_its_credentials();--> statement-breakpoint
CREATE CONSTRAINT TRIGGER sync_counter_closes AFTER UPDATE ON public.sync_sequences DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.opened_in IS NOT NULL) AND (new.opened_in IS DISTINCT FROM old.opened_in))) EXECUTE FUNCTION close_sync_counter();--> statement-breakpoint
REVOKE ALL ON FUNCTION public.audit_redaction_applied() FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.audit_redaction_checked() FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.close_audit_chain() FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.close_sync_counter() FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.file_named_by_a_value(uuid,text) FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.file_naming_lock(uuid) FROM PUBLIC;--> statement-breakpoint
GRANT EXECUTE ON FUNCTION public.file_naming_lock(uuid) TO opengewerk_app;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.record_change() FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.record_instance_change() FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.take_sync_numbers(uuid,bigint) FROM PUBLIC;--> statement-breakpoint
REVOKE ALL ON FUNCTION public.version_takes_its_files() FROM PUBLIC;--> statement-breakpoint
REVOKE CREATE ON SCHEMA "public" FROM PUBLIC;--> statement-breakpoint
REVOKE EXECUTE ON FUNCTION public.print_takes_its_file() FROM PUBLIC;--> statement-breakpoint
ALTER FUNCTION public.activity_duty_not_at_a_collective() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_emptying_confirmed() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_emptying_empties() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_emptying_of(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_ended_day(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_ended_on() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_kept_once_emptied() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_of_row(jsonb) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_of_service_report(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_of_work_order(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_reopened() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_reopening_of(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_reopening_removes() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.activity_retention_ends(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.answers_about_the_assets_of_their_point() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.answers_kept_once_signed() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.answers_more_photos_at_their_activity() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.application_attachment_may_go(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.area_from_the_property() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.asset_duplicate_candidates(text[],text[]) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.asset_hangs_not_under_itself() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.asset_stays_on_its_property() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.assets_with_evidence_stay() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.board_buildings_of(uuid,uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.boards_follow_their_installation() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.boards_in_a_building_of_their_installation() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.boards_on_a_low_voltage_installation() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.booking_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.briefing_names_its_page() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.building_on_a_property_in_reach() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.certificate_of_an_emptying(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.contact_to_confirm(text) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_emptying_confirmed() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_emptying_empties() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_emptying_of(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_kept_once_emptied() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_remedied_day(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_remedied_on() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.defect_retention_ends(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.delegation_kept_as_signed() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.delegation_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.each_once(anyarray) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.empty_the_activity(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.emptying_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.evidence_emptying_confirmed() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.evidence_emptying_empties() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.evidence_emptying_of(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.evidence_retention_ends(uuid) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.evidence_stays_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.grant_default_areas(uuid,text) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.import_record() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.import_writing() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.inverters_on_a_photovoltaic_installation() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.keep_label_given() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.label_open_to_reports(text) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.label_state_in_tenant(text) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_activities_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_assets_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_below_a_contract() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_below_a_contractor() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_closures_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_contacts_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_documents_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_duties_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_labels_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_places_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_plans_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_structure_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.mark_tasks_below() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.material_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.membership_gets_default_areas() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.note_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.outside_take(text[],text[],integer[],text[],timestamp with time zone) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.own_kind_uses() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.part_of_a_collective() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.person_in_sight(text) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.print_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.print_takes_its_file() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.reading_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.record_emptying_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.record_retention_ended(text,date) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.record_retention_ends(text,date) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.record_retention_years(text) SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.record_task_author() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.refuses_an_emptied_activity() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.removed_only_with_its_activity() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.round_record_once_per_opening() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.service_report_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_areas() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_is_the_deadline_run() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_leads() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_limit_asset_kinds() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_limit_properties() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_sees_all_areas() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.session_works_here() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.signed_print_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.task_done_on() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.task_goes_after_retention() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.tenant_role_leads_alone() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.visit_kept_as_written() SET search_path = pg_catalog, public, pg_temp;--> statement-breakpoint
ALTER FUNCTION public.voiding_kept_as_written() SET search_path = pg_catalog, public, pg_temp;
