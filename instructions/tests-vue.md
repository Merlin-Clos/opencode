---
---

# Vue Test Instructions

Apply these rules when the test exercises Vue behavior.

## Test Level

- Test an independent composable without mounting a component.
- Give a lifecycle-dependent composable the smallest Vue host that provides its
  required context.
- Test a component through user-visible behavior, emitted events, and public state.
  Do not assert its internal helper calls or exact structure unless they form part
  of the contract.
- Do not replace a useful composable or component test with a broad mounted test
  that makes failures harder to locate.

## Async Vue Behavior

- Await the user action and the Vue update it triggers.
- Do not use arbitrary delays to wait for Vue or a promise.
- Control pending promises when testing overlap, ordering, cancellation, or stale
  responses.
- Verify both the visible result and the owned reactive state after success or
  failure when both form part of the contract.
- For Vue forms, cover relevant valid input, invalid input, boundary values,
  submission, server failure, and duplicate-submission behavior.
