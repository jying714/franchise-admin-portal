# STATUS.md — Live Project Snapshot

**Last Updated**: July 30, 2026 (~23:55 CDT — POS carry-out + open board + cash close-out smoke PASS on Android)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/pos-app-v1`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10, customer franchise context v1, stripe-checkout-v1, mobile+web residual polish; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Active implementation:** Decision **14** — Thin POS Station App (`pos_app`).  
**Baseline (2026-07-30 night):** Phases **0–4** + **cash take-payment on open orders** smoke-tested on Samsung S25 (Android).  
**Next:** Phase 5 remainder (card-present, drawer hardware, splits, discount, forced re-PIN on void) **or** Phase 7 delivery / Phase 6 dine-in — product choice.  
**Plan authority:** `docs/plans/pos-app-v1-development-plan.md` (Phases 0–14).  
Pure kitchen-only app (Decision 13) remains **superseded**.

| Area | State |
|------|--------|
| HQ onboarding + Design & Branding | **Done** |
| Platform Owner MVP | **Done** |
| Admin ops v1 | **Done** |
| Menu modifier M1–M5 + wings/calzone | **Done** |
| Mobile Design Tokens v1 (T1–T9) | **Done** |
| Developer Dashboard v1 | **Done** |
| Customer franchise context v1 | **COMPLETE on `main`** |
| Stripe checkout v1 (Connect) | **COMPLETE on `main`** |
| Mobile + web residual polish | **COMPLETE on `main`** |
| **Thin POS (`pos_app`)** | **Active** — Phases 0–4 + cash close-out **smoke PASS** |
| Kitchen-only app | **Superseded** |
| Customer website | **Not started** (hard release gate) |

### Completed (locked)

- [x] Decisions 7–12 delivered on `main` as previously recorded
- [x] Decision 14 product lock (July 30)
- [x] Mobile + web residual polish merged
- [x] **pos_app Flutter scaffold + full user directory tree** (July 30)
- [x] **POS development plan Phases 0–14** documented
- [x] **Phase 1 shared_core domain** — Order.source, OrderStatus, Staff PIN/pay, Driver, Waitress, PosSettings, PosTableLayout, PrintJob, PosFirestoreService, rules
- [x] **Phase 2 PIN shell** — PinSessionProvider, permissions, PinUnlockScreen, bootstrap, franchise dart-define bind, station Auth + claims
- [x] **Phase 3 home + open-order board** — order-type tiles, open orders stream, centered action dialog
- [x] **Phase 4 carry-out** — menu grid, ticket, modifier dialog (Decision 10 groups), send → `sent_to_kitchen` with `source: pos`
- [x] **Phase 5.1 cash path (pickup close-out)** — PaymentScreen from open-order actions; **not** at send time

### Active focus — release MVP

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Thin POS** — finish Phase 5 (card/drawer/splits) + 6–14 per plan | `docs/plans/pos-app-v1-development-plan.md` · `docs/slices/pos-app-v1.md` · Decision 14 |
| **2** | Customer website | TBD slice |
| **3** | Pilot polish | After POS MVP |

**Hard release gate:** Thin POS + customer website + polished mobile + web management.

**Pilot hardware:** Android tablet at counter; Ethernet ESC-POS; cash drawer; card-present reader. Smoke device used: Samsung S25 (`R3GYC00Q3YN`).

### POS phase tracker (summary)

| Phase | Name | Status |
|-------|------|--------|
| 0 | Repo + docs + scaffold | **PASS** |
| 1 | shared_core domain foundation | **PASS** |
| 2 | PIN session + franchise lock + permissions | **PASS** (smoke) |
| 3 | Home + open-order board + actions | **PASS** (smoke) |
| 4 | Carry-out order entry + modifiers + send | **PASS** (smoke) |
| 5 | Payments | **Partial** — cash close-out PASS; card/drawer/splits/discount/re-PIN open |
| 6 | Dine-in tables + open ticket | Open |
| 7 | Delivery + driver assign | Open |
| 8 | Staff / driver / waitress records UI | Open (models exist) |
| 9 | Large order + 86 + allergens | Open (allergen line in modifier dialog only) |
| 10 | Printing pipeline | Open |
| 11 | Incoming online orders | Open (board reads all sources when rules allow) |
| 12 | Settings panel | Open (PosSettings model exists) |
| 13 | Offline honesty | Open |
| 14 | Pilot QA + acceptance | Open |

### Carry-out product flow (locked in smoke)

1. Unlock with staff id + PIN (staff doc under `franchises/{id}/staff/{staffId}`).
2. **Carry-out** → menu → optional modifier dialog → ticket → **Send to kitchen** (`status: sent_to_kitchen`, `source: pos`).
3. Order stays on **Open orders** board while kitchen works.
4. Customer pickup → open order → **Take payment** (cash) → `completed` (leaves open board).
5. **Mark ready** / **Void** available from centered action dialog (permission-gated).

Do **not** require payment at send for carry-out.

### Station Auth + rules (operational)

| Mechanism | Detail |
|-----------|--------|
| Franchise bind | `--dart-define=STATION_FRANCHISE_ID=...` (no silent default) |
| Device Auth | Email/password via `STATION_AUTH_EMAIL` / `STATION_AUTH_PASSWORD` |
| Custom claims | `stationFranchise`, `defaultFranchise`, `franchiseIds`, `roles: [pos_station]` via Admin SDK one-off |
| Rules helper | `isPosStation(franchiseId)` on orders read/write |
| Staff get | `isSignedIn() && posEnabled` **or** franchise owner / station |
| Secrets | `secrets/` gitignored; claims script not committed with keys |

`FranchiseProvider` still requires `LocalStorage` positional arg — do not call zero-arg.

### Decision locks (do not regress)

Retain Decision 11 / 12 / 14 locks: franchise bind, Stripe dual accounts, station = thin POS not kitchen-only, manager-only void/refund, order `source` field, ColorScheme / DesignTokens rules, no second menu modifier tree.

### Explicit post-MVP / deferred

Unchanged: guest cart, live delivery tracking, full time-clock, complex inventory, iOS primary pilot, survey scheduled push, CF Node 22 before ~2026-10-30, mobile T8 auth residual.

**Windows desktop Firebase CMake:** known fail with CMake 4.x + Firebase C++ SDK; use **Android** (or Chrome) for station smoke.

**Ground truth:** one FranchiseProvider pattern; no DesignTokens widget color invention; no pure kitchen binary; no second menu modifier tree in POS; carry-out pays at pickup not at send.

---

**Update this file after significant sessions.**
