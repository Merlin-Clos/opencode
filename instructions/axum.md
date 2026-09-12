---
description: Apply Axum routing, extractor, state, middleware, error, response, and async HTTP service rules.
---

# Axum Instructions

Apply this file when the affected service uses Axum.

## Router and HTTP Contracts

- Keep route construction explicit and group routes by domain or feature.
- Preserve the application's path, method, status-code, content-type, and
  response-shape contracts when changing handlers.
- Use the narrowest HTTP method and route scope that expresses the operation.
- Keep handlers focused on request orchestration, boundary validation,
  authorization, and response construction. Put domain decisions in application
  or domain services.
- Do not access persistence directly from a handler when the repository has a
  service or repository boundary.
- Treat route changes as public contract changes and identify affected clients.

## Extractors and Input

- Use typed extractors such as `Path`, `Query`, `Json`, `Form`, `Multipart`, and
  `State` to make input contracts explicit.
- Validate route values, query parameters, headers, cookies, bodies, and claims
  before side effects.
- Remember that extractor order can matter when consuming the request body; keep
  body-consuming extractors last where required by Axum's handler rules.
- Enforce body size, upload size, timeout, and pagination limits for untrusted
  input.
- Return a deliberate rejection or application error instead of leaking parser,
  database, or internal implementation details.

## State and Ownership

- Prefer the typed `State` extractor for application state.
- Make shared state cheap to clone, commonly by storing pools and clients behind
  `Arc` or using types whose clones are already cheap.
- Use `FromRef` or substates when a handler needs only one part of a larger state.
- Keep configuration immutable after startup where possible; put mutable state
  behind an explicit concurrency primitive with a clear owner.
- Avoid request extensions or task-local state when typed state can express the
  dependency. Use dynamic mechanisms only for a real cross-cutting need.

## Errors and Responses

- Make every handler error convertible to the application's response contract.
- Define an application error type that separates safe client-facing messages,
  status codes, logging context, and source errors.
- Map validation, authentication, authorization, not-found, conflict, timeout,
  and unexpected failures distinctly where clients need to react differently.
- Log internal causes at the server boundary without returning secrets, stack
  traces, SQL, tokens, or private data.
- Prefer `IntoResponse` implementations or a central error mapping layer over
  repeated local response construction.
- Do not return `200 OK` for an operation that failed merely because the handler
  produced an HTML or JSON error body.

## Middleware and Tower

- Use Tower and `tower-http` middleware for cross-cutting concerns such as
  tracing, timeouts, compression, request IDs, and limits.
- Apply middleware at the narrowest router boundary that owns its behavior.
- Decide and document middleware ordering, especially for authentication,
  authorization, tracing, timeout, body limits, and error mapping.
- Propagate request cancellation and deadlines through downstream async calls.
- Do not put domain decisions into middleware when they depend on the handler's
  resource or business context.

## Async and External Work

- Keep handlers non-blocking. Move blocking filesystem, CPU-heavy, or legacy
  synchronous work to an appropriate blocking or worker mechanism.
- Bound concurrency for fan-out, streaming, uploads, and background work.
- Avoid holding locks across `.await` unless the design and runtime guarantee it
  is safe and necessary.
- Make retries, repeated submissions, and webhook processing idempotent when a
  request may be delivered more than once.
- Use transactions or an explicit workflow when multiple writes must succeed or
  fail together.

## Security

- Enforce authentication and resource authorization on the server for every
  protected operation.
- Treat identity from authenticated middleware or trusted state as authoritative;
  do not accept the caller's user ID from an untrusted body as proof of identity.
- Configure CORS, cookies, CSRF defenses, headers, TLS termination assumptions,
  and rate limits according to the deployment boundary.
- Validate and constrain redirects, file paths, URLs, uploaded content, and
  serialized input.
- Redact credentials, tokens, cookies, personal data, and full sensitive payloads
  from logs.

## Testing and Operations

- Unit-test pure domain behavior separately from Axum.
- Use router-level integration tests for routing, extractors, middleware,
  serialization, authorization, status codes, and response headers.
- Test error paths and rejection behavior, not only successful handlers.
- Test cancellation, timeout, duplicate requests, body limits, and concurrent
  access when they form part of the service contract.
- Keep startup wiring and shutdown behavior testable; close listeners and owned
  background tasks through explicit lifecycle boundaries.
- Pin feature flags and verify the repository's `cargo fmt`, `cargo clippy`,
  build, and test commands in CI.

## Sources

- [Axum API documentation](https://docs.rs/axum/latest/axum/)
- [Axum error handling](https://docs.rs/axum/latest/axum/error_handling/index.html)
- [Axum repository and examples](https://github.com/tokio-rs/axum)
