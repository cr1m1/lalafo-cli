# Lalafo CLI

Undocumented REST API for lalafo.kg — Kyrgyz classifieds marketplace.
Covers ads search, category browsing, and ad detail viewing.
Base URL: https://api.lalafo.com
Required headers on all requests: Device, Language, Country-Id

Learn more at [Lalafo](https://lalafo.kg).

## Install

This CLI is local-only (not published to the Printing Press library). Build from source:

```bash
cd lalafo
go build -o lalafo-pp-cli ./cmd/lalafo-pp-cli
```

Move the binary somewhere on your `PATH`:

```bash
mv lalafo-pp-cli /usr/local/bin/
# or
mv lalafo-pp-cli ~/go/bin/
```

### MCP Server (Claude Desktop)

Build the MCP binary and configure Claude Desktop manually:

```bash
go build -o lalafo-pp-mcp ./cmd/lalafo-pp-mcp
```

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "lalafo": {
      "command": "/absolute/path/to/lalafo-pp-mcp"
    }
  }
}
```

## Quick Start

### 1. Install

See [Install](#install) above.

### 2. Verify Setup

```bash
lalafo-pp-cli doctor
```

This checks your configuration.

### 3. Try Your First Command

```bash
lalafo-pp-cli ads list
```

## Usage

Run `lalafo-pp-cli --help` for the full command reference and flag list.

## Paths & environment variables

This CLI separates local files into four path kinds:

| Kind | Contents |
|------|----------|
| `config` | User-editable settings such as `config.toml` and saved profiles |
| `data` | Durable local data such as `data.db` |
| `state` | Runtime state such as persisted queries, jobs, and `teach.log` |
| `cache` | Regenerable HTTP/cache files |

Each kind resolves independently. The ladder is:

1. Per-kind env var: `LALAFO_CONFIG_DIR`, `LALAFO_DATA_DIR`, `LALAFO_STATE_DIR`, or `LALAFO_CACHE_DIR`
2. `--home <dir>` for this invocation
3. `LALAFO_HOME` for a flat relocated root
4. XDG env vars: `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`
5. Platform defaults matching existing installs

For containers and agent sandboxes, prefer a single relocated root:

```bash
export LALAFO_HOME=/srv/lalafo
lalafo-pp-cli doctor
```

Under `LALAFO_HOME=/srv/lalafo`, the four dirs resolve to `/srv/lalafo/config`, `/srv/lalafo/data`, `/srv/lalafo/state`, and `/srv/lalafo/cache`.

MCP servers do not receive CLI flags from the host. Put relocation in the host `env` block:

```json
{
  "mcpServers": {
    "lalafo": {
      "command": "lalafo-pp-mcp",
      "env": {
        "LALAFO_HOME": "/srv/lalafo"
      }
    }
  }
}
```

Precedence matters in fleets: an ambient per-kind variable such as `LALAFO_DATA_DIR` overrides an explicit `--home` for that kind. Use `LALAFO_HOME` or the per-kind variables for durable fleet relocation; treat `--home` as the weaker per-invocation lever.

Relocation is one-way. Unsetting `LALAFO_HOME` does not move files back to platform defaults, and `doctor` cannot find files left under a former root. Move the files manually before unsetting relocation variables.

Existing installs keep working because the platform-default rung matches the legacy layout. Run `lalafo-pp-cli doctor --fail-on warn` to check path warnings in automation.

## Commands

### ads

Manage ads

- **`lalafo-pp-cli ads get`** - Retrieve full details for a single ad by ID.
- **`lalafo-pp-cli ads get-count`** - Returns the total number of active ads.
- **`lalafo-pp-cli ads list`** - Browse latest ads with optional category and user filters. Returns paginated results.
- **`lalafo-pp-cli ads search`** - Search ads by keyword query with optional category filter.

### categories

Manage categories

- **`lalafo-pp-cli categories`** - Returns the full hierarchical category tree with nested children.

### countries

Manage countries

- **`lalafo-pp-cli countries`** - Returns all countries where Lalafo operates.

### params

Manage params

- **`lalafo-pp-cli params <categoryId>`** - Returns available filter parameters (condition, model, year, etc.) for a given category.

### users

Manage users

- **`lalafo-pp-cli users <id>`** - Retrieve a user's public profile by ID.


## Output Formats

```bash
# Human-readable table (default in terminal, JSON when piped)
lalafo-pp-cli ads list

# JSON for scripting and agents
lalafo-pp-cli ads list --json

# Filter to specific fields
lalafo-pp-cli ads list --json --select id,name,status

# Dry run — show the request without sending
lalafo-pp-cli ads list --dry-run

# Agent mode — JSON + compact + no prompts in one flag
lalafo-pp-cli ads list --agent
```

## Agent Usage

This CLI is designed for AI agent consumption:

- **Non-interactive** - never prompts, every input is a flag
- **Pipeable** - `--json` output to stdout, errors to stderr
- **Filterable** - `--select id,name` returns only fields you need
- **Previewable** - `--dry-run` shows the request without sending
- **Read-only by default** - this CLI does not create, update, delete, publish, send, or mutate remote resources
- **Offline-friendly** - sync/search commands can use the local SQLite store when available
- **Agent-safe by default** - no colors or formatting unless `--human-friendly` is set

Exit codes: `0` success, `2` usage error, `3` not found, `5` API error, `7` rate limited, `10` config error.

## Health Check

```bash
lalafo-pp-cli doctor
```

Verifies configuration and connectivity to the API.

## Configuration

Run `lalafo-pp-cli doctor` to see the resolved config, data, state, and cache directories. The platform-default config path is `~/.config/lalafo-pp-cli/config.toml`; `--home`, `LALAFO_HOME`, and per-kind env vars can relocate it.

Static request headers can be configured under `headers`; per-command header overrides take precedence.

## Troubleshooting
**Not found errors (exit code 3)**
- Check the resource ID is correct
- Run the `list` command to see available items

---

Generated by [CLI Printing Press](https://github.com/mvanhorn/cli-printing-press)
