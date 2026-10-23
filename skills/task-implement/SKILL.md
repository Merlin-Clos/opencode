---
name: task-implement
description: Implement a direct request or the current saved task and validate it before handoff.
---

# Implement a Task

You run in the foreground as the implementation coordinator. You own the task
lifecycle and delegate the work to two isolated subagents, strictly
sequentially. Do not use another built-in implementation or planning skill.

Complete every in-scope acceptance criterion in the same invocation. Do not return
a progress-only message between criteria or after an intermediate successful step.
Continue with the next tool call until the task is complete, a blocking decision is
required, or an unrecoverable failure prevents further work.

Use additional text after `/task-implement` as a direct task. When no direct task
is supplied, resolve the current saved task through
`$HOME/.config/opencode/scripts/workflow-task.sh -Action current`.

Do not combine a direct request with an unrelated saved task.

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

Invoke the `task-test` subagent through the Task tool and wait for its
completion. Do not start any production edit in parallel. Give it the resolved
`task.md` path, the task name, and the in-scope paths. It reads the full
contract and writes the failing tests, then triages its own suite.

When it returns, verify its tests fail for the intended reason. If they pass
without production changes or fail for the wrong reason, send one focused
correction back to `task-test` before continuing.

## Phase 2 — Code (`task-code`)

Only after Phase 1 is accepted, invoke the `task-code` subagent through the
Task tool and wait for its completion. Give it minimal context: a short goal
summary in your own words, the relevant acceptance criteria, the failing test
file paths from Phase 1, and the in-scope paths. Do not pass the full `task.md`
content. Each subagent has its own context window; that isolation keeps the
tests objective and the fix minimal.

## Validate and Hand Off

Run the required repository checks in CI order and provide a handoff, following
the validation, saved-task update, and handoff rules of the
`task-development-loop` skill. Do not start a review, commit, push, or open a
pull request.
