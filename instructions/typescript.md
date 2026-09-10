---
---

# TypeScript Instructions

## Type Flow

- Preserve precise type information from input to output.
- Prefer inference when it keeps the exact type. Add an explicit type when it
  documents a boundary, prevents widening, or makes a contract clearer.
- Use `import type` for type-only imports.
- Use `satisfies` to check a shape without widening the value.
- Use `unknown`, not `any`, for data whose shape is not yet trusted. Narrow or
  validate it where it enters the application.
- Do not widen a known value to `unknown`, `object`, or `Record<string, unknown>`
  and cast it back later.
- Do not use `any`, chained assertions, `as unknown as T`, or assertion-heavy
  mapping code to connect incompatible layers.
- Prefer discriminated unions when each state allows different data. Do not model
  exclusive states with several booleans that can contradict each other.
- Do not make fields optional or nullable only to silence a type error. Model the
  real states and invariants.
- Use generics only when callers retain a useful relation between inputs and
  outputs. Do not use a generic helper to move a cast elsewhere.
- Use a type assertion only at a boundary where runtime validation, a library
  contract, or a proven invariant establishes the asserted shape. Keep it local.
  Add a short `SAFETY` comment when the reason is not clear from the code.
