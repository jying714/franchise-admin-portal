# Multi-file apply stress — 2026-07-25

Requires: pull + **restart orchestrator** (proposal_store multi-file parse/apply).

| ID | Purpose | Expect |
|----|---------|--------|
| 01 | Dual dirty apply | Real dual BEFORE/AFTER; `/approve confirm` applies **both** files |
| 02 | Single-file control | `no_change` |
| 03 | Escape after multi-file | `no_change` |

Planted dirt for 01:
- feature_setup: duplicate `app_localizations` import
- step_card: `// AGENT_STRESS_REMOVE: multi-file apply proof...`

**Pass criteria for 01 apply message:**
`Applied 2 file(s)` mentioning both paths.

If only one file applies → multi-file parse/apply still broken.
