---
description: Apply Tauri 2 architecture, IPC, capabilities, permissions, state, packaging, and desktop security rules.
---

# Tauri Instructions

Apply this file when the affected application uses Tauri 2.

## Architecture and Boundaries

- Treat the WebView frontend and the Rust application core as different trust
  boundaries.
- Keep presentation, browser interactions, and local UI state in the frontend;
  keep privileged filesystem, process, network, and OS integration in Rust or a
  deliberately selected Tauri plugin.
- Expose the smallest command and plugin surface that the frontend actually
  needs.
- Keep business rules independent from Tauri where possible so they remain
  testable without creating a window or WebView.
- Read the repository's Tauri, frontend, Rust, and build configuration before
  changing generated setup or platform-specific behavior.

## Commands and IPC

- Treat every `invoke` payload as untrusted input, even when it originates from
  the application's own frontend.
- Define typed command arguments and return values; validate and normalize input
  before performing side effects.
- Return structured, stable errors that the frontend can act on without exposing
  internal paths, secrets, stack traces, or implementation details.
- Keep commands focused on one application operation and move domain decisions
  into application services.
- Make command names, payloads, errors, and event names explicit contracts.
- Avoid using global Tauri APIs when importing only the required JavaScript API
  keeps the dependency and permission surface smaller.
- Use raw payloads or another deliberate serialization strategy only when IPC
  volume justifies it; measure before optimizing transport overhead.

## Capabilities and Permissions

- Define capabilities in `src-tauri/capabilities` and grant only the commands,
  plugins, windows, and WebViews required by each feature.
- Prefer separate, narrowly scoped capability files for distinct windows or
  trust levels.
- Review the effective permissions when a window or WebView belongs to multiple
  capabilities; combined capabilities can merge their access.
- Treat plugin default permissions as a starting point, not as proof that the
  resulting application is least-privilege.
- Use filesystem, HTTP, shell, notification, and other plugin scopes to limit
  paths, hosts, programs, and operations explicitly.
- Do not enable broad permissions, unrestricted shell commands, arbitrary URLs,
  or unrestricted filesystem access for convenience.
- Do not assume that hiding a frontend control or omitting a command from the UI
  protects the operation; enforce the boundary through Tauri permissions and
  command validation.

## State, Windows, and Events

- Keep shared application state behind an explicit owner and synchronization
  strategy; do not create mutable global state without a clear lifecycle.
- Initialize long-lived services, clients, and pools during application setup
  when their startup failures should prevent the app from running.
- Use window labels as stable identifiers and keep labels unique when multiple
  windows exist.
- Decide whether a window is created from configuration or programmatically, and
  preserve that decision consistently.
- Use events for notifications and state changes, not as a substitute for a
  typed command response or durable data store.
- Handle window close, minimize, suspend, resume, and application exit behavior
  explicitly when resources or background tasks depend on them.
- Clean up listeners, timers, child processes, and background tasks at the owner
  lifecycle boundary.

## Files, URLs, and Native APIs

- Use Tauri path APIs and plugin scopes instead of concatenating user-controlled
  filesystem paths.
- Reject traversal, unexpected absolute paths, and paths outside the approved
  base directory before access.
- Validate URLs and restrict network access to the hosts and schemes the feature
  requires.
- Treat downloaded files, deep links, file associations, and shell invocations
  as security-sensitive input paths.
- Prefer official Tauri plugins or well-maintained integrations for OS features;
  inspect their permissions and platform behavior before adopting them.
- Keep platform-specific code isolated and document behavior that differs across
  Windows, macOS, Linux, Android, and iOS.

## Frontend Integration

- Keep the frontend usable and testable independently of the native bridge when
  the product supports a browser or web fallback.
- Centralize IPC wrappers in a small frontend boundary instead of scattering raw
  `invoke` calls through components.
- Map transport errors to user-facing states at the frontend boundary; do not
  make every component understand native error details.
- Prevent duplicate commands and stale responses when a native operation can be
  slow, retried, or invoked concurrently.
- Do not put secrets in bundled frontend assets, configuration visible to the
  WebView, command arguments, or logs.

## Build, Updates, and Distribution

- Keep Tauri CLI, Rust crates, JavaScript packages, and plugin versions aligned
  with the repository's supported matrix.
- Review `tauri.conf.json`, capabilities, bundle identifiers, signing settings,
  updater settings, and platform entitlements as release-sensitive configuration.
- Do not weaken CSP, asset protocol scopes, signing, or update verification to
  make development or packaging easier.
- Test packaged builds on every supported platform and WebView combination;
  development mode does not prove production behavior.
- Keep release artifacts reproducible and verify signing, update channels,
  permissions, and migration behavior before distribution.

## Tauri-Specific Verification

- Test commands with valid, invalid, unauthorized, missing, oversized, and
  concurrent payloads at the IPC boundary.
- Test the effective capability and plugin permissions for each window or
  WebView, including multi-capability combinations.
- Test filesystem and URL scopes with allowed, denied, traversal, and boundary
  inputs.
- Test startup failures, window lifecycle events, application shutdown, and
  cleanup of owned tasks or processes.
- Test a production-like packaged build for IPC, asset loading, permissions,
  updater behavior, and platform-specific integrations.

## Sources

- [Tauri 2 documentation](https://v2.tauri.app/)
- [Tauri security model](https://v2.tauri.app/security/)
- [Capabilities](https://v2.tauri.app/security/capabilities/)
- [Tauri configuration reference](https://v2.tauri.app/reference/config/)
- [Filesystem plugin security](https://v2.tauri.app/plugin/file-system/)
