---
name: task-development-loop
description: Implement an approved software task in the current repository with focused changes, short feedback loops, useful tests, and a verified handoff. Use when writing or changing code; do not use for task discovery or independent code review.
---

# Development Loop

Implement the agreed behavior, prove it, and stop for developer review. Apply the
repository-wide and path-specific instructions; do not repeat them in task notes.

## Resolve the Task

Use task input in this order:

1. A contract or request supplied in the current conversation.
2. The saved task referenced by `.copilot/current-task.txt`.

For a saved task, use `$HOME/.config/opencode/scripts/workflow-task.sh -Action current` to resolve
the path. Read the whole `task.md` before changing code.

- Do not silently combine a direct request with an unrelated saved task.
- If both exist and conflict, ask which one controls the work.
- A small direct task may proceed without persistence when its expected behavior is
  clear.
- A direct unsaved task cannot use the persisted `/task-review` workflow. If the
  developer expects a later `/task-review`, propose saving the approved task before the
  first implementation edit. Do not present `/task-review` as immediately available in
  the handoff of an unsaved task.
- If the task lacks a choice that changes behavior, scope, a public contract, data,
  or security, stop and ask. Do not invent that choice during implementation.
- Treat the approved contract as fixed. Propose any material change and wait for
  approval before updating it or the implementation.

## Establish the Baseline

Before editing:

- inspect the current branch and working tree;
- preserve changes that were already present;
- inspect the files and symbols directly involved;
- locate relevant tests, types, schemas, repository configuration, and CI commands;
- identify generated contracts or output used by the feature without editing them;
- confirm the nested repositories included by the saved contract.

For a saved task, compare the current repository with its recorded base commit.
If the branch changed, the base commit is unavailable, or unexpected work overlaps
the task, report the mismatch before proceeding.

After the baseline is valid and immediately before the first code edit, use
`$HOME/.config/opencode/scripts/workflow-task.sh` to move the saved task from `approved` to
`in-progress`:

```bash
$HOME/.config/opencode/scripts/workflow-task.sh \
    -Action set-status \
    -TaskPath "<resolved task.md path>" \
    -Status in-progress
```

Pass the resolved task path explicitly. Never update a task status through
`.copilot/current-task.txt` alone. If an ordinary `/task-implement` call finds an already
`implemented` task, confirm that the developer intends to reopen it before moving
it back to `in-progress`.

## Choose the Working Slice

Start with the smallest end-to-end behavior that can work and be tested.

- Identify the observable result and its owner.
- Trace the required behavior from its entry point through state, domain logic,
  external boundaries, and observable output.
- Change only the layers that have real work to own.
- Restructure directly affected code when adding the behavior would otherwise
  preserve a poor pattern, duplicate knowledge, mix responsibilities, or add
  invalid state.
- Ask before a refactor whose reach or risk exceeds the task.
- Do not add compatibility paths, wrappers, configuration, or extension points
  without an identified need.

Keep a short working plan for multi-step changes. Do not turn a small edit into a
planning exercise.

## Implement with Evidence

For each behavior:

1. Choose the smallest useful proof.
2. When test-first work adds value, write a test that fails for the intended reason.
3. Make the smallest coherent production change that passes it.
4. Refactor the changed area while the proof stays green.
5. Run the nearest relevant type, lint, or test check before moving on.

Prefer test-first work for reproducible bugs, business rules, pure transforms,
state transitions, and branching behavior. Do not force it for trivial wiring.

During implementation:

- keep type information precise across every changed boundary;
- adapt external data once at the boundary that owns the mapping;
- keep one owner for mutable state and side effects;
- handle stale responses and duplicate mutations when the flow permits them;
- use existing dependencies after checking their documentation and types;
- remove obsolete code made unnecessary by the change;
- avoid unrelated cleanup.

If repository evidence disproves the task contract, stop with the conflicting fact
and a recommended contract change. Do not work around the conflict in secret.

## Validate in Short Loops

During development, run focused checks that give quick feedback:

- the changed test file or nearest test group;
- targeted type checking or linting when supported;
- a focused reproduction for a bug;
- the smallest build step that validates a changed boundary.

Fix failures caused by the current change before widening the checks. Do not repair
an unrelated pre-existing failure without developer approval.

## Validate Before Handoff

Read repository configuration and CI workflows to derive the real commands.

Run every required check in CI order. Depending on the repository, these may
include:

1. formatting;
2. static analysis or linting;
3. type checking or compilation;
4. focused and full tests;
5. coverage checks;
6. packaging or a production build;
7. security or dependency checks.

Do not replace a repository command with a guessed equivalent. If a full check
cannot run, run the strongest safe subset and state exactly what remains unverified.

Classify every failure:

- caused by this change: fix it and rerun the affected checks;
- pre-existing and unrelated: show the evidence and leave it unchanged;
- environment or access failure: report the command, error, and missing condition.

Never claim a check passed unless its command completed successfully.

## Update a Saved Task

When the task is saved, preserve its approved contract and metadata. Before handoff:

- move it to `implemented` through `$HOME/.config/opencode/scripts/workflow-task.sh` only after
  the implementation is complete and its acceptance criteria are met;
- append or update one `Implementation Record` using this shape:

  ```md
  ## Implementation Record — <ISO 8601 timestamp>

  - Implemented behavior:
  - Changed areas:
  - Contract changes: None
  - Validation:
  - Known limits: None
  - Scoped debt: None
  ```

  Replace the placeholders with factual details. Keep changed areas at the
  behavior or responsibility level rather than writing a file-by-file diary.
  Record pre-existing failures under known limits and any deliberately excluded
  nearby work under scoped debt.

Do not rewrite the original acceptance criteria to make the implementation appear
complete. Mark unmet criteria clearly and keep the status `in-progress`.

Use the explicit resolved path:

```bash
$HOME/.config/opencode/scripts/workflow-task.sh \
    -Action set-status \
    -TaskPath "<resolved task.md path>" \
    -Status implemented
```

Use `$HOME/.config/opencode/scripts/workflow-task.sh` for every status transition. Do not edit
the frontmatter status by hand.

## Handoff

Return a concise handoff containing:

- what changed and the observable result;
- important design choices;
- tests and checks that passed;
- checks that failed or did not run;
- remaining risks, limits, or debt;
- the saved task path, when used.

Stop after the handoff. Suggest `/task-review` only when a saved task is implemented;
do not suggest it for a direct unsaved task. Do not invoke it or create a review
report.

## Stop Conditions

Stop and ask the developer when:

- an unresolved product choice changes the result;
- the required change breaks an unidentified public or data contract;
- the work would cross a repository boundary without task approval;
- unexpected existing changes overlap the files that must be edited;
- a needed permission, dependency, service, or environment is unavailable;
- the safe implementation requires a material expansion of scope.
