---
name: task-fix-review
description: Record review decisions and correct only the findings selected by the developer.
---

# Fix Selected Review Findings

Delegate correction to the `task-implementation` agent in review-correction mode.

Use only the MonAiAgent task workflow. Do not invoke the built-in `code-review`,
a generic fix skill, or another review workflow.

Process these developer decisions for the current saved task.

Use additional text after `/task-fix-review` as the developer decisions to process.

This is review-correction mode. Use the `task-development-loop` skill for repository
inspection, implementation, tests, validation, task status changes, and handoff.
Apply the additional rules below.

## Resolve and Validate

1. Resolve the task with:

    ```bash
    $HOME/.config/opencode/scripts/workflow-task.sh -Action current
   ```

2. Read the whole `task.md` and every report under its `reviews/` directory.
3. Require at least one completed review and either:
   - a task status of `implemented`; or
   - a task status of `in-progress` with persisted `accepted` Review Decisions
     and an incomplete Review Fix Record showing that a prior `/task-fix-review`
     correction is being resumed.
   A Review Fix Record is incomplete only when its `Status` is `in-progress`.
4. Parse the developer input into explicit actions:
   - `fix` means `accepted` and selected for correction now;
   - `dismiss` means `dismissed` for this task context;
   - `defer` means `deferred` outside the current task.
5. Verify every finding ID against the saved reports before changing any file.
6. Stop and ask when an ID is unknown, an action is ambiguous, or a dismissal or
   deferral has no reason.

Do not infer a decision for an unmentioned finding. It keeps its current state, and
an unselected `open` finding remains `open`.

## Record Developer Decisions

Persist validated decisions in `task.md` under `## Review Decisions`. Create the
section when absent. Use one current entry per finding:

```md
### F-001

- Status: accepted
- Decided-at: <ISO 8601 timestamp>
- Reason: Selected for correction through `/task-fix-review`.
```

Use the developer's stated reason for `dismissed` and `deferred`. If an entry for
the same ID already exists, update that entry instead of adding a duplicate.

Never edit an existing review report. Do not set `fixed` or `reopened`; only a later
`/task-review` may verify a fix or reopen a finding with new evidence.

If the input contains only dismissals or deferrals, record the decisions, leave the
task status unchanged (normally `implemented`; keep `in-progress` when resuming a
correction), return a summary, and stop without changing code.

## Correct Accepted Findings

When at least one finding is selected for correction:

1. Re-read each selected finding's evidence, impact, location, and suggested
   direction in the latest report that contains it.
2. Inspect the current code and confirm the finding still applies.
3. If the task status is `implemented`, move it to `in-progress` with the explicit
   resolved path:

    ```bash
    $HOME/.config/opencode/scripts/workflow-task.sh \
        -Action set-status \
        -TaskPath "<resolved task.md path>" \
       -Status in-progress
   ```

   When resuming an `in-progress` correction, do not repeat the status transition.
4. When resuming, confirm the finding IDs listed in the incomplete record are still
   `accepted` and continue only their unfinished work. Do not add new IDs or repeat
   work already listed as corrected in the incomplete Review Fix Record.
5. Create or update the incomplete Review Fix Record described below before the
   first code edit.
6. Correct only the accepted IDs and code directly required by those corrections.
7. Add or update useful regression or behavior tests for each corrected finding.
8. Run focused checks during correction, then all repository checks required by the
   `task-development-loop` skill before handoff.

Do not fix open, dismissed, or deferred findings. Do not expand the task to nearby
debt. If one selected fix requires a material contract or scope change, stop and
ask before implementing it.

If current evidence shows that an accepted finding no longer applies, do not change
its status yourself. Treat it as resolved for this correction handoff, record the
evidence, and let the next `/task-review` decide whether it is `fixed` or otherwise
no longer valid.

## Record the Correction

Before the first code edit, create the `Review Fix Record` for a new correction,
or update the existing incomplete record when resuming. Keep it in `task.md`
without rewriting the approved contract, and set its `Status` to `in-progress`
so an interrupted correction can be resumed:

```md
## Review Fix Record — <ISO 8601 timestamp>

- Status: in-progress
- Requested findings: F-001, F-003
- Corrected findings: None
- Unresolved findings: F-001, F-003
- Changed areas: Correction in progress
- Validation: Not run yet
- Remaining limits: None
```

When the correction completes, update this same record in place to `Status:
completed` and replace its progress fields with the final corrected, unresolved,
changed-area, validation, and limit details. Do not append a second record for the
same correction. If the correction remains incomplete, keep `Status: in-progress`
and record the blocker and the work still unfinished.

Keep findings as `accepted` until a later `/task-review` verifies them. A successful
implementation is not proof from the independent reviewer.

Move the task back to `implemented` only when every selected correction is complete
and the required checks succeeded or an unrelated pre-existing failure is clearly
established:

```bash
$HOME/.config/opencode/scripts/workflow-task.sh \
    -Action set-status \
    -TaskPath "<resolved task.md path>" \
    -Status implemented
```

If a selected correction remains incomplete or a failure is caused by the change,
leave the task `in-progress` and report the blocker.

## Handoff

Return:

- decisions recorded by finding ID;
- findings corrected and still unresolved;
- tests and checks with exact results;
- the task status and path;
- `/task-review` as the next manual action only when the task is `implemented`;
  otherwise report that the correction must be resumed before review.

Do not invoke `/task-review`, modify review reports, create a new report, mark a finding
`fixed`, commit, push, or open a pull request.
