---
description: Apply idiomatic Rust, ownership, error-handling, API design, dependency, and verification rules.
---

# Rust Instructions

Apply this file when the affected code is written in Rust.

## Repository and Toolchain

- Read `Cargo.toml`, workspace configuration, the declared edition, toolchain
  files, build scripts, lint configuration, and nearby modules before choosing
  a pattern.
- Follow the repository's Rust edition, MSRV, feature flags, formatter, lint,
  build, and test commands.
- Use Cargo for dependency resolution, builds, tests, examples, and packaging.
- Run `cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets --all-features -- -D warnings` when the repository supports them, and the declared test commands.
- Do not enable broad Clippy categories or deny new lints without checking the
  repository's compatibility and false-positive policy.

## Ownership and Types

- Prefer ownership and borrowing that make lifetime and mutation boundaries
  obvious.
- Borrow when the callee does not need ownership; take ownership when the API
  must store, transform, or transfer the value.
- Prefer slices such as `&str` and `&[T]` for read-only borrowed input, and
  `String` or `Vec<T>` when ownership is required.
- Model invalid states with enums, newtypes, and discriminated data rather than
  unrelated booleans, sentinel values, or unchecked strings.
- Preserve precise types across boundaries. Do not use `dyn Any`, broad casts,
  or unnecessary cloning to hide an unclear contract.
- Keep clones explicit and justified by ownership, sharing, or performance
  needs. Do not clone merely to silence the borrow checker.
- Use `Arc`, `Rc`, `Mutex`, `RwLock`, and interior mutability only when their
  ownership or synchronization semantics are part of the design.

## Errors and Panics

- Use `Result` for recoverable failures and `Option` for expected absence.
- Propagate errors with `?` when the current layer cannot recover or translate
  them.
- Add context at meaningful boundaries and preserve the source error.
- Define domain errors that express actionable failure cases; do not expose
  implementation or secret details to external callers.
- Keep `unwrap`, `expect`, indexing, and `panic!` for invariants that are
  genuinely impossible or explicitly owned by the boundary. Document why when
  the invariant is not obvious.
- Do not use panics for ordinary input validation, missing data, I/O failure,
  or user-controlled values.

## API and Module Design

- Keep modules cohesive and public APIs small, predictable, documented, and
  consistent with Rust naming conventions.
- Prefer composition, traits at real abstraction boundaries, and generic code
  only when callers retain a useful relationship between input and output.
- Use `pub(crate)` or private visibility by default; expose only what consumers
  need.
- Avoid pass-through wrappers, premature traits, and abstractions that only move
  a cast or branch elsewhere.
- Document public items, safety invariants, panic conditions, error behavior,
  ownership, and examples when they are important to correct use.
- Keep unsafe code isolated, minimal, justified by a safety comment, and covered
  by tests for the invariant it relies on. Prefer safe APIs when they are clear
  and adequate.

## Async and Concurrency

- Use the runtime and async conventions already established by the repository.
- Do not block an async executor with synchronous waiting, blocking I/O, or
  CPU-heavy work unless it is deliberately isolated on a blocking or dedicated
  worker.
- Propagate cancellation and timeouts through external calls when supported.
- Bound concurrency and resource usage when processing untrusted or unbounded
  input.
- Hold locks for the shortest useful scope. Do not hold a synchronous mutex
  across an `.await` unless the runtime and design explicitly make that safe.
- Make shared mutable state ownership explicit and avoid global mutable state.

## Dependencies and Performance

- Add a dependency only when it removes meaningful complexity or supplies a
  well-maintained capability the project should not own.
- Match dependency versions and feature flags to the workspace policy; avoid
  enabling broad feature sets without need.
- Measure before optimizing. Inspect allocations, copies, I/O, contention, and
  algorithmic complexity when performance matters.
- Prefer iterators and direct transformations when they improve clarity, but do
  not contort readable code to avoid every allocation.
- Do not materialize, clone, sort, or collect data earlier than the behavior or
  boundary requires.

## Tests and Verification

- Test behavior, invariants, error cases, boundary values, and state transitions
  at the smallest useful level.
- Add integration tests when behavior depends on Cargo features, serialization,
  networking, a database, a real runtime, or multiple modules together.
- Add a focused regression test for every reproducible defect.
- Avoid tests that assert implementation details, incidental ordering, or exact
  helper calls unless those are part of the contract.
- Keep examples and documentation tests compiling when they are part of the
  public API.

## Sources

- [The Rust Programming Language](https://doc.rust-lang.org/book/)
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [The Cargo Book](https://doc.rust-lang.org/cargo/)
- [Clippy Documentation](https://doc.rust-lang.org/clippy/)
