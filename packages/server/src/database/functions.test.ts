import type { Pool } from 'pg'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'

import { connect, resetToMigrated } from './test-database.js'

// The functions of this database, the foundation's and this application's
// own (opengewerk#975, migration 0117). A function that runs as the owner of
// the tables and is open to every role can be hung on a temporary table of
// the application role and run there with the owner's rights; one that leaves
// the temporary schema out of its search path, or puts it anywhere but last,
// takes a type or a table another role made there in its session.

let admin: Pool

beforeAll(async () => {
  await resetToMigrated()
  admin = await connect()
})

afterAll(async () => {
  await admin.end()
})

/** The functions of the schema, without those of an extension. */
const ownFunctions = `
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and not exists (select 1 from pg_depend d
                    where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')`

describe('the functions of this database', () => {
  it('set a search path that searches the temporary schema last', async () => {
    const { rows } = await admin.query<{ signature: string; path: string | null }>(
      `select p.oid::regprocedure::text as signature,
              (select s from unnest(p.proconfig) s where s like 'search_path=%') as path
       ${ownFunctions}`,
    )

    expect(rows.length).toBeGreaterThan(100)
    expect(rows.filter((row) => !row.path?.endsWith('pg_temp'))).toEqual([])
  })

  it('that run as the owner are open to no role that asks for them by itself', async () => {
    // No list of rights means the default, which lets every role execute.
    const { rows } = await admin.query<{ signature: string }>(
      `select p.oid::regprocedure::text as signature
       ${ownFunctions}
         and p.prosecdef
         and (p.proacl is null
              or exists (select 1 from aclexplode(p.proacl) a
                          where a.grantee = 0 and a.privilege_type = 'EXECUTE'))
       order by 1`,
    )

    expect(rows).toEqual([])
  })
})
