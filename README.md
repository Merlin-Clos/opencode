# OpenCode Workflow Configuration

This repository centralizes a global OpenCode task workflow, reusable technical
instructions, and optional local integrations.

## Why This Repository Exists

A centralized setup helps to:

- make task framing, implementation, validation, and review consistent;
- keep automated workflow behavior and developer decisions visible;
- reuse language, framework, and test guidance across repositories;
- preserve development knowledge in versioned files.

Read the detailed [task workflow](./WORKFLOW.md) and the
[installation and integration guide](./INSTALLATION.md).

## Task Commands

Use these commands as the manual workflow entry points in OpenCode:

- `/task-brainstorm` frames a request and prepares an approved task contract.
- `/task-implement` implements a direct request or the current saved task.
- `/task-review` runs the incremental multi-agent review workflow for a saved task.
- `/task-fix-review` records developer decisions and corrects selected findings.

The internal `task-development-loop` skill is loaded by implementation workflows
and is not a manual command.

## Responsibility Layers

The workflow, reusable `instructions/`, and repository-owned `AGENTS.md` files
have separate responsibilities. See
[`WORKFLOW.md`](./WORKFLOW.md#responsibility-layers) for the complete model and
examples.

## Repository Map

- `commands/`: manual `/task-*` entry points.
- `skills/`: discovery, implementation, review, and correction workflows.
- `agents/`: specialized task and review roles.
- `scripts/`: persisted task and incremental review state operations.
- `instructions/`: language, framework, test, and generated-code guidance.
- `rules/`: local command permission rules.
- `opencode.json`: global models, instructions, server, and MCP settings.
- `AGENTS.md`: repository-wide implementation rules.
- `WORKFLOW.md`: lifecycle, persistence, review, and nested-repository behavior.
- `INSTALLATION.md`: official setup sources and local integration instructions.

## Optional Integrations

[Context7](./INSTALLATION.md#context7),
[Headroom](./INSTALLATION.md#headroom), and
[RTK](./INSTALLATION.md#rtk).
