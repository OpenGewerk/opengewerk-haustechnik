import { checkPointResultLabel, type DistributionBoardKind } from '@opengewerk/platform-domain'

import { type StatedAnswer, type StatedCircuit, workedOutLimitWords } from './evidence.js'
import type { WorkedOutLimitKind } from './forms.js'

/**
 * The measurements of a group over the circuits as a table (#350), the same
 * in the office and in the PDF of an evidence: the circuits board by board in
 * the order of the chart, a column for each measured value of the form, the
 * limit worked out of each circuit where it differs from circuit to circuit
 * (`withLimit`), what else the block said, and under it where each limit comes
 * from. Read from the frozen state alone.
 */

/** A column of the table: a measured value of the group, by the label of its field. */
export interface CircuitColumn {
  readonly label: string
  /** The symbol the label ends with, as the head of a column names it: `RPE`, `Zs`. */
  readonly symbol: string
  /** The sign of its unit, as the values were said: `Ω`. */
  readonly unit: string
  /** How a limit worked out of the circuit comes about, where it is. */
  readonly workedOut?: WorkedOutLimitKind
  /**
   * Whether the limit worked out of each circuit stands in a column beside
   * it: the loop impedance, whose limit differs from circuit to circuit, and
   * since version 2 of both tests of the installation the insulation and the
   * tripping time, by the nominal voltage and the kind of RCD
   * (opengewerk/opengewerk#1021). The tripping current needs none, the RCD in
   * the words of the circuit names it.
   */
  readonly withLimit: boolean
}

/** A value in the table: its figure without the unit, empty where none was given. */
export interface CircuitValue {
  readonly figure: string
  /** Whether it is outside its limit, which made a defect of it. */
  readonly outside: boolean
  /**
   * The limit worked out of the circuit in short words, `≤ 2,875` or
   * `130 bis 500`, or `keiner`, in a column with its limit beside it; none in every other.
   */
  readonly limit?: string
}

/** A circuit with its values, one for each column, and what else its block said. */
export interface CircuitRow {
  readonly circuit: StatedCircuit
  readonly values: readonly CircuitValue[]
  readonly remarks: string
}

/** The circuits of one board, in the order of the chart. */
export interface CircuitBoardRows {
  readonly board: string
  readonly boardKind: DistributionBoardKind
  readonly rows: readonly CircuitRow[]
}

/** The table of one group over the circuits. */
export interface CircuitTable {
  /** The label of the group: "Messen je Stromkreis". */
  readonly group: string
  readonly columns: readonly CircuitColumn[]
  readonly boards: readonly CircuitBoardRows[]
  /**
   * Where each limit comes from, one phrase a column, with its sources: the
   * limit itself or how it is worked out, the values without a limit, and
   * the values a circuit without what they are worked out from has none for.
   */
  readonly limits: readonly string[]
  /** Whether a value of the table is outside its limit. */
  readonly anyOutside: boolean
}

/** Whether an answer stands in the block of one of the circuits given, under its group. */
export function onACircuit(answer: StatedAnswer, circuits: readonly StatedCircuit[]): boolean {
  return (
    answer.circuit !== undefined &&
    answer.group !== null &&
    circuits.some((circuit) => circuit.id === answer.circuit)
  )
}

/**
 * The symbol a label ends with, `RPE` of "Durchgängigkeit des Schutzleiters
 * RPE", as a table of measurements names a column. A label that goes on
 * after its symbol with "ohne" or "mit" keeps that part, so that the two ways
 * of measuring the insulation of the recurring test stay apart (#630):
 * "Riso ohne Verbraucher", as OpenGewerk heads its columns.
 */
export function symbolOf(label: string): string {
  const words = label.trim().split(/\s+/)
  const how = words.findIndex((word, at) => at > 1 && (word === 'ohne' || word === 'mit'))

  return how > 0 ? words.slice(how - 1).join(' ') : (words.at(-1) ?? label)
}

/** A measured value in words, split into its figure and its unit: "0,42 Ω". */
function figureAndUnit(value: string | null): { figure: string; unit: string } {
  const at = value?.lastIndexOf(' ') ?? -1

  return value === null || at < 0
    ? { figure: value ?? '', unit: '' }
    : { figure: value.slice(0, at), unit: value.slice(at + 1) }
}

/**
 * A limit in the short words of a table, without its unit, which the head of
 * the column names: "höchstens 2,875 Ω" as "≤ 2,875", and the range of a
 * selective RCD, "zwischen 130 und 500 ms", as "130 bis 500".
 */
function shortBound(bound: string): string {
  const range = /^zwischen (\S+) und (\S+) \S+$/.exec(bound)

  if (range !== null) {
    return `${range[1] ?? ''} bis ${range[2] ?? ''}`
  }

  const signs: Readonly<Record<string, string>> = {
    höchstens: '≤',
    mindestens: '≥',
    unter: '<',
  }
  const [word = '', ...rest] = bound.split(' ')
  const sign = signs[word]
  const figure = rest.length > 1 ? rest.slice(0, -1).join(' ') : rest.join(' ')

  return sign === undefined ? bound : `${sign} ${figure}`
}

/**
 * What else a block says beside its values: its texts, a check point not in
 * order with its remark, and the remark at a value, named by its symbol.
 */
function remarksOf(said: readonly StatedAnswer[]): string {
  return said
    .flatMap((answer) => {
      if (answer.kind === 'measurement') {
        return answer.remark === null || answer.remark.trim() === ''
          ? []
          : [`${symbolOf(answer.label)}: ${answer.remark}`]
      }

      if (answer.kind === 'check_point') {
        return answer.result === 'ok' || answer.result === null
          ? []
          : [
              [`${answer.label}: ${checkPointResultLabel[answer.result]}`, answer.remark]
                .filter(Boolean)
                .join(', '),
            ]
      }

      if (answer.kind === 'text') {
        return answer.value === null ? [] : [answer.value]
      }

      return answer.value === null ? [] : [`${answer.label}: ${answer.value}`]
    })
    .join(' ')
}

/**
 * Why a limit worked out of the circuit can be missing in a row, as far as
 * the frozen state tells: for the insulation of the recurring test a circuit
 * above 500 V (#630), whose nominal voltage the chart does not name, else
 * what protects the circuit, and either way a day before its rules began,
 * which the state does not keep apart from the first.
 */
function missingBecause(kind: WorkedOutLimitKind): string {
  const first =
    kind === 'recurring_insulation_without_loads' || kind === 'recurring_insulation_with_loads'
      ? 'über 500 V'
      : 'ohne Angaben zur Schutzeinrichtung'

  return `${first} oder ohne Regel am Tag der Prüfung`
}

/** Where the limit of each column comes from, with its sources (`CircuitTable.limits`). */
function limitsOf(answers: readonly StatedAnswer[], columns: readonly CircuitColumn[]): string[] {
  const limited: string[] = []
  const unlimited: string[] = []
  const without = new Map<string, string[]>()

  for (const column of columns) {
    const ofColumn = answers.filter((answer) => answer.label === column.label)
    const sources = [
      ...new Set(
        ofColumn.flatMap((answer) =>
          (answer.limit?.source ?? '').split('; ').filter((source) => source !== ''),
        ),
      ),
    ].join('; ')
    const bound = ofColumn.find((answer) => answer.limit?.bound !== undefined)?.limit?.bound
    const from = sources === '' ? '' : ` (${sources})`

    if (column.workedOut !== undefined) {
      limited.push(`${column.symbol} ${workedOutLimitWords[column.workedOut]}${from}`)

      if (ofColumn.some((answer) => answer.limit === null)) {
        const because = missingBecause(column.workedOut)

        without.set(because, [...(without.get(because) ?? []), column.symbol])
      }
    } else if (bound !== undefined) {
      limited.push(`${column.symbol} ${bound}${from}`)
    } else {
      unlimited.push(column.symbol)
    }
  }

  return [
    ...limited,
    ...(unlimited.length === 0 ? [] : [`${unlimited.join(' und ')} ohne Grenzwert`]),
    ...[...without].map(([because, symbols]) => `${because} keiner für ${symbols.join(' und ')}`),
  ]
}

/** The limits worked out of the circuit that differ from circuit to circuit (`CircuitColumn.withLimit`). */
const limitPerCircuit: ReadonlySet<WorkedOutLimitKind> = new Set([
  'loop_impedance',
  'circuit_insulation',
  'recurring_insulation_without_loads',
  'recurring_insulation_with_loads',
  'rcd_trip_time',
])

/** The table of the answers of one group over the circuits. */
function tableOf(
  group: string,
  answers: readonly StatedAnswer[],
  circuits: readonly StatedCircuit[],
): CircuitTable {
  const columns: CircuitColumn[] = []

  for (const answer of answers) {
    if (answer.kind === 'measurement' && !columns.some((column) => column.label === answer.label)) {
      columns.push({
        label: answer.label,
        symbol: symbolOf(answer.label),
        unit: figureAndUnit(answer.value).unit,
        ...(answer.workedOut === undefined ? {} : { workedOut: answer.workedOut }),
        withLimit: answer.workedOut !== undefined && limitPerCircuit.has(answer.workedOut),
      })
    }
  }

  const boards: CircuitBoardRows[] = []

  for (const circuit of [...circuits].sort((left, right) => left.place - right.place)) {
    const said = answers.filter((answer) => answer.circuit === circuit.id)
    const values = columns.map((column): CircuitValue => {
      const answer = said.find((each) => each.label === column.label)
      const value = {
        figure: figureAndUnit(answer?.value ?? null).figure,
        outside: answer?.limit?.within === false,
      }

      if (!column.withLimit) {
        return value
      }

      const bound = answer?.limit?.bound

      return { ...value, limit: bound === undefined ? 'keiner' : shortBound(bound) }
    })
    const row = { circuit, values, remarks: remarksOf(said) }
    const last = boards.at(-1)

    if (last !== undefined && last.board === circuit.board) {
      boards[boards.length - 1] = { ...last, rows: [...last.rows, row] }
    } else {
      boards.push({ board: circuit.board, boardKind: circuit.boardKind, rows: [row] })
    }
  }

  return {
    group,
    columns,
    boards,
    limits: limitsOf(answers, columns),
    anyOutside: answers.some(
      (answer) => answer.kind === 'measurement' && answer.limit?.within === false,
    ),
  }
}

/**
 * The tables of the answers given that stand in the block of a circuit, one
 * for each group over the circuits in the order the answers name them. Every
 * circuit of the state stands in each, also one without an answer.
 */
export function circuitTablesOf(
  answers: readonly StatedAnswer[],
  circuits: readonly StatedCircuit[],
): readonly CircuitTable[] {
  const groups = new Map<string, StatedAnswer[]>()

  for (const answer of answers.filter((each) => onACircuit(each, circuits))) {
    const label = answer.group?.label ?? ''

    groups.set(label, [...(groups.get(label) ?? []), answer])
  }

  return [...groups.entries()].map(([group, said]) => tableOf(group, said, circuits))
}
