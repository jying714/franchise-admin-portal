# STATUS.md — Live Project Snapshot

**Last Updated**: August 18, 2026 (TSP100 StarGraphic print + drawer)  
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
| POS print/drawer | **StarGraphic live** on TSP143 LAN — `PrintService` + `DrawerService` |
| Station hardware · iOS | **TSP100 + drawer + Stripe reader on site**; iOS delayed |
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
| **D** | POS print + drawer | **DONE** — StarGraphic + DK kick on one TSP100 |
| **E** | iOS bring-up | **Delayed** |
| **F** | Hardware week: real print + drawer | **DONE for single TSP100** (receipt/kitchen/drawer); layout polish open |

**Not required for hardware cutover:** full template re-seed, Phase E extract polish, dual-tree deletion.

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Vendor Star plugin is on branch; merge when Catalog health + POS print signed off |
| **2** | Receipt/ticket **layout** polish (same PrintService formatters; HQ editor later) |
| **3** | Stripe Terminal when scheduled (reader ≠ printer) |
| **4** | Doughboys install: existing kitchen printers + this TSP100 as counter receipt |
| **5** | iOS when scheduled; SendGrid credits when available |


---

## Station hardware inventory (2026-08-18)

| Device | Status | Notes |
|--------|--------|--------|
| **Star TSP143 / TSP100 LAN** | **Live** — `192.168.1.21` | Model `TSP143 (STR_T-001)`. **StarGraphic** (not raw ESC/POS 9100). Kitchen + receipt + mobile tickets **PASS**. |
| **Cash drawer** | **Live** via printer DK | `DrawerService` Star `openCashDrawer` on cash pay **PASS**. |
| **Stripe card reader** | **On site** | Payment only — receipts still go through `PrintService` → TSP100. |
| **Kitchen / 2nd printer** | Doughboys already has units | MVP **dev uses this one printer for all roles**. Live: kitchen printers on site + this (or counter) unit for guest checks. |

**POS print stack:**

- `pos_app/lib/services/print_service.dart` — roles `kitchen` / `receipt`; console always; LAN via StarIO.
- `pos_app/lib/services/drawer_service.dart` — same `POS_PRINTER_HOST`.
- Plugin: **vendored** `pos_app/vendor/flutter_star_prnt_plus` (path dep; AGP namespace + no Registrar).
- Run: `--dart-define=POS_PRINTER_HOST=192.168.1.21` (plus existing station/Stripe defines).
- Order/pay **must not** fail on print/drawer errors.

**Not yet:** HQ printer registry, category routing, ticket-layout editor, station-settings host field.


**Update this file after significant sessions.**
