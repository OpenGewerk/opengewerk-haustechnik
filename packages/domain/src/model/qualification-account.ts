import { qualificationProblems as problemsOfAPersonsQualification } from '@opengewerk/platform-domain'

/**
 * What is wrong with a qualification of this application, by field. Since its
 * version 0.7.0 the foundation asks for a person of `peopleSchema` (ADR 0016 in
 * the repository opengewerk); here a qualification still hangs on an account
 * (#618), so the account stands in for the person, and what is wrong with it
 * is said at `userId`, where the form of the office shows it.
 */
export function qualificationProblems(
  qualification: Readonly<Record<string, unknown>>,
): Readonly<Record<string, string>> {
  const { personId, ...others } = problemsOfAPersonsQualification({
    ...qualification,
    personId: qualification['userId'],
  })

  return personId === undefined ? others : { ...others, userId: personId }
}
