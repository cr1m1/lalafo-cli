# Printing Press Patches

These patches were applied to the generated CLI tree and must be carried forward
on reprint. Each entry records the intent so a fresh `cli-printing-press` run
can replay or upstream the fix.

## 2026-07-03: Bug fix batch (10 fixes)

### Patch 1: FTS hash collision → use actual SQLite rowids
- **Files**: `internal/store/store.go` (upsertGenericResourceTx, rebuildResourcesFTS),
  `internal/store/schema_version_test.go`
- **Why**: FNV-64a hashes used as FTS5 rowids have birthday-paradox collision risk.
  At ~65K resources, collisions silently corrupt the search index. Using the
  resources table's own SQLite rowid is guaranteed unique.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 2: Hardcoded locale headers → configurable defaults
- **File**: `internal/client/client.go` (doInternal)
- **Why**: `Language: ru` and `Country-Id: 12` were unconditionally set on every
  request. Now they are defaults that config `Headers` or per-endpoint overrides
  can replace. Users in other Lalafo countries get correct results.
- **Upstream?**: No — Lalafo-specific.

### Patch 3: CSV escaping — add carriage return
- **File**: `internal/cli/helpers.go` (printCSV)
- **Why**: RFC 4180 requires quoting fields containing `\r`. The original check
  only covered `,`, `"`, and `\n`.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 4: Card display — guard empty second field
- **File**: `internal/cli/helpers.go` (printAutoCards)
- **Why**: When the second priority field has an empty or null value, the card
  header showed a trailing "— " with nothing after it.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 5: Double time.Now() → capture once
- **File**: `internal/store/store.go` (upsertGenericResourceTx)
- **Why**: `synced_at` and `updated_at` could differ by microseconds under load.
  Now captured once before the SQL statement.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 6: Silent cache write errors → log to stderr
- **File**: `internal/client/client.go` (writeCache)
- **Why**: `os.MkdirAll` and `os.WriteFile` errors were silently discarded.
  Now logged to stderr for debuggability.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 7: Duration parser — add month support
- **File**: `internal/cli/sync.go` (parseSinceDuration)
- **Why**: `m` = minutes is commonly confused with months. Added `M` for months
  (30 days) and updated the error message to clarify.
- **Upstream?**: Partially — the regex and switch are generated, but the month
  addition is a Lalafo-specific enhancement.

### Patch 8: Dead code — redundant length check
- **File**: `internal/cli/ads_get.go`
- **Why**: `len(args) < 1` was already guarded by `len(args) == 0` above.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 9: Card field ordering — union across all items
- **File**: `internal/cli/helpers.go` (printAutoCards)
- **Why**: Field ordering was derived from only `items[0]`. Fields present in
  later items but absent in the first were silently omitted from all cards.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 10: Relative path fallback → temp dir
- **File**: `internal/cli/helpers.go` (defaultDBPath)
- **Why**: Ultimate fallback returned `"data.db"` (relative to CWD). Now uses
  `os.TempDir()` which is always absolute.
- **Upstream?**: Yes — systemic generator pattern.

## 2026-07-10: Product-review fix batch (build blockers + core UX)

Driven by a use-the-product review (flow-20260710-1727-9c3b780a). The tree could
not be built as documented and the core browse/export UX was silently broken.

### Patch 11: Missing `package main` entrypoints
- **Files**: `cmd/lalafo-pp-cli/main.go`, `cmd/lalafo-pp-mcp/main.go` (new)
- **Why**: No `package main` existed anywhere in the tree, so the documented
  build (`go build ./cmd/lalafo-pp-cli` / `./cmd/lalafo-pp-mcp`), the `Makefile`,
  and `.goreleaser.yaml` all failed — neither binary could be produced. The CLI
  main defers to `cli.Execute()` + `cli.ExitCode()`; the MCP main wires
  `server.NewMCPServer` → `mcp.RegisterTools` → `server.ServeStdio` and carries a
  `main.version` var for the goreleaser ldflag.
- **Upstream?**: Yes — the generator must emit both mains. Systemic gap.

### Patch 12: `.gitignore` swallowed the entrypoint dirs
- **File**: `.gitignore`
- **Why**: Unanchored binary patterns (`lalafo-pp-cli`, `lalafo-pp-mcp`) also
  matched the new `cmd/lalafo-pp-cli/` and `cmd/lalafo-pp-mcp/` source dirs, so
  the mains from Patch 11 were untracked. Anchored to `/lalafo-pp-cli`,
  `/lalafo-pp-mcp`, `/lalafo` so only root build artifacts are ignored.
- **Upstream?**: Yes — must ship with the entrypoint generator fix.

### Patch 13: Envelope-aware CSV / plain / table output
- **File**: `internal/cli/helpers.go` (printCSV, printPlain, printOutput; new
  `unwrapListEnvelope`, `listItemsForTabularOutput`), `internal/cli/ads_list.go`,
  `internal/cli/ads_search.go`
- **Why**: The lalafo collection endpoints return an `{items:[...], _meta, _links}`
  envelope. `--csv`/`--plain` and the terminal table all only handled a
  *top-level array*, so `ads list`/`ads search` silently dumped raw JSON instead
  of rows/tables — breaking the export + browse workflow that is the whole point
  of a classifieds CLI. Now the formatters unwrap the envelope (reusing
  `extractPaginatedItems`, the same locator the pagination/compact paths use)
  before rendering. The provenance "N results" line was likewise envelope-blind
  (always "0 results" above a full table); `envelopeAwareItemCount` fixes it.
- **Upstream?**: Yes — systemic generator pattern (envelope-unaware formatters).

### Patch 14: Nested cells JSON-encoded, not Go `map[...]`
- **File**: `internal/cli/helpers.go` (new `cellScalarString`; printCSV,
  plainCellValue)
- **Why**: `--csv`/`--plain` rendered non-scalar fields (e.g. a country's
  `capital` object, an ad's `images`) via `fmt.Sprintf("%v")`, leaking Go's
  `map[...]`/`[...]` form and making the output unparseable. Non-scalars are now
  JSON-encoded.
- **Upstream?**: Yes — systemic generator pattern.

### Patch 15: Seed the `which` capability index
- **File**: `internal/cli/which.go` (whichIndex)
- **Why**: `whichIndex` shipped empty, so the advertised runtime-discovery
  command (`which "<capability>"`, the primary mechanism AGENTS.md tells agents to
  use) returned "no curated capability index" for every query. Seeded with the
  hero capabilities from the SKILL.md Command Reference; every entry resolves in
  the Cobra tree (guarded by `TestWhichIndex_ExistsAndIsWellFormed`).
- **Upstream?**: Yes — the generator should seed the index from the verified
  feature list.

### Patch 16: `ads get-count` spurious cache warning
- **Files**: `internal/cli/data_source.go` (new `noCacheResourceType` +
  `writeThroughCache` guard), `internal/cli/ads_get-count.go`
- **Why**: The scalar count response (`{ads_count, feed-name, feed-id}`) was
  routed through the "ads" write-through cache, upserted as an ID-less row, and
  printed `warning: 1/1 ads items returned but not cached locally ...` on every
  call. The count read now opts out of caching via a `noCacheResourceType`
  sentinel that makes write-through a no-op (respecting the #1439 single-object
  cache behavior for real detail responses).
- **Upstream?**: Yes — count/aggregate reads should not auto-cache.

### Patch 17: Numeric `ads get` example
- **File**: `internal/cli/ads_get.go`
- **Why**: The `--help` example used a UUID
  (`550e8400-e29b-41d4-a716-446655440000`); lalafo ad IDs are numeric. Uses
  `114121330` (matching MANUAL.md).
- **Upstream?**: Lalafo-specific — the generator's example placeholder should use
  the API's real ID shape.

## 2026-07-10: Amend node — detail-fetch provenance count

### Patch 18: `ads get` / `ads get-count` print "0 results" for a successful fetch
- **Files**: `internal/cli/helpers.go` (new `detailResponseItemCount`),
  `internal/cli/ads_get.go`, `internal/cli/ads_get-count.go`,
  `internal/cli/helpers_format_test.go` (`TestDetailResponseItemCount`)
- **Why**: The single-object detail commands counted results with the inline
  pattern `var countItems []json.RawMessage; json.Unmarshal(data, &countItems);
  printProvenance(cmd, len(countItems), prov)`. A single detail object (or the
  scalar count aggregate) never unmarshals into a `[]json.RawMessage`, so the
  count was **always 0** — a successful `ads get <id>` printed "0 results (live)"
  directly above the ad it just fetched, and `ads get-count` did the same above
  the count. This is the *inline* form Patch 13 replaced in `ads_list.go` /
  `ads_search.go` with `envelopeAwareItemCount`, but left in the detail commands.
  Now both call `detailResponseItemCount`, a sibling that reports array length
  for a bare array, inner row count for a list envelope, `1` for a single
  non-empty object, and `0` for JSON null / an empty object / an empty
  collection.
- **Upstream?**: Yes — same systemic generator pattern as Patch 13 (the
  detail-command provenance counter should be envelope/object aware, not a bare
  `[]json.RawMessage` length).
