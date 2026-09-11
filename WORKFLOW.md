# OpenCode Workflow

This configuration separates developer decisions from the automated work
performed by its OpenCode commands, skills, agents, and scripts.

## Responsibility Layers

This workflow must remain generic to OpenCode and independent of the project in
which it runs. It owns agent orchestration: framing work, constraining scope,
choosing useful proof, coordinating review, and making execution structured,
predictable, and straightforward. It should prevent agents from exploring or
changing unrelated areas without embedding knowledge of a project's business
domain or architecture.

The responsibility layers are:

```text
OpenCode workflow (outer, generic)
    ↓
Agent orchestration and task lifecycle
    ↓
instructions/ (reusable technical guidance)
    ↓
Rules by language, technology, test type, or file type
    ↓
AGENTS.md (inner, repository-owned)
    ↓
Repository context, architecture, commands, and local rules
```

### Reusable technical instructions

`instructions/` deduplicates technical rules that are useful across repositories.
Modules progress from general principles to narrower additions. A specialized
module adds only the rules unique to its context instead of restating its general
base.

For example, a future set of modules could be organized like this (the paths are
illustrative and do not describe the current directory contents):

```text
instructions/
├── tests.md
├── rust.md
├── rust-cli.md
└── axum.md
```

- `tests.md` defines test principles that do not depend on a language.
- `rust.md` adds rules shared by Rust repositories.
- `rust-cli.md` adds only the concerns specific to Rust command-line tools.
- `axum.md` adds only the concerns specific to Axum applications.

A Rust CLI can therefore use the general test, Rust, and Rust CLI guidance, while
an Axum API can use the same test and Rust foundations plus the Axum-specific
module. Neither specialized module needs to copy the shared Rust rules. When a
repository introduces an uncovered language or technology, prefer a new reusable
module at the narrowest useful shared level so later repositories can use it too.

### Repository-owned context

`AGENTS.md` files supply facts and rules that belong to the repository being
changed. They own its purpose, architecture, business constraints, build and
validation commands, generated-file workflows, path conventions, and repository
boundaries. This knowledge belongs to the user's repository, not to the generic
OpenCode workflow.

In a monorepo, a useful structure may be:

```text
repository/
├── AGENTS.md
├── front/
│   └── AGENTS.md
└── back/
    └── AGENTS.md
```

The root file explains the project as a whole and maps its major areas. The files
under `front/` and `back/` add rules for those areas, with deeper files only where
a narrower context provides real value. Keep a rule in `AGENTS.md` when it is true
only for that repository or directory; move it to `instructions/` only when it is
generic enough to be reused elsewhere.

In short: the workflow provides the outer orchestration framework,
`instructions/` factors reusable technical guidance, and `AGENTS.md` supplies the
inner project knowledge.

## Quick Start

1. Run `/task-brainstorm` to frame a request and agree on its task contract.
2. Choose whether to persist the approved contract. Persistence is optional for
   a small task completed in one chat.
3. Run `/task-implement` to make and validate the change.
4. Run `/task-review` when a saved task is `implemented`.
5. Run `/task-fix-review` with explicit decisions for findings that should be
   corrected, dismissed, or deferred.

## Manual and Automatic Steps

### Manually invoked

- `/task-brainstorm` starts repository discovery and contract framing.
- `/task-implement` starts implementation and validation for a direct request or
  the current saved task.
- `/task-review` starts an independent review of the current saved task.
- `/task-fix-review` records developer decisions and corrects only the selected
  findings.

### Performed by the workflow

- `/task-brainstorm` inspects the repository, asks only necessary questions, and
  saves the approved contract only when persistence is chosen.
- `/task-implement` applies the approved scope, runs the required checks, and
  records the result for a saved task.
- `/task-review` routes independent analysis through the review coordinator and
  specialist agents, validates their candidates, and saves one final report.
- `/task-fix-review` records developer decisions, changes only accepted findings,
  and records an incomplete correction before editing so interrupted work can
  resume.
- `scripts/workflow-task.sh` owns saved-task paths and status transitions.
  `scripts/workflow-review.sh` owns diff comparison and reviewed-state capture.

The internal `task-development-loop` skill is loaded by implementation workflows.
It is not a manual entry point.

Do not invoke it by hand: it is the shared implementation engine behind
`/task-implement` and `/task-fix-review`. It still shows up in the `/` menu
because a skill is only shadowed when a same-named command takes precedence —
every other skill has one, `task-development-loop` does not. Keeping its rules
in one shared place avoids duplicating them across both consumers, where an
update on one side could silently change behavior on the other.

## Task Statuses

The normal persisted lifecycle is:

```text
approved -> in-progress -> implemented
```

- `approved`: the saved contract is ready for implementation.
- `in-progress`: implementation or an accepted review correction is active.
- `implemented`: the acceptance criteria and required validation are complete.

An implemented task may return to `in-progress` for `/task-fix-review`, then return
to `implemented` after the selected correction is complete. A resumed correction
remains `in-progress` while work or validation is incomplete.

## Review Findings

Finding states are:

- `open`: no developer decision exists.
- `accepted`: selected for correction.
- `dismissed`: rejected for the current task context.
- `deferred`: valid but outside the current task.
- `fixed`: verified by a later `/task-review`.
- `reopened`: new evidence makes a previous decision relevant again.

Review reports are immutable after completion. Developer decisions are recorded in
`task.md` under `Review Decisions`. A later `/task-review` is the only workflow that
can mark an accepted finding as `fixed` or reopen an earlier decision.

## Persistence and Review

Direct tasks may remain unsaved. An unsaved task cannot use the persisted
`/task-review` workflow. If a later review is expected, save the approved task
before the first implementation edit.

Saved task contracts and review state live under `.copilot/` in the target
repository. `/task-review` requires all of the following:

- a current saved `task.md`;
- task status `implemented`;
- valid task branch and base-commit metadata.

The command creates the first completed review report when no previous report
exists. Later reviews are incremental and compare the current task diff with the
last captured review state.

`/task-fix-review` normally requires an `implemented` task. It may resume an
`in-progress` correction only when persisted accepted findings and an incomplete
Review Fix Record identify the unfinished work. The record keeps `Status:
in-progress` until the correction is complete.

## Usage Tips

### Review in a fresh session

Run `/task-review` in a fresh OpenCode session instead of the one that planned
and implemented the change. A reviewer running in the implementer's session
inherits its bias toward accepting the code; a fresh session recovers the full
task context from the saved `task.md` and still judges the diff on its own
merits. This mirrors the implementer/reviewer split the Bun team used when
rewriting Bun in Rust with Claude: "Usually with humans, the person reviewing
the code is not the person who authored the code... The implementer doesn't
review. The reviewer doesn't implement."
([Rewriting Bun in Rust](https://bun.com/blog/bun-in-rust)).

### Prefer an open model for security review

The `task-review-security` agent reads real weakness and exploit paths. Large
closed-provider models often refuse that work: their guardrails cannot reliably
tell an incident responder from an attacker. During the July 2026 OpenAI/Hugging
Face incident, Hugging Face's responders could not use commercial frontier
models to review attacker exploit payloads and instead ran an open-weight model
(GLM 5.2) on their own infrastructure to finish the forensics
([OpenAI](https://openai.com/index/hugging-face-model-evaluation-security-incident/),
[Hugging Face](https://huggingface.co/blog/security-incident-july-2026)). Bind a
capable open-weight model to `task-review-security` rather than a heavily
guardrailed closed model.

## Nested Repositories and Submodules

Each saved task records the root repository and every nested Git repository or
submodule explicitly included by the task. A target repository defines the
available nested repositories in a root-level `mon-ai-agent.json` file:

```json
{
  "nestedRepositories": [
    {
      "name": "Shared Library",
      "path": "modules/shared-library"
    }
  ]
}
```

Each `path` must be a configured safe relative path to the root of an existing
nested Git repository. Select one or more configured paths when creating the saved
task:

```bash
$HOME/.config/opencode/scripts/workflow-task.sh \
    -Action create \
    -Name "Update shared behavior" \
    -IncludeRepository "modules/shared-library"
```

Repeat `-IncludeRepository` to include more than one configured repository. No
configuration is required when a task involves only the root repository. Review
comparison and state capture use the repositories and base commits stored in the
task, not later changes to `mon-ai-agent.json`.

This support includes nested repositories in a task's implementation and review
scope. It is not a procedure for installing this OpenCode configuration as a
submodule.

## Repository Map

- `commands/`: manual `/task-brainstorm`, `/task-implement`, `/task-review`, and
  `/task-fix-review` entry points.
- `skills/`: task workflows, including the internal `task-development-loop`.
- `agents/`: discovery, implementation, review coordination, and review
  specialists.
- `scripts/`: saved-task and review-state operations.
- `instructions/`: reusable technical guidance described under
  [Responsibility Layers](#responsibility-layers).
- `rules/`: local command permission rules.
- `AGENTS.md`: instructions owned by this configuration repository; target
  repositories provide their own local context.
- `.copilot/`: optional persisted contracts, review reports, and review state in a
  target repository.
