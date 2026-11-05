---
name: task-implement
description: Implement a direct request or the current saved task and validate it before handoff.
---

# Implement a Task

You run in the foreground as the implementation coordinator. You own the task
lifecycle and, when a dedicated test phase adds value, delegate the work to
two isolated subagents, strictly sequentially. Do not use another built-in
implementation or planning skill.

Complete every in-scope acceptance criterion in the same invocation. Do not return
a progress-only message between criteria or after an intermediate successful step.
Continue with the next tool call until the task is complete, a blocking decision is
required, or an unrecoverable failure prevents further work.

Use additional text after `/task-implement` as a direct task. When no direct task
is supplied, resolve the current saved task through
`$HOME/.config/opencode/scripts/workflow-task.sh -Action current`.

Do not combine a direct request with an unrelated saved task.

## Decide the Test Strategy

Before delegating, decide whether a dedicated test phase adds value. An
explicit user instruction always wins: a request for tests (or a Validation
Plan that demands them) runs the test phase; a request for a quick,
prototype, or throwaway result skips it.

Otherwise run the `task-test` subagent only when the change touches code that
must keep working unattended: production source, public contracts and APIs,
shipped scripts such as deploy, CD, or CI scripts, persistent state,
security or auth paths, or anything the saved contract requires tests for.

Skip the test phase when every touched file is throwaway or local-only
tooling: benchmark harnesses, measurement scripts, linter runners, scratch
prototypes, one-off inspection or migration scripts. Such code fails loudly
on run and costs minutes to fix; testing the test scaffolding is debt, not
quality. For mixed tasks, scope the test phase to the production part only
and implement the helper scripts directly.

When the test phase is skipped, implement the code directly instead of
delegating, prove it by running it once, and state in the handoff why no
dedicated tests were added, per the repository validation rules.

## Phased Plans

A saved task may carry an `## Implementation Phases` section, with details
inline or in `phase-N.md` files beside `task.md`. When it does, implement
the phases in dependency order: never start a phase whose dependencies are
not `done`, and independent phases in any convenient order. Update each
phase's `Status` (`pending` → `in-progress` → `done`, or `blocked` with the
reason) in the task or phase file as the work completes; the top-level task
`status` still moves only through `scripts/workflow-task.sh`. Run one
test-then-code cycle per phase so each phase stays verifiable on its own.
When new evidence invalidates a phase, stop, report the conflict, and wait
for a plan revision instead of silently changing the approved scope.

## Resolve and Baseline

Resolve the task, read the whole `task.md` for a saved task, and establish the
baseline: current branch and working tree, files and symbols directly involved,
relevant tests, types, schemas, repository configuration, CI commands, generated
contracts, and nested repositories in scope. Move a saved task from `approved`
to `in-progress` with the explicit resolved path before the first delegated
edit, as described in the `task-development-loop` skill. The loop skill remains
the reference for baseline, validation, status, and handoff mechanics; only the
edit work itself is delegated below instead of done directly.

## Phase 1 — Tests (`task-test`)

Only when the test strategy above calls for it, invoke the `task-test`
subagent through the Task tool and wait for its completion. Do not start any
production edit in parallel. Give it the resolved `task.md` path, the task
name, and the in-scope paths, narrowed to the code that must keep working
when mixed with throwaway helpers. It reads the full contract and writes the
failing tests, then triages its own suite.

When it returns, verify its tests fail for the intended reason. If they pass
without production changes or fail for the wrong reason, send one focused
correction back to `task-test` before continuing.

## Phase 2 — Code (`task-code`)

When Phase 1 ran, invoke the `task-code` subagent only after it is accepted.
When Phase 1 was skipped, implement the change directly instead of
delegating. Give a delegated `task-code` minimal context: a short goal
summary in your own words, the relevant acceptance criteria, the failing test
file paths from Phase 1, and the in-scope paths. Do not pass the full `task.md`
content. Each subagent has its own context window; that isolation keeps the
tests objective and the fix minimal. Prove a directly implemented change by
running it and reporting the output.

## Validate and Hand Off

Run the required repository checks in CI order and provide a handoff, following
the validation, saved-task update, and handoff rules of the
`task-development-loop` skill. Do not start a review, commit, push, or open a
pull request.
