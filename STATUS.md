# STATUS.md — Live Project Snapshot

**Last Updated**: August 17, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`feat/pre-hardware-hq-polish`** (active) · soft-release **`main`** includes salad profile merge  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | **On main** |
| Salad profile + dressings + optional overrides | **Merged to main** (2026-08-15) |
| HQ menu editor layout + type-first ingredient picker | **On main** |
| Catalog health / schema UX productization | **In progress on branch** — foundation health + item Fixes sheet |
| POS print/drawer interfaces (software) | **Mock ready** — `PrintService` + `DrawerService` |
| Station hardware · iOS | **Waiting** (printer/drawer inbound; iOS delayed) |
| Soft parallel / hard Owner.com cutover | Soft parallel OK; hard cutover after sign-off + hardware |
| Portal invite email (SendGrid) | Wired; blocked on credits |

---

## Decision 15 — Catalog Health (locked 2026-08-15)

Authority: `docs/DECISIONS.md` §15, `docs/slices/catalog-health-v1.md`

| Rule | Choice |
|------|--------|
| UI language | **Catalog health** / **Fixes needed** (not “schema”) |
| Surfaces | Onboarding step **+** post HQ/Admin attention card |
| Item editor | No standing panel; attention control + sheet only |
| Publish gate | **Errors block**; warnings do not |
| Duplicate types | User picks survivor id; **union** ingredients; **hard-delete** loser; case-insensitive create+rename |
| Franchise dupes | **Block menu publish** until fixed |
| Normalize v1 | Types + orphans + menu refs; dry-run → confirm |
| Scan | Auto on Menu Items / onboarding step + manual refresh |
| Undo | Confirm + dry-run; no 24h undo required v1 |
| Tap budget | ≤ 5 for merge → healthy |

---

## Pre-hardware plan (`feat/pre-hardware-hq-polish`)

| Phase | Focus | State |
|-------|--------|--------|
| **A** | Residuals (override chip label; Admin parity) | Chip residual **open**; Admin parity **deferred** |
| **A4** | Hide standing schema UI; Fixes needed + repair sheet | **DONE** (sidebar deleted) |
| **B** | Duplicate types detect + merge; type label normalize | **DONE** (types + ingredients screens) |
| **B+** | Case-insensitive unique type/category names | **DONE** |
| **C** | Catalog health onboarding step + HQ card | **Open** |
| **D** | POS print + drawer **interfaces** | **DONE** (mock); ticket preview optional |
| **E** | iOS bring-up | **Delayed** |
| **F** | Hardware week: real print + drawer | Waiting devices |

**Not required for hardware cutover:** full template re-seed, Phase E extract polish, dual-tree deletion.

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Merge branch when smoke-green; optional Catalog health hub (C) |
| **2** | Soft parallel until hardware + manager sign-off |
| **3** | Hardware: real `PrintService` / `DrawerService` implementers |
| **4** | iOS when scheduled; SendGrid credits when available |

---

**Update this file after significant sessions.**
