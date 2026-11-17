import { describe, expect, it } from 'vitest'

import { qualificationProblems } from './qualification-account.js'

describe('the problems of a qualification on an account (#618)', () => {
  it('asks for the account where the foundation asks for a person, and says it there', () => {
    expect(qualificationProblems({ kindKey: 'electrician' })).toEqual({
      userId: 'Wählen Sie die Person.',
    })
    expect(qualificationProblems({ userId: 'anna', kindKey: 'electrician' })).toEqual({})
    expect(qualificationProblems({ userId: 'anna', personId: '', kindKey: 'electrician' })).toEqual(
      {},
    )
  })

  it('keeps every other problem of the foundation', () => {
    expect(qualificationProblems({ userId: 'anna' })).toEqual({
      kind: 'Wählen Sie die Art der Qualifikation.',
    })
  })
})
