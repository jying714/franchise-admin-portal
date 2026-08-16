# Slice: Catalog Health v1

**Status:** Approved (Decision 15) — implement on `feat/pre-hardware-hq-polish`  
**Date:** 2026-08-15  
**Goal:** Self-serve franchise catalog integrity without exposing “schema” vocabulary to owners. Minimize support cost for onboarding.

## Non-goals (v1)

- Full 24h undo / time-travel merges  
- Automatic merge without human confirm  
- Renaming only (must rewrite ids)  
- Teaching owners the word “schema”

## UI copy

| Engineering | Owner UI |
|-------------|----------|
| schema issues | **Fixes needed** |
| schema editor | **Catalog health** / fix sheet |
| detectAllIssues | scan / health check |

## Surfaces

1. **Onboarding — Catalog health step**  
   - Required path before onboarding complete.  
   - Shows franchise-level + sample item issues.  
   - Primary actions: merge types, map refs, clear dead refs.

2. **Post-onboarding — HQ/Admin card**  
   - Persistent attention when count > 0.  
   - Opens same engine/sheet as onboarding.

3. **Menu item editor (HQ + Admin)**  
   - **No** standing schema card.  
   - Attention control when this item (or franchise blockers) has errors.  
   - Sheet: plain language + one primary action per issue.

## Severity

| Severity | Gate | Examples |
|----------|------|----------|
| Error | Block save/publish | Missing category; missing ingredient; required group empty; salad dressings type empty; duplicate types (franchise) |
| Warning | Allow publish | Price $0 (free item); soft/optional gaps |

## Duplicate ingredient types

1. Detect case-insensitive name/slug collisions (e.g. `sauces` / `Sauces`).  
2. User selects **survivor id**.  
3. **Union:** all ingredients on loser → `typeId = survivor`.  
4. Rewrite menu item refs that point at loser type id if any.  
5. **Hard-delete** loser type document after verify.  
6. Prevent future collisions: case-insensitive unique on create **and** rename.

## Normalize v1 pipeline

Single flow:

```text
Scan → Dry-run report → Confirm → Apply (batched) → Re-scan
```

Includes: type merge, orphan ingredients, broken menu refs.

## Scan cadence

- Auto on Menu Items entry + onboarding Catalog step (debounce/cache).  
- Manual **Scan again** on card/sheet.

## Success metric

≤ 5 taps: discover duplicate sauces → pick survivor → confirm dry-run → healthy → publish salad (zero support).

## Implementation order (suggested)

1. **A4** — Hide standing schema UI; attention control + sheet on menu item editor (+ Admin).  
2. **B1** — Duplicate type detection.  
3. **B2** — Merge apply (union + hard-delete) with dry-run.  
4. **B3** — Orphans + menu ref repair.  
5. **C** — Onboarding step + HQ/Admin health card wiring.  
6. Publish gate hooks for franchise-level errors.

## References

- Decision 15 in `docs/DECISIONS.md`  
- Decision 10 menu profiles / foundation types  
- Existing `MenuItemSchemaIssue` detectors (reuse/extend; don’t fork forever)
