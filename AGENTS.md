# Repository Instructions

## Purpose

Make the smallest coherent change that fully meets the current task. Favor clear,
durable code over short-lived patches, speculative flexibility, or compatibility
layers that have no stated need.

## Sources of Truth

- Read the task, nearby code, repository configuration, and CI workflows before
  choosing an implementation.
- Follow the current task contract over assumptions drawn from similar code.
- Treat existing code as evidence of current behavior, not proof of the desired
  design.
- Follow the repository formatter, linter, type checker, tests, and build
  configuration. Do not invent competing style rules.
- Check the documentation and types of an existing dependency before assuming it
  lacks a needed capability.

## Scope and Design

- Keep changes within the task and the code directly affected by it.
- Restructure directly affected code when the requested change would otherwise add
  duplication, mixed responsibilities, invalid state, extra branches, or a layer
  with no clear role.
- Ask before a notable refactor whose cost, risk, or reach exceeds the task.
- Record weak nearby code as debt instead of changing it without need.
- Choose the simplest implementation that meets known requirements. Do not add
  speculative configuration, extension points, wrappers, or abstractions.
- Add an abstraction when it has a clear owner and removes real duplication or
  isolates a real boundary. Do not add forwarding layers.
- Build a small working change end to end before adding optional capability.
- Keep each module focused. Place behavior with the code that owns the related
  state or invariant.

## Compatibility and Long-Term Choices

- Do not preserve old internal behavior by default. Remove obsolete paths instead
  of adding aliases, fallbacks, dual implementations, or migration code with no
  stated consumer.
- Do not keep a poor pattern merely because nearby code uses it. Apply the new rule
  consistently within the changed area.
- Preserve a public API, stored data, authentication flow, authorization rule,
  deployment contract, or external integration when the task requires it or when
  consumers cannot move in the same change.
- If a required contract must break, make the break explicit, identify its
  consumers, and include the required migration or coordinated change. Do not hide
  the break behind an unrequested compatibility layer.
- Prefer a durable solution within the task's scope. Do not introduce a known
  temporary design that requires replacement unless an external constraint makes
  it necessary. State that constraint and keep the temporary path isolated.

## Dependencies

- Prefer a well-maintained dependency when it reduces total complexity or improves
  reliability.
- Use suitable dependencies already present before adding a package or writing a
  local replacement.
- Add a dependency only when its value exceeds its maintenance, security, bundle,
  and upgrade cost.
- Do not reimplement common behavior without a concrete reason.

## Correctness and Failure Handling

- Define important behavior at boundaries: accepted input, output, state changes,
  errors, permissions, and side effects.
- Make invalid states hard to represent. Keep one owner for each mutable state and
  side effect.
- Handle failures where code can recover, translate them, add useful context, or
  update state it owns. Do not catch and rethrow an unchanged error.
- Do not silently ignore errors or replace them with misleading defaults.
- Protect asynchronous state from stale responses, duplicate submissions, and
  cleanup after disposal when those cases can occur.

## Generated Code and Repository Boundaries

- Identify generated files and nested repositories from repository instructions,
  configuration, generation scripts, and Git metadata.
- Do not edit generated output by hand unless the repository explicitly defines it
  as an editable source.
- Update the source contract or generator, then regenerate output through the
  documented command.
- Treat nested repositories and submodules as separate change boundaries. Do not
  modify one unless the task explicitly includes it.

## Validation

- Give every behavior change a useful test or another clear form of proof unless a
  test would not add value. State the reason when no useful test can be added.
- During development, run the smallest relevant checks for quick feedback.
- Before handoff, run every required repository check in the order and form defined
  by its configuration and CI.
- Do not fix an unrelated pre-existing failure. Verify that it predates the change
  when possible and report it separately.
- Report what ran, what passed, what failed, and what could not run. Never claim a
  check passed without running it.

## Communication

- Write repository instructions, task records, review reports, code comments, and
  agent output in English.
- Use direct, precise, and short language.
- Separate verified facts from assumptions.
- Explain a non-obvious choice through its constraint and effect, not through a
  vague claim that it is cleaner or better.

## Token-Efficient Shell Output

RTK is an optional command-line proxy that filters and summarizes supported
command output. Use it when its command-specific filter is useful, not as a
blind prefix for every command. RTK does not change OpenCode's native file tools.

Before using an unfamiliar RTK command, check the installed version and its help:
```bash
command -v rtk
rtk --help
rtk <command> --help
```

Useful command categories, subject to the installed version:
- `rtk read`, `rtk grep`, `rtk rg`, `rtk ls`, and `rtk git` compact common shell output.
- `rtk test` and language-specific wrappers show focused test or diagnostic output.
- `rtk gain`, `rtk discover`, and `rtk session` report RTK savings and adoption.
- `rtk proxy <command> ...` runs without output filtering but tracks usage. It is not a network proxy.
- `rtk run -c '...'` runs a shell command without filtering or usage tracking.

Use the plain command when RTK has no suitable wrapper, exact raw output matters,
or the wrapper's behavior is unclear. If `rtk` is unavailable, run the plain
command and note the fallback.

## Documentation — always verify with Context7

Use Context7 MCP to cross-reference official documentation for every library, API, or config step involved. Never rely on internal memory when external documentation is available. Always verify against the project's specific versions.
