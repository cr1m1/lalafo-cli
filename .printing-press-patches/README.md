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
