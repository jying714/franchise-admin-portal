# STATUS.md — Live Project Snapshot

**Last Updated**: October 1, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`feat/pre-hardware-hq-polish`** (active) · soft-release **`main`**  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Out of franchiseHQ production MVP

**WeekTally / weekly tally is not a franchiseHQ product feature and is not an MVP acceptance item.**

It is still hosted on the admin domain. `firebase.json` admin target must keep these rewrites **before** the `**` → `/index.html` catch-all, on `main` and on this branch:

- `/tally/api/**` → Cloud Run `weektally` (`us-central1`)
- `/tally` → Cloud Run `weektally`
- `/tally/**` → Cloud Run `weektally`

Copied onto polish in `b6692319`. Do not deploy Hosting from a branch that drops them. Do not track WeekTally in burn-in, Owner.com cutover, or release %.

Also deferred past MVP (do not pull into the October completion bar): **iOS**, **printer-by-category**, **loyalty**, **custom domains**, **home composition Wave 2** (`docs/plans/home-page-composition-engine-v1.md` — HQ homepage widget studio; Wave 1 shell is already complete).

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | On `main` for base; polish not merged |
| Ordering customization parity | **Open** — `docs/slices/ordering-customization-normalize-v1.md` |
| Salad profile + dressings + optional overrides | **Merged to main** (2026-08-15) |
| HQ menu editor layout + type-first ingredient picker | **On main** |
| Catalog health / schema UX | **On branch** — foundation + Fixes sheet; phase C open |
| POS print/drawer | **StarGraphic live** on TSP143 LAN |
| POS station UX (builders, cash tip, EOD) | **On branch** 2026-08-20/21; idle docs stale vs `d428a034` |
| Station hardware · iOS | TSP100 + drawer + reader on site; **iOS post-MVP** |
| Soft parallel / Owner.com cutover | Soft parallel OK |
| Portal invite email (SendGrid) | Wired; blocked on credits |
| WeekTally `/tally` | **Out of MVP** — hosting rewrites required on admin target |

---

## Ordering customization (locked 2026-10-01)

Mobile modal is the reference. POS and customer_web must match it. Authority: `docs/slices/ordering-customization-normalize-v1.md`.

Confirmed gap: three confirm maps. customer_web has no salad/dinner builder. Sauce amount and `menu_profile_wings` fallback are mobile-only. Drinks flavor stays mobile-only until a drink is sold on web and POS.

---

## Decision 15 — Catalog Health (locked 2026-08-15)

Authority: `docs/DECISIONS.md` §15, `docs/slices/catalog-health-v1.md`

Owners see **Catalog health** / **Fixes needed** (not “schema”). Errors block publish; warnings do not. Duplicate types: pick survivor, union ingredients, hard-delete loser.

---

## Pre-hardware plan (`feat/pre-hardware-hq-polish`)

| Phase | Focus | State |
|-------|--------|--------|
| **A4** | Hide standing schema UI; Fixes needed | **DONE** |
| **B / B+** | Type merge + case-insensitive names | **DONE** |
| **C** | Catalog health onboarding hub + HQ card | **Open** |
| **D** | POS print + drawer | **DONE** — StarGraphic + DK |
| **POS UX** | Profile builders, cash close-out, EOD, idle | Builders/EOD done; idle smoke not re-recorded after `d428a034` |
| **E** | iOS | **Post-MVP** |

---

## POS station UX (2026-08-20 → 21) — on this branch

| Item | State |
|------|--------|
| `PosCustomizationSheet` by `menuProfile` (pizza L/R+Dbl, calzone/sub/dinner Dbl, salad dressings, wings halves+dips) | **PASS** — not mobile-parity; see normalize slice |
| Ticket/print WHOLE/LEFT/RIGHT + HALF 1/2 + optionLabels | **PASS** for POS-shaped maps |
| Dine-in optional name+phone; after Add → categories; tap line to re-edit (seeded) | **PASS** |
| Seated table: Add items + Modify ticket (+ Add items in workspace) | **PASS** |
| Cash tender dialog → change due; cash stays **open** until Close out (tip) | **PASS** |
| `cashTip` / `cardTip` + `closedByStaffName` | **PASS** |
| EOD (manager/owner): cash/card/overall by source; tips by staff → order | **PASS** |
| Idle: `lockForRepin` → `SessionTimeoutOverlay` then `lock()` | Code advanced in `d428a034`; August 21 smoke note still says fail — re-smoke before checking the box |

**Do not invent** `Order.paymentMethod` / `Order.tableId` getters — read those fields from the order doc.

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Ordering customization normalize — shared payload, then web salad/dinner, wing-config fallback |
| **2** | Merge polish to `main` (delivery callable is not on `main`) |
| **3** | Delivery range on mobile + POS (web + HQ store_ops already on polish) |
| **4** | Catalog health phase C |
| **5** | Functions Node 22 before ~2026-10-30 |
| **6** | Re-smoke idle; SendGrid credits if invites are required |

Printer-by-category, iOS, loyalty, custom domains, Wave 2 studio, WeekTally product work: not this list. Keep the `/tally` Hosting rewrites anyway.

---

## Station hardware inventory (2026-08-18)

| Device | Status | Notes |
|--------|--------|--------|
| **Star TSP143 / TSP100 LAN** | **Live** — `192.168.1.21` | StarGraphic. Kitchen + receipt **PASS**. One printer for MVP. |
| **Cash drawer** | **Live** via DK | Cash pay **PASS**. |
| **Stripe card reader** | **On site** | Payment only. Terminal flow not required for this bar unless counter card must be reader-taken. |

Plugin vendored: `pos_app/vendor/flutter_star_prnt_plus`. Host: `--dart-define=POS_PRINTER_HOST=192.168.1.21`.

**Update this file after significant sessions.**
