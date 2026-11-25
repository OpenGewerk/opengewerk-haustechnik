import { describe, expect, it } from 'vitest'

import { limitAtHead, limitBound } from './form-points.js'

describe('the limit at the head of a measured value (#350)', () => {
  const ohms = { unit: 'ohms', decimals: 2 } as const

  it('stands as exactly as the sentence under it says it (opengewerk/opengewerk#1089)', () => {
    // Zs of a B 16 A breaker: 230 V over 80 A is 2,875 Ω, in a field of two places.
    expect(limitAtHead(ohms, 'at_most', 2875)).toBe('≤ 2,875 Ω')
    expect(limitAtHead({ unit: 'milliseconds', decimals: 0 }, 'at_most', 300_000)).toBe('≤ 300 ms')
  })

  it('says a range without a sign, from its least value inside, or above a value the field shows (opengewerk/opengewerk#1021)', () => {
    const milliseconds = { unit: 'milliseconds', decimals: 0 } as const
    const milliamperes = { unit: 'milliamperes', decimals: 1 } as const

    expect(limitAtHead(milliseconds, 'at_most', 500_000, 130_000)).toBe('130 bis 500 ms')
    expect(limitAtHead(milliamperes, 'at_most', 30_000, 15_001)).toBe('über 15,0 bis 30,0 mA')
  })

  it('takes the bound of a limit worked out of the circuit from the catalogue: the insulation is one a value has to reach (opengewerk/opengewerk#1021)', () => {
    expect(limitBound({ kind: 'circuit_insulation' })).toBe('at_least')
    expect(limitBound({ kind: 'rcd_trip_time' })).toBe('at_most')
    expect(limitBound({ kind: 'loop_impedance' })).toBe('at_most')
    expect(limitBound({ kind: 'at_least', rule: 'elektro.insulation_minimum_up_to_500v' })).toBe(
      'at_least',
    )
    expect(limitAtHead({ unit: 'megaohms', decimals: 2 }, 'at_least', 500)).toBe('≥ 0,50 MΩ')
  })
})
