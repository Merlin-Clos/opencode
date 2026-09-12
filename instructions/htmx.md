---
description: Apply HTMX hypermedia, server-rendered HTML, request, swap, accessibility, security, and progressive-enhancement rules.
---

# HTMX Instructions

Apply this file when the affected UI uses HTMX.

## Hypermedia and Server Boundaries

- Treat the server-rendered HTML response as the source of truth for the view
  state and interaction result.
- Let HTML semantics, links, forms, HTTP methods, status codes, and response
  fragments describe the application behavior.
- Use `GET` only for safe, idempotent reads. Use `POST`, `PUT`, `PATCH`, or
  `DELETE` for mutations according to the application's HTTP contract.
- Return the smallest complete HTML fragment that the target can safely replace.
- Keep full-page and fragment responses intentionally compatible when the same
  endpoint supports both navigation and HTMX requests.
- Do not create a client-side state store that duplicates server state unless the
  feature genuinely needs local state that the server cannot own.

## Attributes and DOM Targets

- Make `hx-target`, `hx-swap`, and the response root agree with the DOM contract.
- Prefer stable, meaningful element IDs and predictable target boundaries.
- Use `hx-select` and out-of-band swaps only when they make a real multi-region
  update clearer; document the affected IDs when a response updates several
  regions.
- Preserve focus, keyboard behavior, labels, and live-region semantics across
  swaps.
- Use `hx-preserve` only for content whose state must survive replacement, such
  as media playback or a controlled widget.
- Avoid deeply nested inherited HTMX attributes when the request behavior becomes
  hard to discover at the element that triggers it.

## Forms and Requests

- Give submitted controls stable `name` attributes and validate all values on the
  server.
- Prevent duplicate mutations with a clear pending state or server-side
  idempotency strategy where repeated requests would be harmful.
- Use `hx-include`, `hx-vals`, and request configuration narrowly and visibly.
- Prefer `hx-vals` over deprecated `hx-vars`.
- Configure multipart encoding explicitly for file uploads and enforce server
  limits for size, type, and quantity.
- Use response status codes and `HX-*` response headers consistently with the
  application's established contract.

## Errors, Loading, and Concurrency

- Return an actionable error fragment for validation or recoverable failures,
  preserving the user's input where safe.
- Use `hx-indicator`, disabled controls, or an equivalent visible pending state
  for requests that take noticeable time.
- Decide what happens when requests overlap: cancel, serialize, ignore stale
  responses, or reconcile them explicitly.
- Do not hide server errors behind a successful-looking swap.
- Make retry behavior safe for the HTTP method and operation; do not blindly
  retry non-idempotent mutations.

## Security

- Render untrusted values through an auto-escaping template engine.
- Treat every HTMX request as untrusted input and enforce authentication,
  authorization, CSRF protection, validation, and rate limits on the server.
- Do not rely on hidden buttons, client-side attributes, or disabled controls as
  authorization.
- Do not put secrets or authorization decisions in `hx-vars`, `hx-vals`, URLs,
  or HTML comments.
- Set authentication cookies with `Secure`, `HttpOnly`, and an appropriate
  `SameSite` policy.
- Serve only routes controlled by the application and review any endpoint that
  returns user-generated HTML.

## Progressive Enhancement and Accessibility

- Start with a usable semantic link or form, then add HTMX enhancement.
- Keep navigation, validation, and mutation flows usable when JavaScript or
  HTMX is unavailable unless the feature explicitly requires it.
- Preserve browser history intentionally with `hx-push-url` or `hx-replace-url`;
  do not change the URL without deciding how refresh and back navigation behave.
- Announce important dynamic updates with accessible status or live-region
  patterns, and verify focus after swaps.
- Prefer server-rendered HTML over inline JavaScript for behavior that HTMX can
  express directly. Use `hx-on*` only for small, local event handling.

## Verification

- Test the endpoint's full-page and fragment contracts where both exist.
- Test valid, invalid, unauthorized, forbidden, not-found, conflict, and server
  failure responses at the HTTP boundary.
- Verify the target, swap mode, status code, headers, focus behavior, and visible
  error state for important interactions.
- Test refresh, back navigation, duplicate submission, slow responses, and stale
  responses when those states are possible.

## Sources

- [HTMX Documentation](https://htmx.org/docs/)
- [HTMX Web Security Basics](https://htmx.org/essays/web-security-basics-with-htmx/)
- [`hx-vals`](https://htmx.org/attributes/hx-vals/)
- [`hx-vars` deprecation](https://htmx.org/attributes/hx-vars/)
