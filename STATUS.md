# STATUS.md — Live Project Snapshot

**Last Updated**: August 21, 2026 (POS station UX + EOD + idle overlay)  
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
| Catalog health / schema UX | **On branch** — foundation + Fixes sheet |
| POS print/drawer | **StarGraphic live** on TSP143 LAN |
| POS station UX (builders, cash tip, EOD) | **On branch** 2026-08-20/21 |
| Station hardware · iOS | **TSP100 + drawer + Stripe reader on site**; iOS delayed |
| Soft parallel / Owner.com cutover | Soft parallel OK |
| Portal invite email (SendGrid) | Wired; blocked on credits |

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
| **POS UX** | Profile builders, cash close-out, EOD, idle | **Mostly done** — idle timer **not verified** |
| **E** | iOS | **Delayed** |

---

## POS station UX (2026-08-20 → 21) — on this branch

| Item | State |
|------|--------|
| `PosCustomizationSheet` by `menuProfile` (pizza L/R+Dbl, calzone/sub/dinner Dbl, salad dressings, wings halves+dips) | **PASS** |
| Ticket/print WHOLE/LEFT/RIGHT + HALF 1/2 + optionLabels | **PASS** |
| Dine-in optional name+phone; after Add → categories; tap line to re-edit (seeded) | **PASS** |
| Seated table: Add items + Modify ticket (+ Add items in workspace) | **PASS** |
| Cash tender dialog → change due; cash stays **open** until Close out (tip) | **PASS** |
| `cashTip` / `cardTip` + `closedByStaffName` | **PASS** |
| EOD (manager/owner): cash/card/overall by source; tips by staff → order | **PASS** |
| Idle: `lockForRepin` → `SessionTimeoutOverlay` (30s) then `lock()` | **Wired — timer not functional in smoke** |
| Pointer `touch()` on `PosApp` Listener | **Wired — verify with timer** |

**Do not invent** `Order.paymentMethod` / `Order.tableId` getters — read those fields from the order doc.

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Fix idle timer (overlay never/always firing) — then HQ idle + grace seconds |
| **2** | Delivery range v1 (distance **or** drive time) on `store_ops` — POS + mobile + customer_web |
| **3** | Receipt/ticket layout polish; HQ printer-by-category later |
| **4** | Stripe Terminal when scheduled |
| **5** | Merge when Catalog health + POS UX signed off |
| **6** | iOS; SendGrid credits |

---

## Station hardware inventory (2026-08-18)

| Device | Status | Notes |
|--------|--------|--------|
| **Star TSP143 / TSP100 LAN** | **Live** — `192.168.1.21` | StarGraphic. Kitchen + receipt **PASS**. |
| **Cash drawer** | **Live** via DK | Cash pay **PASS**. |
| **Stripe card reader** | **On site** | Payment only. |
| **2nd kitchen printer** | Doughboys floor | MVP dev = this one printer. |

Plugin vendored: `pos_app/vendor/flutter_star_prnt_plus`. Host: `--dart-define=POS_PRINTER_HOST=192.168.1.21`.

**Update this file after significant sessions.**
