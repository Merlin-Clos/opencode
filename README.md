# OpenCode Workflow Configuration

This repository provides a global OpenCode workflow with reusable technical
instructions and optional local integrations.

> [!NOTE]
> **This repository defines the workflow, not the application**
>
> Project architecture, business rules, commands, and validation requirements
> belong in the target repository's own `AGENTS.md`.

## Start Here

1. Read [the workflow](./WORKFLOW.md) to understand the lifecycle.
2. Follow [the installation guide](./INSTALLATION.md) to connect this repository.
3. Copy `opencode.example.jsonc` to your local `opencode.jsonc`.
4. Start a task with `/task-brainstorm`.

## Task Commands

| Command | Purpose |
| --- | --- |
| `/task-brainstorm` | Frame a request and prepare an approved task contract. |
| `/task-implement` | Implement and validate a direct request or saved task. |
| `/task-review` | Run an incremental multi-agent review for a saved task. |
| `/task-fix-review` | Record decisions and correct selected findings. |

The internal `task-development-loop` skill powers the implementation workflows.
It is not a manual command.

## Responsibility Layers

The workflow, reusable `instructions/`, and repository-owned `AGENTS.md` files
have separate responsibilities. See
[`WORKFLOW.md`](./WORKFLOW.md#responsibility-layers) for the complete model and
examples.

## Repository Map

| Path | Responsibility |
| --- | --- |
| `commands/` | Manual `/task-*` entry points. |
| `skills/` | Discovery, implementation, review, and correction workflows. |
| `agents/` | Specialized task and review roles. |
| `scripts/` | Persisted task and incremental review state. |
| `instructions/` | Language, framework, test, and generated-code guidance. |
| `rules/` | Local command permission rules. |
| `opencode.example.jsonc` | Portable configuration template. |
| `AGENTS.md` | Repository-wide implementation rules. |
| `WORKFLOW.md` | Lifecycle, persistence, review, and nested-repository behavior. |
| `INSTALLATION.md` | Official setup sources and local integration instructions. |

## Optional Integrations

[Context7](./INSTALLATION.md#context7), [Headroom](./INSTALLATION.md#headroom),
and [RTK](./INSTALLATION.md#rtk) improve documentation lookup, context quality,
and shell output respectively. They are not required to start OpenCode.

See the [RTK usage results](./RTK.md) for anonymized measurements from four
machines and three users.
