# OpenCode Configuration

Personal OpenCode configuration: agents, commands, instructions, rules, and
skills.

## Requirements

- OpenCode
- Python 3.10+ and `uv` for Headroom
- RTK
- A Context7 API key

## Installation

### Headroom

Install the Headroom CLI as an isolated `uv` tool:

```bash
uv tool install --python 3.13 "headroom-ai[all]"
headroom --version
```

Start the local optimization proxy and verify it:

```bash
headroom proxy --port 8787
headroom doctor
```

Use `headroom dashboard` while the proxy is running. For a persistent
deployment, use the official `headroom install apply` workflow instead of
committing service files or runtime state to this repository.

### RTK

Install the Rust Token Killer CLI using the official installer:

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
rtk --version
rtk gain
```

Enable the optional OpenCode integration:

```bash
rtk init -g --opencode
```

RTK filters supported shell-command output. Check the installed version before
using a wrapper:

```bash
rtk --help
rtk <command> --help
```

`rtk proxy <command> ...` runs a command without output filtering but tracks
usage. It is not a network proxy. `rtk run -c '...'` runs a raw shell command
without filtering or usage tracking.

### Context7

This configuration uses Context7 as a remote MCP server. No local Context7
binary is required. Create an API key at <https://context7.com/dashboard>, then
store it in the ignored `.env` file:

```bash
cp .env.example .env
```

Set the value in `.env`:

```dotenv
CONTEXT7_API_KEY=your_api_key_here
```

The MCP endpoint is configured in `opencode.json` and reads
`CONTEXT7_API_KEY` from the environment. Never commit `.env` or an actual API
key. Restart OpenCode after changing configuration or environment values.

## Verification

```bash
opencode --version
headroom doctor
rtk --version
rtk gain
```

## References

- [Headroom documentation](https://headroom-docs.vercel.app/docs)
- [RTK installation guide](https://github.com/rtk-ai/rtk/blob/develop/INSTALL.md)
- [Context7 documentation](https://context7.com/docs)
