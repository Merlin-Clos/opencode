---
---

# PrimeVue Instructions

## Forms

- Use PrimeVue `Form` and named fields instead of parallel `v-model` state for
  standard form controls.
- Define typed initial values that match the form's actual fields and nullability.
- Return field errors as arrays whose `message` values are stable translation keys.
- Translate validation keys in the template with `$t(...)`; do not translate them
  inside resolver logic.
- For a custom or non-standard control, use `FormField` and forward the field
  contract, including change and blur handling.
- Use `formRef.setValues(...)` when existing data must populate a form.
- Treat submitted values as a boundary. Narrow or validate them before passing
  them to business or external code.
- If PrimeVue's `FormSubmitEvent` loses the form's static type, allow one local
  assertion only when the typed initial values and resolver enforce the same
  shape. Do not repeat that assertion downstream.
- Keep `null` distinct from an empty string, zero, or `false` when the API or
  business rule gives them different meanings.
