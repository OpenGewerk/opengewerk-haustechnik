import { personLevels, qualificationLimits } from '@opengewerk/haustechnik-domain'
import {
  applicationRole,
  primaryId,
  reference,
  syncColumns,
  tenantIsolation,
  timestamps,
} from '@opengewerk/platform-server'
import { files, memberships, tenantColumn } from '@opengewerk/platform-server/schema'
import { sql } from 'drizzle-orm'
import {
  check,
  date,
  foreignKey,
  index,
  pgPolicy,
  pgTable,
  text,
  unique,
  uniqueIndex,
} from 'drizzle-orm/pg-core'

/**
 * The qualifications of the people who work for the operator (#337, section
 * 4.3 of the concept): the kinds the operator adds to those of the packages,
 * and what each person holds, until a day or without one, with the
 * certificate as a file of the store. Tenant-wide and without an area; a
 * device holds the qualifications of its own person and no others.
 *
 * Made like the factory of the foundation made them up to its version 0.6.5
 * (ADR 0012 in the repository opengewerk). Since 0.7.0 the factory hangs a
 * qualification on a person of `peopleSchema` instead of an account
 * (ADR 0016 there), and this application has no people without an account.
 * Until it takes the people over, the tables stay what its migrations made,
 * on the account.
 */

/** A text from one character up to the bound. */
const fits = (column: unknown, most: number) =>
  sql`char_length(${column}) between 1 and ${sql.raw(String(most))}`

/** One of the words of a list, as a check of the database. */
const oneOf = (column: unknown, words: readonly string[]) =>
  sql`${column} in (${sql.raw(words.map((word) => `'${word}'`).join(', '))})`

export const qualificationKinds = pgTable(
  'qualification_kinds',
  {
    id: primaryId<'qualification-kind'>(),
    ...tenantColumn,
    label: text('label').notNull(),
    level: text('level').notNull(),
    ...timestamps,
    ...syncColumns,
  },
  (table) => [
    tenantIsolation(table.tenantId),
    unique('qualification_kinds_tenant_id_key').on(table.tenantId, table.id),
    // A label once per tenant, however it is written, among those not taken out.
    uniqueIndex('qualification_kinds_label_once')
      .on(table.tenantId, sql`lower(${table.label})`)
      .where(sql`${table.deletedAt} is null`),
    check('qualification_kinds_label_fits', fits(table.label, qualificationLimits.kindLabel)),
    check('qualification_kinds_level_known', oneOf(table.level, personLevels)),
  ],
)

export const qualifications = pgTable(
  'qualifications',
  {
    id: primaryId<'qualification'>(),
    ...tenantColumn,
    userId: text('user_id').notNull(),
    kindKey: text('kind_key'),
    ownKindId: reference<'qualification-kind'>('own_kind_id'),
    validUntil: date('valid_until', { mode: 'string' }),
    note: text('note'),
    certificateSha256: text('certificate_sha256'),
    ...timestamps,
    ...syncColumns,
  },
  (table) => [
    tenantIsolation(table.tenantId),
    unique('qualifications_tenant_id_key').on(table.tenantId, table.id),
    index('qualifications_of_a_person').on(table.tenantId, table.userId),
    foreignKey({
      columns: [table.tenantId, table.userId],
      foreignColumns: [memberships.tenantId, memberships.userId],
      name: 'qualifications_of_somebody_here',
    }),
    foreignKey({
      columns: [table.tenantId, table.ownKindId],
      foreignColumns: [qualificationKinds.tenantId, qualificationKinds.id],
      name: 'qualifications_of_an_own_kind',
    }),
    foreignKey({
      columns: [table.tenantId, table.certificateSha256],
      foreignColumns: [files.tenantId, files.sha256],
      name: 'qualifications_certificate_stored',
    }),
    // Exactly one kind: of a catalogue, or of the tenant's own.
    check('qualifications_one_kind', sql`num_nonnulls(${table.kindKey}, ${table.ownKindId}) = 1`),
    check(
      'qualifications_kind_key_fits',
      sql`${table.kindKey} is null or ${fits(table.kindKey, qualificationLimits.kindKey)}`,
    ),
    check(
      'qualifications_note_fits',
      sql`${table.note} is null or ${fits(table.note, qualificationLimits.note)}`,
    ),
    check(
      'qualifications_certificate_is_a_hash',
      sql`${table.certificateSha256} is null or ${table.certificateSha256} ~ '^[0-9a-f]{64}$'`,
    ),
  ],
)

/**
 * Whose qualifications a person sees (section 7 of the concept: a right
 * holds in the areas of the person): their own, those of whoever works in an
 * area they see, and all of them for whoever sees every area and for the
 * runs. A qualification has no area of its own, so the areas of the person
 * it is of decide (`person_in_sight`); the database holds it for reading and
 * writing alike.
 */
export const qualificationsOfPeopleInSight = pgPolicy('of_people_in_sight', {
  as: 'restrictive',
  for: 'all',
  to: applicationRole,
  using: sql`public.person_in_sight(${qualifications.userId})`,
  withCheck: sql`public.person_in_sight(${qualifications.userId})`,
}).link(qualifications)
