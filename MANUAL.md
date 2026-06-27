# Lalafo CLI & MCP Usage Manual

CLI and MCP server for the [lalafo.kg](https://lalafo.kg) classifieds marketplace API.
Search ads, browse categories, view listings — all from terminal or AI agents.

**API**: `api.lalafo.com` (undocumented REST v3, no auth required)
**Markets**: Kyrgyzstan (KG), Azerbaijan (AZ), Serbia (RS), Poland (PL)
**Active listings**: 1,000,000+

---

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [CLI Commands](#cli-commands)
  - [ads list](#ads-list)
  - [ads search](#ads-search)
  - [ads get](#ads-get)
  - [ads get-count](#ads-get-count)
  - [categories](#categories)
  - [params](#params)
  - [users](#users)
  - [countries](#countries)
  - [search](#search)
  - [sync](#sync)
  - [doctor](#doctor)
  - [profile](#profile)
  - [workflow](#workflow)
- [Output Formats](#output-formats)
- [Pagination](#pagination)
- [Configuration](#configuration)
- [MCP Server](#mcp-server)
  - [Setup](#mcp-setup)
  - [Available Tools](#mcp-tools)
  - [Tool Reference](#mcp-tool-reference)
- [Cookbook](#cookbook)
- [Exit Codes](#exit-codes)

---

## Install

Build from source (requires Go 1.20+):

```bash
cd lalafo
go build -o lalafo-pp-cli ./cmd/lalafo-pp-cli
```

Add to PATH:

```bash
# Option A: copy to go bin
cp lalafo-pp-cli ~/go/bin/

# Option B: symlink
ln -s $(pwd)/lalafo-pp-cli /usr/local/bin/lalafo-pp-cli

# Option C: sudo copy
sudo cp lalafo-pp-cli /usr/local/bin/
```

Verify:

```bash
lalafo-pp-cli doctor
```

---

## Quick Start

```bash
# Check setup
lalafo-pp-cli doctor

# Search for Toyota Camry
lalafo-pp-cli ads search --q "Toyota Camry" --json

# Browse latest ads
lalafo-pp-cli ads list --per-page 5

# View specific ad
lalafo-pp-cli ads get 114121330

# Browse categories
lalafo-pp-cli categories --json

# Get filters for Toyota category (ID: 1608)
lalafo-pp-cli params 1608

# View seller profile
lalafo-pp-cli users 17511713
```

---

## CLI Commands

### ads list

Browse latest ads with optional filters.

```bash
lalafo-pp-cli ads list [flags]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--per-page` | int | 20 | Results per page |
| `--page` | string | 1 | Page number |
| `--category-id` | string | | Filter by category ID |
| `--user-id` | string | | Filter by user ID |
| `--all` | bool | false | Fetch all pages |

**Examples:**

```bash
# Latest 10 ads
lalafo-pp-cli ads list --per-page 10

# Ads in Toyota category
lalafo-pp-cli ads list --category-id 1608 --per-page 5

# All ads from a specific seller
lalafo-pp-cli ads list --user-id 17511713

# JSON with selected fields
lalafo-pp-cli ads list --per-page 5 --json --select id,title,price,currency,city
```

---

### ads search

Search ads by keyword with optional category filter.

```bash
lalafo-pp-cli ads search --q <query> [flags]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--q` | string | *required* | Search query |
| `--per-page` | int | 20 | Results per page |
| `--page` | string | 1 | Page number |
| `--category-id` | string | | Filter by category ID |
| `--all` | bool | false | Fetch all pages |

**Examples:**

```bash
# Search for iPhones
lalafo-pp-cli ads search --q "iPhone 15"

# Search Toyota Camry, JSON output with key fields only
lalafo-pp-cli ads search --q "Toyota Camry" --json --select id,title,price,currency,city

# Search within Electronics category
lalafo-pp-cli ads search --q "laptop" --category-id 1555 --per-page 10

# Pipe to jq
lalafo-pp-cli ads search --q "квартира Бишкек" --json | jq '.results.items[].title'
```

---

### ads get

Get full details for a single ad by ID.

```bash
lalafo-pp-cli ads get <id> [flags]
```

**Examples:**

```bash
# View ad details
lalafo-pp-cli ads get 114121330

# JSON output
lalafo-pp-cli ads get 114121330 --json

# Select specific fields
lalafo-pp-cli ads get 114121330 --json --select title,price,currency,city,mobile,description
```

**Response includes:** title, description, price, currency, images, params (filters like condition, model, year), seller info, phone number, location (lat/lng), view count, favorites count, timestamps.

---

### ads get-count

Get total number of active ads on the platform.

```bash
lalafo-pp-cli ads get-count
```

**Example output:**
```json
{
  "ads_count": "1082785",
  "feed-name": "ad-count",
  "feed-id": 2001
}
```

---

### categories

Get the full hierarchical category tree.

```bash
lalafo-pp-cli categories [flags]
```

**Examples:**

```bash
# Full tree
lalafo-pp-cli categories --json

# Pipe to jq — top-level categories with ad counts
lalafo-pp-cli categories --json | jq '.results[] | {id, name, ads_count}'
```

**Key category IDs (Kyrgyzstan):**

| ID | Category | Ads |
|----|----------|-----|
| 1501 | Транспорт (Transport) | 340k+ |
| 1502 | Продажа авто (Car Sales) | 54k+ |
| 1608 | Toyota | 7k+ |
| 1555 | Электроника (Electronics) | — |
| 2001 | Недвижимость (Real Estate) | — |
| 2045 | Услуги (Services) | — |

---

### params

Get available filter parameters for a category. Useful for understanding what filters exist before searching.

```bash
lalafo-pp-cli params <categoryId> [flags]
```

**Examples:**

```bash
# Get filters for Toyota category
lalafo-pp-cli params 1608 --json

# Pipe to jq — list filter names and types
lalafo-pp-cli params 1608 --json | jq '.results[] | {name, kind, alias}'
```

**Typical params for cars (category 1608):**
- Состояние (Condition): new, used
- Модель (Model): Camry, Corolla, Land Cruiser, etc.
- Год (Year): range
- Объём двигателя (Engine volume): range
- Тип топлива (Fuel type): бензин, дизель, газ, электро
- Коробка передач (Transmission): автомат, механика
- Привод (Drive): передний, задний, полный

---

### users

Get a user's public profile.

```bash
lalafo-pp-cli users <id> [flags]
```

**Examples:**

```bash
# View seller profile
lalafo-pp-cli users 17511713 --json

# Selected fields
lalafo-pp-cli users 17511713 --json --select username,response_rate,response_time,verify
```

**Response includes:** username, avatar, registration date, response rate (%), response time (seconds), verification status, pro status.

---

### countries

List all countries where Lalafo operates.

```bash
lalafo-pp-cli countries [flags]
```

**Countries:**

| ID | Country | Code | Domain | Currency |
|----|---------|------|--------|----------|
| 12 | Кыргызстан | KG | lalafo.kg | KGS |
| 13 | Азербайджан | AZ | lalafo.az | AZN |
| 11 | Сербия | RS | lalafo.rs | — |
| 14 | Польша | PL | lalafo.pl | — |

---

### search

Full-text search. Uses API endpoint by default, falls back to local SQLite if synced.

```bash
lalafo-pp-cli search <query> [flags]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--data-source` | string | auto | `auto`, `live`, or `local` |
| `--limit` | int | 50 | Max results |
| `--type` | string | | Filter by resource type |

**Examples:**

```bash
# Search via API
lalafo-pp-cli search "квартира"

# Local search only (requires prior sync)
lalafo-pp-cli search "Toyota" --data-source local

# JSON with limit
lalafo-pp-cli search "iPhone" --json --limit 10
```

---

### sync

Sync API data to local SQLite for offline search.

```bash
lalafo-pp-cli sync [flags]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--full` | bool | false | Full resync, ignore checkpoint |
| `--concurrency` | int | 4 | Parallel workers |
| `--max-pages` | int | 0 | Max pages per resource (0=unlimited) |
| `--latest-only` | bool | false | Refresh head only, no backfill |

**Examples:**

```bash
# Sync all data
lalafo-pp-cli sync

# Quick refresh — latest page only
lalafo-pp-cli sync --latest-only

# Full resync
lalafo-pp-cli sync --full
```

---

### doctor

Health check — verifies config, connectivity, local database status.

```bash
lalafo-pp-cli doctor
```

---

### profile

Save and reuse flag presets.

```bash
# Save current flags as profile
lalafo-pp-cli ads list --per-page 50 --json -- profile save my-defaults

# List profiles
lalafo-pp-cli profile list

# Use profile
lalafo-pp-cli ads list --profile my-defaults

# Delete profile
lalafo-pp-cli profile delete my-defaults
```

---

### workflow

Compound operations.

```bash
# Archive all data locally
lalafo-pp-cli workflow archive

# Check archive status
lalafo-pp-cli workflow status
```

---

## Output Formats

Every command supports multiple output modes:

```bash
# JSON (default when piped)
lalafo-pp-cli ads list --json

# Select specific fields
lalafo-pp-cli ads list --json --select id,title,price,currency

# Compact (minimal fields for agents)
lalafo-pp-cli ads list --compact

# CSV
lalafo-pp-cli ads list --csv

# Plain tab-separated
lalafo-pp-cli ads list --plain

# Quiet — one value per line
lalafo-pp-cli ads list --quiet

# Agent mode — JSON + compact + no prompts + no color
lalafo-pp-cli ads list --agent

# Dry run — show HTTP request without sending
lalafo-pp-cli ads list --dry-run
```

### JSON Envelope

JSON output wraps results in a provenance envelope:

```json
{
  "meta": {
    "source": "live"
  },
  "results": { ... }
}
```

`meta.source` is `"live"` (API) or `"local"` (SQLite).

---

## Pagination

List and search commands return paginated results.

```bash
# Page 1, 20 per page (defaults)
lalafo-pp-cli ads list

# Page 2, 50 per page
lalafo-pp-cli ads list --page 2 --per-page 50

# Fetch ALL pages (caution: can be slow for large result sets)
lalafo-pp-cli ads list --all
```

Response includes pagination metadata:

```json
{
  "_meta": {
    "totalCount": 10000,
    "pageCount": 500,
    "currentPage": 1,
    "perPage": 20
  },
  "_links": {
    "next": { "href": "/v3/ads?page=2&per-page=20" }
  }
}
```

---

## Configuration

Config file: `~/.config/lalafo-pp-cli/config.toml`
Data (SQLite): `~/.local/share/lalafo-pp-cli/data.db`
State: `~/.local/state/lalafo-pp-cli/`
Cache: `~/.cache/lalafo-pp-cli/`

### Environment Variables

| Variable | Description |
|----------|-------------|
| `LALAFO_HOME` | Relocate all dirs under one root |
| `LALAFO_CONFIG_DIR` | Override config directory |
| `LALAFO_DATA_DIR` | Override data directory |
| `LALAFO_STATE_DIR` | Override state directory |
| `LALAFO_CACHE_DIR` | Override cache directory |

### Relocate everything (containers/CI):

```bash
export LALAFO_HOME=/srv/lalafo
lalafo-pp-cli doctor
# Dirs: /srv/lalafo/config, /srv/lalafo/data, /srv/lalafo/state, /srv/lalafo/cache
```

---

## MCP Server

The CLI ships with an MCP (Model Context Protocol) server for AI agent integration.

### MCP Setup

Build the MCP server:

```bash
cd lalafo
go build -o lalafo-pp-mcp ./cmd/lalafo-pp-mcp
```

#### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "lalafo": {
      "command": "/absolute/path/to/lalafo-pp-mcp"
    }
  }
}
```

#### Claude Code

Add to your MCP config:

```json
{
  "mcpServers": {
    "lalafo": {
      "command": "/absolute/path/to/lalafo-pp-mcp",
      "args": []
    }
  }
}
```

#### Cursor / VS Code

Add to `.cursor/mcp.json` or VS Code MCP settings:

```json
{
  "mcpServers": {
    "lalafo": {
      "command": "/absolute/path/to/lalafo-pp-mcp"
    }
  }
}
```

#### With relocated data directory

```json
{
  "mcpServers": {
    "lalafo": {
      "command": "/absolute/path/to/lalafo-pp-mcp",
      "env": {
        "LALAFO_HOME": "/srv/lalafo"
      }
    }
  }
}
```

### MCP Tools

The MCP server exposes 8 read-only tools:

| Tool | Description |
|------|-------------|
| `ads_get` | Get single ad by ID |
| `ads_get-count` | Total active ads count |
| `ads_list` | Browse ads with filters |
| `ads_search` | Search ads by keyword |
| `categories_get-category-tree` | Full category hierarchy |
| `countries_list` | List supported countries |
| `params_get-category` | Filter params for a category |
| `users_get` | Get user profile by ID |

All tools are read-only. No authentication required.

### MCP Tool Reference

#### ads_search

Search ads by keyword.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | yes | Search query |
| `per-page` | int | no | Results per page (default 20) |
| `page` | int | no | Page number |
| `category_id` | int | no | Filter by category ID |

**Agent prompt example:**
> "Search lalafo for Toyota Camry under $15,000"

#### ads_list

Browse latest ads.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `per-page` | int | no | Results per page (default 20) |
| `page` | int | no | Page number |
| `category_id` | int | no | Filter by category ID |
| `user_id` | int | no | Filter by user ID |

**Agent prompt example:**
> "Show me the latest 5 car listings on lalafo"

#### ads_get

Get full ad details.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | int | yes | Ad ID |

**Agent prompt example:**
> "Get details for lalafo ad 114121330"

#### ads_get-count

No parameters. Returns total active ad count.

#### categories_get-category-tree

No parameters. Returns full nested category tree.

**Agent prompt example:**
> "What categories are available on lalafo?"

#### params_get-category

Get filter options for a category.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `categoryId` | int | yes | Category ID |

**Agent prompt example:**
> "What filters can I use when searching Toyota cars on lalafo?" (use categoryId 1608)

#### countries_list

No parameters. Returns all Lalafo countries.

#### users_get

Get user profile.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | int | yes | User ID |

---

## Cookbook

### Find cheapest Toyota Camry

```bash
lalafo-pp-cli ads search --q "Toyota Camry" --per-page 100 --json \
  | jq '[.results.items[] | select(.currency == "USD")] | sort_by(.price) | .[:5] | .[] | {title, price, city}'
```

### List all top-level categories with ad counts

```bash
lalafo-pp-cli categories --json \
  | jq '.results[] | {id, name, ads_count}' 
```

### Get Toyota models available as filters

```bash
lalafo-pp-cli params 1608 --json \
  | jq '.results[] | select(.alias == "model_1") | .values[].value'
```

### Export ads to CSV

```bash
lalafo-pp-cli ads search --q "квартира" --per-page 50 --csv > apartments.csv
```

### Check a seller's profile before buying

```bash
# Get user ID from an ad
lalafo-pp-cli ads get 114121330 --json --select user_id

# Then check their profile
lalafo-pp-cli users 17511713 --json --select username,response_rate,verify
```

### Sync for offline search

```bash
# Initial sync
lalafo-pp-cli sync

# Search locally (fast, no network)
lalafo-pp-cli search "iPhone" --data-source local

# Refresh
lalafo-pp-cli sync --latest-only
```

### Script: monitor new ads in a category

```bash
#!/bin/bash
while true; do
  lalafo-pp-cli ads list --category-id 1608 --per-page 5 --json \
    --select id,title,price,currency \
    | jq -c '.results.items[]'
  sleep 300  # check every 5 minutes
done
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 2 | Usage error (bad flags, missing args) |
| 3 | Not found |
| 5 | API error |
| 7 | Rate limited |
| 10 | Config error |

---

## API Details

- **Base URL**: `https://api.lalafo.com`
- **Version**: v3
- **Auth**: None (public read-only)
- **Rate limits**: Unknown (undocumented API) — use `--rate-limit` flag if needed
- **Required headers** (sent automatically by CLI):
  - `Device: web`
  - `Language: ru`
  - `Country-Id: 12` (Kyrgyzstan)

To change country or language, edit `~/.config/lalafo-pp-cli/config.toml`.

---

Generated by [CLI Printing Press](https://github.com/mvanhorn/cli-printing-press)
