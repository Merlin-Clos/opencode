---
name: task-brainstorm
description: Frame a software task against the current repository before implementation.
---

# Brainstorm a Task

Do not invoke another planning or brainstorm skill.

Use additional text after `/task-brainstorm` as the task to frame.

Turn a request into a decision-ready task contract grounded in the repository.
Do not modify product code, tests, configuration, dependencies, or generated files.

## Establish the Starting Point

1. Restate the requested outcome in one short paragraph.
2. Inspect the smallest useful part of the repository before proposing a design:
   - entry points and code that own the affected behavior;
   - domain logic, state, external boundaries, and tests;
   - types, schemas, or generated contracts used by the feature;
   - nearby conventions and reusable code;
   - repository checks and CI configuration;
   - Git state and any nested repository included by the task.
3. Separate verified facts from assumptions and open questions.
4. Identify generated files and nested repositories from repository instructions,
   configuration, generation scripts, and Git metadata. Do not propose manual edits
   to generated output unless the repository explicitly defines it as editable.

Do not scan the whole repository when targeted inspection can answer the question.

## Clarify What Changes the Design

Ask only questions whose answers can change scope, behavior, data flow, public
contracts, risk, or acceptance criteria.

- Ask one focused question at a time when possible.
- Offer concrete options with their effects when a real choice exists.
- Recommend one option when repository evidence supports it.
- Do not ask the developer to choose an implementation detail that repository
  evidence can settle.
- Do not repeat a question the developer has already answered.
- If a safe assumption is cheap to reverse, state it and continue.
- If a missing answer would make the contract false or unsafe, stop and ask.

Topics to resolve only when relevant:

- current and desired observable behavior;
- users, roles, permissions, and failure behavior;
- data ownership, external contracts, and boundary mapping;
- compatibility requirements and consumers that cannot move in the same change;
- migration or rollout needs;
- race conditions, stale state, retries, and duplicate actions;
- accessibility, navigation, translation, and localization effects;
- required tests and other proof;
- explicit non-goals and nearby debt;
- nested repositories included by the task.

## Develop the Contract

Propose the simplest durable design that meets the known need.

- Prefer one coherent implementation over old and new paths running together.
- Preserve compatibility only for an identified contract or consumer.
- Keep the design within the task. Surface a larger refactor as a choice instead of
  silently adding it.
- Reuse suitable project dependencies and patterns after checking their actual
  capabilities.
- Reject speculative layers, configuration, and extension points.
- Include an end-to-end working slice before optional additions.
- Identify the owner of state, side effects, mapping, and validation.
- Note alternatives only when their tradeoffs could change the decision.

When a design moves existing behavior or data across an architectural boundary,
require the proposal to identify:

- why the current owner cannot keep that responsibility;
- the added calls, transfers, transformations, and failure paths;
- expected input size, result size, and execution frequency;
- consistency and contract semantics that must be preserved;
- repository evidence or measurements supporting the move.

Do not select a design merely because it moves more code into the application.

Apply repository-wide and path-specific instructions when assessing the design.
Do not copy those rules into the task contract unless a rule creates a concrete
decision or acceptance criterion for this task.

## Define Proof Before Implementation

For each behavior or risk, state how the implementation can prove it.

- Prefer observable acceptance criteria.
- Name the relevant test level and case-selection technique only when it helps:
  equivalence partitioning, boundary value analysis, decision table testing, state
  transition testing, basis path testing, loop testing, or regression testing.
- Add a regression test requirement for a reproducible bug.
- Include non-test checks such as formatting, linting, type checking, or a build
  only when they apply.
- Do not set a coverage target without a task-specific reason.
- Mark an item as a manual check only when useful automation is not practical.

## Present the Proposed Contract

Use this structure in the conversation:

```md
# Task: <short outcome>

## Goal
<The observable result and why it matters.>

## Verified Current Behavior
- <Repository-backed fact with file or symbol references.>

## Desired Behavior
- <Observable behavior.>

## Scope
- <Included work.>

## Non-goals
- <Explicit exclusion.>

## Design Decisions
- <Decision and short reason.>

## Acceptance Criteria
- [ ] <Observable pass/fail condition.>

## Validation Plan
- <Test or check and what it proves.>

## Risks and Open Questions
- <Remaining risk, assumption, or `None`.>
```

Keep sections short. Omit empty detail, but keep every heading so saved task files
have a stable shape.

## Reach Agreement

The developer owns the contract.

1. Present the proposed contract and call out any assumption that still matters.
2. Ask for approval or changes.
3. Update the contract from the developer's answer.
4. Do not start implementation, invoke the implementation agent, or alter product
   files after approval.

No reply or a vague positive reaction does not count as approval when an important
question remains open.

## Optional Persistence

After the developer approves the contract, ask whether to save it when the task is
large, spans sessions, changes several areas, or may need later review. Saving is
optional for a small task completed in one chat.

If the developer chooses to save:

1. Suggest a short kebab-case task name based on the outcome.
2. Use `$HOME/.config/opencode/scripts/workflow-task.sh` to create the task directory, record the
   branch and base commit, and update `.copilot/current-task.txt`.
3. Write only the approved contract and task metadata under the created `.copilot/`
   task directory.
4. Record the root repository and every nested repository explicitly included by the
   task, with its path and base commit.
5. Do not overwrite another task or reuse its directory.
6. Return the saved `task.md` path and stop.

If the script is missing, empty, or fails, do not recreate its behavior by guess.
Return the approved contract in chat, report that persistence is unavailable, and
leave the repository unchanged.

The saved `task.md` must include this metadata before the contract:

```yaml
---
status: approved
created-at: <ISO 8601 timestamp>
branch: <branch name>
repositories:
  root:
    path: .
    base-commit: <commit SHA>
  included: []
---
```

When nested repositories are included, use:

```yaml
repositories:
  root:
    path: .
    base-commit: <commit SHA>
  included:
    - name: <repository name>
      path: <relative path>
      base-commit: <commit SHA>
```

Do not invent metadata when Git cannot provide it. Report that persistence is
unavailable.

## Stop Conditions

The brainstorm ends when one of these outcomes occurs:

- the developer approves an unsaved contract;
- the approved contract is saved and its path is returned;
- a missing product decision blocks an accurate contract;
- repository evidence exposes a conflict that the developer must resolve.

End with the next available action, but do not launch it automatically.
