import { describe, expect, it } from 'vitest'

import { circuitTablesOf, onACircuit, symbolOf } from './circuit-table.js'
import type { StatedAnswer, StatedCircuit } from './evidence.js'

/**
 * The measurements of a group over the circuits as a table (#350), as the
 * office and the PDF of an evidence show them, from the frozen state alone.
 */

const group = { label: 'Messen je Stromkreis', block: 1 }

function measured(
  circuit: string,
  label: string,
  value: string | null,
  limit: StatedAnswer['limit'] = null,
  more: Partial<StatedAnswer> = {},
): StatedAnswer {
  return {
    section: 'Messen',
    label,
    group,
    kind: 'measurement',
    value,
    result: null,
    remark: null,
    limit,
    photo: null,
    circuit,
    ...more,
  }
}

const circuits: readonly StatedCircuit[] = [
  {
    id: 'c-uv-f1',
    board: 'UV Werkstatt',
    boardKind: 'sub_distribution',
    designation: 'F1',
    consumer: 'Beleuchtung Werkstatt',
    protection: 'B 10 A, RCD 30 mA',
    place: 2,
  },
  {
    id: 'c-q1',
    board: 'HV Halle 1',
    boardKind: 'main_distribution',
    designation: 'Q1',
    consumer: 'Zuleitung UV Werkstatt',
    protection: 'gG 63 A',
    place: 0,
  },
  {
    id: 'c-f2',
    board: 'HV Halle 1',
    boardKind: 'main_distribution',
    designation: 'F2',
    consumer: 'Steckdosen Nordwand',
    protection: 'B 16 A, RCD 30 mA',
    place: 1,
  },
]

const zsSource = 'DIN VDE 0100-410; DIN EN 60898-1'

const answers: readonly StatedAnswer[] = [
  {
    section: 'Besichtigen',
    label: 'Basisschutz',
    group: null,
    kind: 'check_point',
    value: null,
    result: 'ok',
    remark: null,
    limit: null,
    photo: null,
  },
  measured('c-q1', 'Durchgängigkeit des Schutzleiters RPE', '0,08 Ω'),
  measured('c-q1', 'Schleifenimpedanz Zs', '0,18 Ω', null, { workedOut: 'loop_impedance' }),
  measured('c-f2', 'Durchgängigkeit des Schutzleiters RPE', '0,31 Ω'),
  measured(
    'c-f2',
    'Schleifenimpedanz Zs',
    '3,40 Ω',
    {
      text: 'Außerhalb des Grenzwerts, höchstens 2,87 Ω.',
      source: zsSource,
      within: false,
      bound: 'höchstens 2,87 Ω',
    },
    { workedOut: 'loop_impedance', remark: 'Zweimal gemessen.' },
  ),
  measured('c-f2', 'Isolationswiderstand Riso', '350,00 MΩ', {
    text: 'Innerhalb des Grenzwerts, mindestens 1,00 MΩ.',
    source: 'DIN VDE 0100-600',
    within: true,
    bound: 'mindestens 1,00 MΩ',
  }),
  {
    ...measured('c-f2', 'Stromkreis in Ordnung', null),
    kind: 'check_point',
    result: 'not_ok',
    remark: 'Klemme lose',
  },
  { ...measured('c-f2', 'Bemerkung', 'Abzweigdose prüfen.'), kind: 'text' },
]

describe('the table of the measurements on circuits (#350)', () => {
  it('leaves out every answer outside the block of a circuit of the state', () => {
    expect(answers.filter((answer) => onACircuit(answer, circuits))).toHaveLength(7)
    expect(onACircuit(measured('c-gone', 'Schleifenimpedanz Zs', '1,00 Ω'), circuits)).toBe(false)
  })

  it('names a column by the symbol its label ends with', () => {
    expect(symbolOf('Durchgängigkeit des Schutzleiters RPE')).toBe('RPE')
  })

  it('has a column for each measured value, and the limit beside the loop impedance', () => {
    const [table] = circuitTablesOf(answers, circuits)

    expect(table?.group).toBe('Messen je Stromkreis')
    expect(table?.columns.map((column) => [column.symbol, column.unit, column.withLimit])).toEqual([
      ['RPE', 'Ω', false],
      ['Zs', 'Ω', true],
      ['Riso', 'MΩ', false],
    ])
  })

  it('lists every circuit board by board in the order of the chart, also one without an answer', () => {
    const [table] = circuitTablesOf(answers, circuits)

    expect(
      table?.boards.map((board) => [
        board.board,
        board.boardKind,
        board.rows.map((row) => row.circuit.designation),
      ]),
    ).toEqual([
      ['HV Halle 1', 'main_distribution', ['Q1', 'F2']],
      ['UV Werkstatt', 'sub_distribution', ['F1']],
    ])
    expect(table?.boards[1]?.rows[0]?.values).toEqual([
      { figure: '', outside: false },
      { figure: '', outside: false, limit: 'keiner' },
      { figure: '', outside: false },
    ])
  })

  it('marks a value outside its limit and gives the limit worked out of the circuit, or none', () => {
    const [table] = circuitTablesOf(answers, circuits)
    const [q1, f2] = table?.boards[0]?.rows ?? []

    expect(q1?.values[1]).toEqual({ figure: '0,18', outside: false, limit: 'keiner' })
    expect(f2?.values[1]).toEqual({ figure: '3,40', outside: true, limit: '≤ 2,87' })
    expect(f2?.values[2]).toEqual({ figure: '350,00', outside: false })
    expect(table?.anyOutside).toBe(true)
  })

  it('says under "Bemerkung" the remark at a value, a check point not in order and the texts', () => {
    const [table] = circuitTablesOf(answers, circuits)

    expect(table?.boards[0]?.rows[1]?.remarks).toBe(
      'Zs: Zweimal gemessen. Stromkreis in Ordnung: nicht in Ordnung, Klemme lose Abzweigdose prüfen.',
    )
  })

  it('says where each limit comes from, the values without one, and where a circuit gave none', () => {
    const [table] = circuitTablesOf(answers, circuits)

    expect(table?.limits).toEqual([
      `Zs aus Charakteristik und Nennstrom (${zsSource})`,
      'Riso mindestens 1,00 MΩ (DIN VDE 0100-600)',
      'RPE ohne Grenzwert',
      'ohne Angaben zur Schutzeinrichtung keiner für Zs',
    ])
  })

  it('gives the limit of each circuit beside the insulation and the tripping time of a test in version 2 (opengewerk/opengewerk#1021)', () => {
    // F2 up to 500 V with an RCD without delay, F1 SELV with a selective RCD: the
    // same values, judged by different limits, which the table says beside them.
    const judged = (
      circuit: string,
      label: string,
      value: string,
      bound: string,
      within: boolean,
      workedOut: 'circuit_insulation' | 'rcd_trip_time',
    ) =>
      measured(
        circuit,
        label,
        value,
        {
          text: `${within ? 'Innerhalb' : 'Außerhalb'} des Grenzwerts, ${bound}.`,
          source: 'DIN VDE 0100-600',
          within,
          bound,
        },
        { workedOut },
      )
    const [table] = circuitTablesOf(
      [
        judged(
          'c-f2',
          'Isolationswiderstand Riso',
          '0,70 MΩ',
          'mindestens 1,00 MΩ',
          false,
          'circuit_insulation',
        ),
        judged(
          'c-uv-f1',
          'Isolationswiderstand Riso',
          '0,70 MΩ',
          'mindestens 0,50 MΩ',
          true,
          'circuit_insulation',
        ),
        judged('c-f2', 'Auslösezeit tA', '400 ms', 'höchstens 300 ms', false, 'rcd_trip_time'),
        judged(
          'c-uv-f1',
          'Auslösezeit tA',
          '400 ms',
          'zwischen 130 und 500 ms',
          true,
          'rcd_trip_time',
        ),
      ],
      circuits,
    )

    expect(table?.columns.map((column) => [column.symbol, column.withLimit])).toEqual([
      ['Riso', true],
      ['tA', true],
    ])
    expect(table?.boards[0]?.rows[1]?.values).toEqual([
      { figure: '0,70', outside: true, limit: '≥ 1,00' },
      { figure: '400', outside: true, limit: '≤ 300' },
    ])
    expect(table?.boards[1]?.rows[0]?.values).toEqual([
      { figure: '0,70', outside: false, limit: '≥ 0,50' },
      { figure: '400', outside: false, limit: '130 bis 500' },
    ])
  })

  it('has no table where no answer stands in the block of a circuit', () => {
    expect(circuitTablesOf(answers.slice(0, 1), circuits)).toEqual([])
  })
})
