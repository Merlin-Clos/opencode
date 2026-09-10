---
name: task-implement
description: Implement a direct request or the current saved task and validate it before handoff.
---

# Implement a Task

Delegate implementation to the `task-implementation` agent.

Use the `task-development-loop` skill as the implementation workflow. Do not use
another built-in implementation or planning skill.

Use additional text after `/task-implement` as a direct task. When no direct task
is supplied, resolve the current saved task through
`$HOME/.config/opencode/scripts/workflow-task.sh -Action current`.

Do not combine a direct request with an unrelated saved task.

Implement, test, run the required repository checks, and provide a handoff. Do not
start a review, commit, push, or open a pull request.
