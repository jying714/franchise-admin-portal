# Agent stress pack — 2026-07-25

Drain after pulling validator/router/SCOPE_CARD fixes and restarting orchestrator.

| ID | Mode | Expect |
|----|------|--------|
| 01 | A false-ban main Selector | `no_change` (not collection HARD BAN) |
| 02 | A false-ban design_tokens | `no_change` (not FP() HARD BAN on comments) |
| 03–05 | B escape purity | `no_change` single-line preferred |
| 06–07 | C invent traps | `no_change` or HARD BAN if static/onPrimary invented |
| 08 | D dual dirty | real dual BEFORE/AFTER: drop duplicate import + AGENT_STRESS_REMOVE line |
| 09–10 | E format | `no_change` only; reject mixed fences + No change needed |

Planted dirt for 08: `// AGENT_STRESS_REMOVE` on `onboarding_step_card.dart`. Feature setup already has duplicate `app_localizations` import.

Review: `/proposals full` + `/metrics`. Apply **only** 08 if both diffs are correct.
