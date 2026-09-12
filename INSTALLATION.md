# Installation and Integrations

This repository owns the wiring between OpenCode and its supporting tools. It does
not copy third-party installation instructions. Those instructions change over
time and belong to each upstream project.

> [!IMPORTANT]
> **Use upstream documentation for installation**
>
> Install or upgrade each component from the official source linked below. Then
> apply the repository-specific integration described in this document.

OpenCode is required. The supporting integrations are optional, but recommended
because they improve documentation lookup, context quality, and shell output.

| Integration | Main benefit | Required? |
| --- | --- | --- |
| [Context7](#context7) | Current, version-specific documentation. | No |
| [Headroom](#headroom) | Cleaner, smaller model context. | No, recommended |
| [RTK](#rtk) | More focused shell output. | No, recommended |

## OpenCode

### Why it is used

OpenCode is the runtime that discovers and executes this configuration's commands,
agents, skills, and instructions. The orchestration model is documented under
[Responsibility Layers](./WORKFLOW.md#responsibility-layers).

### Official installation

Install OpenCode and configure an LLM provider using the
[official OpenCode introduction and installation guide](https://opencode.ai/docs/).
Use that guide as the source of truth for supported platforms, package managers,
provider authentication, and upgrades.

### Connect this repository

Use this repository as the global OpenCode configuration directory at
`~/.config/opencode`. The tracked `opencode.example.jsonc` is a template, not the
active configuration.

Copy it to `opencode.jsonc`, replacing any OpenCode default, then customize it:

```bash
cp ~/.config/opencode/opencode.example.jsonc ~/.config/opencode/opencode.jsonc
```

> [!TIP]
> **Keep the instructions entry**
>
> Preserve `~/.config/opencode/instructions/*.md` in the local configuration so
> the shared instruction modules continue to load.

`opencode.jsonc` is git-ignored and belongs to the machine. Providers, models, and
per-agent bindings in that file are never committed. OpenCode prefers
`opencode.jsonc` over `opencode.json`.

Its main integration points are:

- `opencode.example.jsonc` for the config template (models, instructions, MCP).
- `commands/` for the manual `/task-*` entry points.
- `skills/` and `agents/` for workflow behavior.
- `scripts/` for persisted task and review state.
- `rules/` for local command permissions.
- `instructions/` and `AGENTS.md` for technical and repository-wide guidance.

Keep architecture, build commands, generated-file rules, and other instructions
specific to a target repository in that repository's own `AGENTS.md`. Restart the
OpenCode process after changing global configuration, dependencies, or plugins so
startup discovery runs again.

Official references:

- [OpenCode configuration](https://opencode.ai/docs/config/)
- [OpenCode commands](https://opencode.ai/docs/commands/)
- [OpenCode agents](https://opencode.ai/docs/agents/)
- [OpenCode agent skills](https://opencode.ai/docs/skills/)
- [OpenCode plugins](https://opencode.ai/docs/plugins/)

## OpenCode Zen

### Why it is used

OpenCode Zen is the OpenCode team's curated and benchmarked model gateway. It is
the workflow's default provider because OpenCode is an open-source project that
moves quickly, Zen selects and verifies models that work well as coding agents,
and its pricing keeps cache reads cheap. It also offers free models, which is why
the default `model` and `small_model` in `opencode.example.jsonc` are Zen free
models.

Free Zen models are temporary: the team rotates or deprecates them over time.
Keep those two ids current, or replace them with any provider and model you have
connected. The config is portable, does not assume a specific provider, and lets
you bind a different model and reasoning effort to each agent, as the commented
`agent` example in `opencode.example.jsonc` shows.

Zen is optional and has no lock-in: you can use it alongside your own provider
keys. Run `/connect` in the TUI and select OpenCode Zen, or use `/models` to pick
a model. See the official
[OpenCode Zen documentation](https://opencode.ai/docs/zen/).

## Context7

### Why it is used

The model's training data is not a reliable source of truth for the dependency
versions in every repository. A project may use a library released after the
model's training cutoff, or a much newer version whose APIs, configuration, and
runtime behavior have changed. Assuming that internal knowledge still applies can
therefore produce plausible but incorrect implementation choices.

Context7 gives agents access to current, version-specific documentation and code
examples through MCP. Agents use it when a task depends on a library, framework,
SDK, API, or configuration contract instead of assuming that remembered behavior
is still valid. Repository code, dependency versions, and tests remain the primary
local evidence. Context7 supplies the current upstream reference needed to
interpret them correctly.

Its free plan is sufficiently generous for the documentation lookups expected by
this workflow, making it a practical compromise without requiring the workflow to
depend entirely on model training data. Consult the official site for current plan
limits because those limits may change.

### Official installation and account setup

Follow the [official Context7 installation guide](https://github.com/upstash/context7#installation)
and obtain an API key from the [Context7 dashboard](https://context7.com/dashboard).
The API key is recommended for higher rate limits.

### Connect it to this workflow

No local Context7 server is required by this configuration. `opencode.example.jsonc`
registers `https://mcp.context7.com/mcp` as a remote MCP server and reads
`CONTEXT7_API_KEY` from the OpenCode process environment.

> [!NOTE]
> **The API key is recommended**
>
> Context7's official documentation recommends a free API key for higher rate
> limits. It is not described as a strict prerequisite, but this workflow should
> configure it rather than rely on undocumented anonymous limits.

`.env.example` documents the expected variable name. If the OpenCode launch method
loads a local environment file, copy that template to the ignored `.env` file and
replace the placeholder. Otherwise, expose the same variable through the shell or
service that starts OpenCode. Never commit the key or place it directly in your
local `opencode.jsonc`.

Use OpenCode's MCP management commands to confirm that `context7` is enabled and
reachable. See the [official OpenCode MCP documentation](https://opencode.ai/docs/mcp-servers/)
and [Context7 documentation](https://context7.com/docs).

## Saving Tokens

Headroom and RTK are equally important parts of the context pipeline. They improve
different parts of the same workflow:

- Headroom compresses model traffic and helps keep long conversations clean.
- RTK removes repetitive shell output before it enters the model context.

Together, they reduce token usage and keep the conversation focused on useful
information. Under a fixed provider quota, saved tokens remain available for more
work.

These tools improve the quality of long sessions as well as their cost. Neither
tool replaces source inspection or validation.

The sections below describe what each tool does and how it is wired into this
workflow.

### Headroom

Agent sessions accumulate file contents, tool results, logs, structured data, and
conversation history. Headroom runs locally in the model traffic path and
compresses that context before it reaches the model. In this workflow, its
native OpenCode plugin routes provider traffic through the local Headroom proxy
and exposes retrieval of the original content when more detail is needed.

> [!NOTE]
> **Headroom is optional, but recommended**
>
> It does not prevent OpenCode from working when disabled. In long sessions, it
> keeps the model context cleaner, delays compaction, and reduces token usage.

Expect Headroom to use noticeable RAM and CPU. Keeping a local compression
pipeline and its caches warm costs memory and compute. Modest hardware runs it
without trouble, but constrained machines should plan for it.

Headroom is modular. The official
[installation extras table](https://docs.headroomlabs.ai/docs/installation#extras)
separates the core package, including content routing, cache alignment, and
structured/JSON processing, from optional capabilities. Its `[all]` row shows the
full built-in runtime bundle, including the proxy, code and ML compression,
memory, relevance scoring, image compression, reports, OpenTelemetry export,
evaluations, voice, HTML extraction, MCP tools, and spreadsheet support. The same
table identifies integrations and optional backends that are not included in
`[all]`.
Use it as the source of truth when choosing installation features.

#### Official installation

Install and operate Headroom using its
[official documentation](https://docs.headroomlabs.ai/docs). The
[official OpenCode integration guide](https://docs.headroomlabs.ai/docs/opencode)
is the source of truth for supported proxy, wrapper, provider, plugin, and MCP
integration modes.

#### Connect it to this workflow

This setup uses Headroom's native OpenCode plugin with an independently managed
local proxy. The local plugin is deliberately ignored by Git and must exist at
`~/.config/opencode/plugins/headroom.js` on each configured machine:

```js
import { HeadroomPlugin } from "headroom-opencode";

export default async function plugin(input) {
  return HeadroomPlugin(input, {
    proxyUrl:
      process.env.HEADROOM_PROXY_URL ??
      "http://127.0.0.1:8787",
  });
}
```

The config directory must also have a local `package.json` dependency on
`headroom-opencode`, as required for imports from a local OpenCode plugin. Both the
local package manifest and its installed dependencies are ignored because they are
machine-managed integration state.

Make the proxy available at `HEADROOM_PROXY_URL`, or at the plugin's default
`http://127.0.0.1:8787`. Use Headroom's official diagnostics and statistics to
verify the proxy, then send an OpenCode request and confirm that the request count
increases. OpenCode loads local plugins at startup.

> [!IMPORTANT]
> **Keep the native plugin and provider setup separate**
>
> This setup uses the native `headroom-opencode` plugin. Keep your normal OpenCode
> provider and model configuration. The plugin intercepts that traffic in process
> and sends it through the proxy at `HEADROOM_PROXY_URL`.
>
> Do not add a `provider.headroom` block or replace your model with a
> `headroom/...` model unless you switch to `headroom wrap opencode` or its
> persistent provider installation. Those are alternative routing modes, not
> additional configuration for the native plugin.

Do not combine this persistent plugin path with `headroom wrap opencode` unless you
intend to replace the routing strategy. The wrapper manages runtime configuration
and other integration state itself.

Additional official references:

- [Headroom repository](https://github.com/headroomlabs-ai/headroom)
- [OpenCode local plugin loading and dependencies](https://opencode.ai/docs/plugins/#from-local-files)

### RTK

Some shell commands produce large, repetitive output. RTK intercepts the commands
it supports and returns a shorter representation that keeps results and failures
while dropping noise.

> [!NOTE]
> **RTK is optional, but recommended**
>
> RTK only affects supported shell commands. It does not change OpenCode's native
> file tools, and output reduction does not translate one-to-one into bill
> reduction.

The supported surface changes as RTK evolves. Use the official
[commands section](https://github.com/rtk-ai/rtk#commands) as the single command
reference rather than copying that list into this repository.

#### Official installation

Choose a supported installation method from the
[official RTK installation guide](https://github.com/rtk-ai/rtk/blob/develop/INSTALL.md).
Use the [official RTK README](https://github.com/rtk-ai/rtk) and its
[supported AI tools section](https://github.com/rtk-ai/rtk#supported-ai-tools) for
current OpenCode integration, limitations, upgrades, and telemetry behavior.

#### Connect it to this workflow

After installing RTK, apply the OpenCode integration documented upstream. This
installs RTK's OpenCode command-rewrite plugin. Restart OpenCode afterward so the
plugin is loaded.

`AGENTS.md` tells the workflow to use the integration only when its
command-specific filtering is useful and to inspect installed help before relying
on unfamiliar wrappers.

Use RTK's official version, integration inspection, and savings commands to verify
that the installed binary is the expected project and that OpenCode shell activity
is being tracked.

## Security and Local State

- Keep `.env` and all real credentials out of Git.
- Keep machine-specific dependencies and ignored plugins reproducible from this
  document and their upstream sources.
- Review third-party release notes before upgrading integrations.
- Restart only the affected process after configuration changes. A system-wide
  restart is not required.
