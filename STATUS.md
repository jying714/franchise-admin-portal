# STATUS.md — Live Project Snapshot

**Last Updated**: August 1, 2026 (~22:20 CDT — cleanup branch merged: mobile UI polish, sub cook profile, HQ menu search/sort, POS order-detail workspace)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `main`  
**Main**: All prior MVP slices + thin POS software pilot + **2026-08-01 cleanup** (mobile / web / POS order workspace); Hosting deploy on push to `main`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Thin POS software pilot: COMPLETE on `main` (2026-08-01).**  
**Post-pilot cleanup (merged same day):** mobile reduced category/menu cards, dinner optional-addon pricing + visibility, sub menu profile (cook Regular/Crispy), order history desc, profile share-QR dialog; HQ + Admin menu editor search/sort; **POS order-detail workspace** (live dialog, line void/comp/partial qty, nested add-on void, add item under dialog, print check/kitchen, closed line refund, source + payment chips).

**Not product hard-release complete:** customer website, Stripe Terminal hardware, real printers, staff bootstrap polish, formal Phase 14 tablet sign-off packaging.  

**Next product focus:** **Customer website** (hard release gate partner) **or** hardware (Terminal / ESC-POS) when available. Optional: check-level discounts on open POS tickets.  

**Plan authority:** `docs/plans/pos-app-v1-development-plan.md` · `docs/slices/pos-app-v1.md`.  
Pure kitchen-only app (Decision 13) remains **superseded**.

| Area | State |
|------|--------|
| HQ onboarding + Design & Branding | **Done** |
| Platform Owner MVP | **Done** |
| Admin ops v1 | **Done** |
| Menu modifier M1–M5 + wings/calzone | **Done** |
| Mobile Design Tokens v1 (T1–T9) | **Done** |
| Developer Dashboard v1 | **Done** |
| Customer franchise context v1 | **COMPLETE** |
| Stripe checkout v1 (Connect) | **COMPLETE** |
| Mobile + web residual polish | **COMPLETE** + 2026-08-01 UI polish |
| **Thin POS (`pos_app`) software pilot** | **COMPLETE on `main`** |
| **POS order-detail workspace** | **COMPLETE on `main`** (void/comp/add/print/line refund) |
| Kitchen-only app | **Superseded** |
| Customer website | **Not started** (hard release gate) |

### Completed (locked) — POS software pilot

- [x] Decisions 7–12 on `main`
- [x] Decision 14 product lock; pure kitchen binary superseded
- [x] pos_app Phases 0–4 (PIN, board, carry-out)
- [x] Phase 5 money — pre-tax discount; live due; cash + split; **card PaymentSheet + Connect PI**
- [x] Closed orders board + cash refund skeleton (re-PIN)
- [x] Print mocks — kitchen + customer receipt
- [x] Dine-in / delivery ops baselines
- [x] Online intake — mobile in-hours → `sent_to_kitchen`; POS auto kitchen ticket; outside-hours block
- [x] **HQ Tax & hours** — `franchises/{id}/config/store_ops` (taxRate + per-weekday hours); Quick Link on Owner HQ
- [x] Mobile + POS **read** store_ops tax; mobile **read** today’s hours for open gate
- [x] Station settings (AppBar gear) — franchise / tax / today hours read-only
- [x] Offline honesty — home banner (seeded connectivity check); PaymentScreen card disabled + hard-block
- [x] Android Stripe shell — FlutterFragmentActivity + Material/AppCompat themes (day + night)
- [x] Pilot smoke script (software) **PASS** 2026-08-01
- [x] Branch `feat/pos-app-v1` merged to `main`; feature branch deleted

### Completed (locked) — 2026-08-01 cleanup (`fix/cleanup-web-mobile-pos` → `main`)

**Mobile**
- [x] Category grid: reduced (no-image) cards merge into continuous 2-col slots (stacked pairs fill empty cells)
- [x] Menu item reduced card: slim layout (qty right of title; actions below)
- [x] Dinner included ingredients stay visible when empty; optional add-ons price via `_resolveExtraIngredientPrice`
- [x] Order history descending (newest first)
- [x] Profile: loyalty → contact → change restaurant → share franchise (QR dialog) → rest
- [x] **Sub menu profile** (`MenuProfile.sub`) — Cook Regular (default) / Crispy; modal bridge; optional add-ons same pattern as dinners

**Web**
- [x] HQ onboarding step 4 menu items: local search + sort (name A–Z / sortOrder); reorder gated when filtered
- [x] Admin menu editor parity (search + sort)
- [x] Dinner optional-addon price wiring in HQ + Admin `MenuItemEditorSheet`

**POS order-detail workspace**
- [x] Large `OrderDetailDialog` streams order doc (stays open on line ops)
- [x] Line void / comp; partial qty split; nested add-on void (POS group maps + mobile keys)
- [x] Manager PIN for void/comp/refund
- [x] Add item → `OrderEntryScreen(existingOrderId:)` under dialog; append preserves `lineStatus`
- [x] Print guest check + reprint kitchen (open + closed)
- [x] Closed line refund (cash skeleton) + whole-order refund
- [x] Closed list: **source** + **payment method** chips (MOBILE + CASH/CARD/SPLIT)
- [x] Paths: `pos_app/lib/features/orders/widgets/order_detail_dialog.dart`, `order_line_ops.dart`

**Shared**
- [x] `OrderItem.lineStatus` + void/comp audit fields; `effectiveLineTotal`
- [x] `MenuProfile.sub` template seed

### Pilot smoke script (software) — PASS 2026-08-01

- [x] PIN unlock → home
- [x] Carry-out send → kitchen mock ticket
- [x] Cash close-out → closed board
- [x] Card PaymentSheet (`4242…`) → paid + receipt mock
- [x] Discount + pre-tax tax matches HQ rate
- [x] Mobile in-hours → `sent_to_kitchen` + POS auto ticket
- [x] Mobile closed day → place blocked
- [x] Station settings shows franchise / tax / today hours
- [x] Airplane mode → banner; Card disabled; cash still offered
- [x] Refund paid cash order from Closed (re-PIN)

### Active focus — after POS software pilot + cleanup

| Priority | Work | Notes |
|----------|------|--------|
| **1** | **Customer website** | Hard release gate; same pay + in-hours → kitchen rules |
| **2** | Staff bootstrap docs (R8) | PIN seed, claims, dart-defines runbook |
| **3** | Stripe Terminal / real printers (R3/R4) | When hardware available; mock stays fallback |
| **4** | Optional: open-ticket check/item discounts | Beyond payment-time discount |
| **5** | Staff/driver UI, 86, large-order (Phases 8–9) | Models exist |
| **6** | Formal tablet pilot packaging (R9 residual) | Optional sign-off on production tablet |

**Hard release gate:** Thin POS (**software done**) + **customer website** + polished mobile + web management.

### POS phase tracker

| Phase | Name | Status |
|-------|------|--------|
| 0–4 | Scaffold → carry-out | **PASS** |
| 5 | Payments (software) | **PASS** — Terminal open |
| 6 | Dine-in | **PASS (ops)** |
| 7 | Delivery | **PASS (ops)** |
| 8 | Staff UI | **Open** |
| 9 | Large order + 86 | **Open** |
| 10 | Printing | **PASS (mock)** — hardware open |
| 11 | Online intake | **PASS (MVP)** |
| 12 | Settings | **PASS (read-only station)** |
| 13 | Offline honesty | **PASS (banner + block card)** |
| 14 | Pilot QA software | **PASS** 2026-08-01 |
| — | Order-detail workspace (void/comp/add/print/line refund) | **PASS** 2026-08-01 |

### Residual list (updated 2026-08-01 evening)

| ID | Item | Status |
|----|------|--------|
| R1 | Franchise tax from `config/store_ops` | **Done** |
| R2 | Franchise hours from `config/store_ops` | **Done** |
| R3 | Stripe Terminal / physical reader | **Open** (PaymentSheet waived for software pilot) |
| R4 | Real printers | **Open** (mock OK for pilot) |
| R5 | Offline honesty | **Done** |
| R6 | Station settings UI | **Done** |
| R7 | Customer website MVP | **Open** — **next product epic** |
| R8 | Staff bootstrap documented | **Open** (partial) |
| R9 | Phase 14 software smoke | **Done**; production-tablet packaging optional |
| R10 | Order-detail workspace | **Done** |

**Firestore path (locked):** `franchises/{franchiseId}/config/store_ops`  
Fields: `taxRate` (decimal), `hours.{mon…sun}.{openHour,openMinute,closeHour,closeMinute,closed}`.

**Explicit post-MVP:** scheduled orders; card refund reverse; guest cart; live delivery tracking; full time-clock; complex inventory; iOS primary pilot; CF Node 22 before ~2026-10-30.

### Carry-out / online flows (locked)

- Carry-out: pay at **pickup** (board), not at send.  
- Mobile in-hours → kitchen; outside hours / closed day → blocked.  
- POS auto mock kitchen ticket for online `sent_to_kitchen` (once per session id).

### Station run

```text
--dart-define=STATION_FRANCHISE_ID=...
--dart-define=STATION_AUTH_EMAIL=...
--dart-define=STATION_AUTH_PASSWORD=...
--dart-define=STRIPE_PK=pk_...   # never sk_
```

PowerShell: single-line dart-defines preferred (backtick glue breaks franchise bind).

`FranchiseProvider` requires `LocalStorage` — no zero-arg.

### Decision locks (do not regress)

Decision 11 / 12 / 14: franchise bind, dual Stripe, thin POS not kitchen-only, manager void/refund, order `source`, no second menu modifier tree, carry-out pays at pickup.

**Order lines:** `OrderItem.lineStatus` (`active` / `voided` / `comped`); totals use `effectiveLineTotal`. Nested void strips POS group-key lists and mobile `selectedAddOns` / `currentIngredients`.

**Windows desktop Firebase CMake:** prefer **Android** for station smoke.

---

**Update this file after significant sessions.**
