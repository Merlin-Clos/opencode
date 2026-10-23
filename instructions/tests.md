---
---

# Test Instructions

## Purpose

- Test behavior and risk, not line counts.
- Link each test to a public contract, business rule, state transition, failure,
  boundary, or defect that matters.
- Prefer a small set of distinct cases over many cases that prove the same thing.
- Keep tests deterministic, isolated, readable, and able to fail for one clear
  reason.
- Do not add tests only to raise a coverage percentage.

## Test Level

- Test a pure rule or transform directly.
- Choose the smallest test level that clearly proves the behavior.
- Test code through its observable behavior and public contracts. Do not assert
  internal helper calls or exact structure unless they form part of the contract.
- Use an integration test when the risk lies at a real boundary between modules,
  such as a mapper, service, store, router, or validation resolver.
- Do not replace a useful lower-level test with a broad test that makes failures
  harder to locate.
- Use end-to-end tests for important user-visible workflows whose risks cross real
  application boundaries. Keep focused lower-level tests for rules and failures
  they prove more clearly; end-to-end tests complement rather than replace them.
- Make end-to-end verification repeatable with the exact command and stable inputs.
  Preserve a report, trace, screenshot, or similar artifact when repository tooling
  or acceptance criteria make it useful. Do not create bulky artifacts without a
  clear consumer.

## Black-Box Case Selection

- Use equivalence partitioning to group valid and invalid inputs that should behave
  alike. Test a representative from each relevant group instead of every value.
- For an isolated unit, identify its meaningful failure modes before selecting
  cases. Cover distinct reachable outcomes without trying to enumerate speculative
  or unbounded failure possibilities.
- Use boundary value analysis for ranges, sizes, limits, dates, ordering, and other
  edges. Test the boundary and the nearest meaningful value on each side.
- Use decision table testing when several conditions interact. Cover combinations
  that produce distinct results, including constrained or invalid combinations.
  Do not generate a full Cartesian product when cases are equivalent or impossible.
- Use state transition testing when behavior depends on current state or event
  order. Cover relevant success, failure, rejected transition, retry, and stale
  asynchronous response paths.

## White-Box Case Selection

- Use basis path testing for important branching logic. Identify independent paths
  that produce distinct outcomes and make sure each has a useful test.
- Use McCabe cyclomatic complexity to guide basis path testing, not as a test quota.
  For binary decisions, estimate complexity as decision points plus one.
- When deterministic complexity signals identify a hotspot, inspect whether
  independent behavior paths remain untested. Do not create a finding from a
  numeric threshold alone.
- Use branch and condition coverage as diagnostic signals for important logic.
  Missing coverage matters when it reveals an untested result or independent path.
- Do not require complete path coverage, systematic multiple-condition coverage,
  or a fixed repository-wide coverage target.
- Use loop testing only when loop control affects behavior. Consider zero, one,
  two, typical-many, and known limit cases as relevant.
- For ordinary `map`, `filter`, or similar collection operations, prefer
  equivalence classes and boundary values over mechanical iteration-count tests.

## Regression and Test-First Work

- For a reproducible defect, add a regression test that fails because of the
  original behavior and passes after the fix.
- Keep the regression test focused on the broken contract, not the implementation
  detail that caused it.
- For reproducible bugs, business rules, pure transforms, state transitions, and
  important branching behavior, write a test that fails for the intended reason
  before changing production code whenever the expected behavior can be stated and
  a useful test level is available.
- Do not implement first and add tests afterward merely to ratify the chosen
  implementation. When test-first is impractical or adds no value, state why and
  use another useful proof.
- Use the red-green-refactor cycle: write one meaningful failing test, make the
  smallest coherent change that passes, then improve the code while tests stay
  green.
- Do not force test-first work for trivial code or when the available test level
  cannot provide useful feedback.

## Mocks and Fixtures

- Mock the narrow external boundary, not the unit's internal collaborators by
  default.
- Prefer real pure functions, adapters, and lightweight in-memory values over broad
  module mocks.
- Do not assert call counts or call order unless they form part of the contract,
  such as preventing a duplicate mutation.
- Keep fixtures small and explicit. Include only data needed to explain the case.
- Use builders or factories only when they remove real setup noise across several
  tests. Do not hide the values that make a case distinct.
- Restore global state, timers, mocks, and listeners after each test.

## Asynchronous Behavior

- Await the action and the observable state change it triggers.
- Do not use arbitrary delays to wait for asynchronous work.
- Control pending promises when testing overlap, ordering, cancellation, or stale
  responses.
- Verify both the observable result and the owned state after success or failure
  when both form part of the contract.
- For forms, cover relevant valid input, invalid input, boundary values, submission,
  server failure, and duplicate-submission behavior.
- For state with exclusive variants, assert the allowed transitions and data for
  each status rather than separate implementation booleans.

## Test Quality Review

- A test must fail when the behavior it claims to protect breaks.
- Avoid snapshots for business rules or broad UI output when focused assertions
  state the contract more clearly.
- Do not copy implementation branches into the test as a second version of the
  production logic.
- Do not weaken an assertion, add an unrelated mock, or remove a case only to make
  a failing test pass.
- When a test fails after an intended contract change, update the test to the new
  contract and remove obsolete expectations. Do not preserve old behavior without
  a stated compatibility need.
- Treat coverage reports as evidence for finding gaps, not as proof of correctness.

## Volume and Signal

- Prefer the smallest suite with the strongest signal.
- Before adding a test, confirm it protects a distinct outcome, boundary, failure
  mode, or contract.
- Do not add duplicates or Cartesian products that prove the same thing twice.
- Prefer one clear test per distinct risk over many overlapping variants.

## Mutation Testing

- When the repository already configures a mutation testing tool (Stryker, PIT,
  mutmut, or equivalent), use its report as a diagnostic for assertion strength
  and case relevance.
- Ignore this section when no such tool is present or configured.
- Treat the mutation score as a signal, never as a quota.

## When to Delete or Reduce Tests

- Prefer a small high-signal suite over a large low-signal one. Strengthen or
  merge when the risk is still real; delete when it is not.
- Ask: "Has this test ever caught a real defect or does it guard a significant
  risk?" When clearly not and it costs maintenance, remove it.
- Consider deleting tests that:
  - only verify what the types already guarantee;
  - cover trivial logic, getters/setters, or basic DOM behavior;
  - depend on real or fake timers and assert timing rather than behavior;
  - only assert mock calls and mirror the implementation;
  - are low-value smoke tests;
  - duplicate another table case;
  - assert wall-clock performance;
  - are flaky and cannot be made reliable quickly;
  - guard only an implementation detail outside the public contract;
  - protect exactly the same outcome as a clearer test.
- Keep in priority tests that cover:
  - orchestration and event sourcing;
  - auth and permissions;
  - persistence and migrations;
  - external format parsing;
  - business guards and invariants;
  - deterministic race fixes;
  - critical paths and real boundaries.
- On timers: prefer deterministic synchronization (await the observable state
  change) over sleeps, timeouts, or wall-clock asserts. Keep a timer-based test
  only when timing is the contract and it is stable; otherwise replace it or
  delete it.
