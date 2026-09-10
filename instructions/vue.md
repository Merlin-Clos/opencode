---
---

# Vue Instructions

## Component Structure

- Use Vue 3 Composition API with `<script setup lang="ts">`.
- Keep components focused on rendering, user interaction, and orchestration.
- Move pure business rules and data transforms out of components.
- Follow the repository formatter configuration. Do not restate or override it in
  generated code.

## Responsibility Boundaries

Use this flow when each part has real work to own:

```text
Vue component -> composable -> domain or external service
```

- A component owns view composition and user events.
- A composable owns reactive state, Vue lifecycle behavior, and reusable UI
  orchestration.
- A service owns calls to an external boundary, data adaptation, and operations
  that do not need Vue reactivity.
- Skip a layer that would only forward arguments and return the same value.
- Use Pinia only for state shared across independent consumers or routes. Keep
  feature-local state in the feature.
- Keep one owner for loading, mutation, and error state. Do not let a component and
  composable manage competing copies of the same state.

## External Data and Models

- Treat external responses as transport data, not screen models.
- Convert external data to the model owned by the feature once, in the service or
  boundary adapter that consumes it.
- Do not cast transport data directly to a domain or screen model when their
  contracts differ.
- Keep transport naming, nullability, and optional fields at the external boundary
  when the rest of the feature needs a stronger model.

## Async State and Errors

- Use a plain boolean `ref` only for a true independent boolean.
- Use a discriminated union or one status field for exclusive states such as
  `idle`, `loading`, `success`, and `error`.
- Prevent an older request from replacing newer state when requests can overlap.
- Prevent duplicate submission when it could repeat a mutation.
- Clean up watchers, listeners, timers, and pending effects owned by a component or
  composable.
- Catch an error only where the code can recover, translate it, add useful context,
  or update owned UI state.
- Use `finally` for cleanup that must happen after both success and failure.
- Preserve useful error detail. Do not turn unrelated failures into the same silent
  fallback.

## Routing and Authorization

- Keep client route guards and navigation visibility aligned.
- Treat hidden navigation as presentation, not authorization. Do not rely on it to
  protect a route or operation.
- Preserve server-side authorization requirements when changing client routing or
  visibility.

## Internationalization

- Use stable translation keys for user-visible labels, placeholders, help text,
  validation messages, errors, and notifications.
- Do not add hard-coded user-visible text when the feature uses i18n.
- Keep translation out of business rules, resolvers, and services. Return a stable
  code or key and translate at the view boundary.
- Update every locale required by the repository when adding or changing a key.
- Run the repository i18n check after changing keys or locale files.

## Maintainability

- Prefer pure functions for rules and transforms.
- Remove duplication at the level of behavior or knowledge. Do not merge code that
  only looks similar but follows different rules.
- Avoid pass-through composables and services that add no policy, mapping, state,
  or boundary.
- Reduce nesting with guard clauses when they keep the main path clear.
- Split code when responsibilities, state ownership, or independent paths make it
  hard to reason about. Do not split a function into empty forwarding helpers only
  to lower a metric.
