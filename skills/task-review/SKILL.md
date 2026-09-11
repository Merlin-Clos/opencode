---
name: task-review
description: Run and save an incremental multi-agent review of the current implemented task.
---

# Review the Current Task

Use only the MonAiAgent task-review workflow and its
`task-review-*` specialist agents. Do not invoke the built-in `code-review`,
another review skill, or a generic review workflow.

Review the current saved task.

Use additional text after `/task-review` as optional focus or new evidence; the
saved task remains the review scope.

Require a current `task.md` with status `implemented`. Create one report for this
call, route all required specialists, verify and deduplicate their candidates,
respect prior developer decisions, save only the final filtered report, and update
the review state only after a completed review.

Do not modify product code, choose finding decisions for the developer, invoke
`task-fix-review`, commit, or push.
