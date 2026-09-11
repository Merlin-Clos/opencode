---
---

# Nuxt UI Instructions

## Forms

- Use `UForm` with `:schema` and `:state` plus named `UFormField` entries instead
  of ad-hoc parallel state for standard form controls.
- Define a typed state object that matches the form's actual fields and
  nullability.
- Let the schema gate submission: `UForm` validates before emitting `@submit`,
  so read the validated payload from the submit event instead of revalidating by
  hand.
- Return field errors as arrays whose `message` values are stable translation keys.
- Translate validation keys in the template; do not translate them inside schema
  or resolver logic.
- For a custom or non-standard control, wrap it in a named `UFormField` and keep
  its model bound to the form state so validation and errors stay attached.
- Populate existing data by assigning the form state, not by keeping a parallel
  copy.
- Use the form ref (`validate()`, `setErrors(...)`, `clearErrors()`) for
  programmatic validation and server-side errors instead of parallel error state.
- Type the submit handler as `FormSubmitEvent<Schema>` and read validated data
  from `event.data`. Do not repeat that typing downstream.
- Treat submitted values as a boundary. Narrow or validate them before passing
  them to business or external code.
- Keep `null` distinct from an empty string, zero, or `false` when the API or
  business rule gives them different meanings.
