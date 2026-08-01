# STATUS.md — Live Project Snapshot

**Last Updated**: August 1, 2026 (~09:40 CDT — POS pilot money/print/online intake smoke PASS)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/pos-app-v1`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10, customer franchise context v1, stripe-checkout-v1, mobile+web residual polish; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Active implementation:** Decision **14** — Thin POS Station App (`pos_app`).  
**Pilot baseline (2026-08-01):** Ops surfaces + money truth (tax/discount/cash/split/card software) + mock print + closed board/refund + mobile in-hours → kitchen + auto kitchen ticket — **smoke PASS** on Android.  
**Not POS MVP complete:** HQ tax/hours config, Terminal hardware, real printers, offline honesty, station settings UI, customer website, formal pilot checklist signed off.  
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
| Customer franchise context v1 | **COMPLETE on `main`** |
| Stripe checkout v1 (Connect) | **COMPLETE on `main`** |
| Mobile + web residual polish | **COMPLETE on `main`** |
| **Thin POS (`pos_app`)** | **Active** — pilot path ~75–80%; residual list below |
| Kitchen-only app | **Superseded** |
| Customer website | **Not started** (hard release gate) |

### Completed (locked)

- [x] Decisions 7–12 delivered on `main` as previously recorded
- [x] Decision 14 product lock (July 30)
- [x] Mobile + web residual polish merged
- [x] **pos_app** scaffold + Phases 0–4 (PIN, board, carry-out send)
- [x] **Phase 5 money (pilot)** — pre-tax discount stack; live amount due; cash + split; **card via Connect PaymentIntent + PaymentSheet** (software entry, not Terminal)
- [x] **Closed orders board** — type filters + date range (Today / 7d / month / custom); refund surface for paid tickets
- [x] **Refund skeleton** — full cash refund, re-PIN, `refunded` metadata; card reverse deferred
- [x] **Print mocks** — kitchen ticket on POS send / board send / auto online; customer receipt on pay
- [x] **Online intake (MVP)** — mobile in store hours → `sent_to_kitchen` + `source: mobile`; POS auto kitchen ticket once per order id per session
- [x] **Outside-hours mobile gate** — hardcoded 11:00–21:00; block place order when closed (no scheduled queue)
- [x] **Android Stripe shell** — `FlutterFragmentActivity`; AppCompat/MaterialComponents themes (day + night); `STRIPE_PK` dart-define

### Active focus — residual toward polished POS MVP

| Priority | Work | Notes |
|----------|------|--------|
| **1** | **HQ tax config** | Kill provisional `0.0925`; franchise-scoped rate for mobile + POS |
| **2** | **HQ / franchise store hours** | Replace mobile hardcode; same rule for future web |
| **3** | **Station settings UI** | Franchise bind display, mock print flags, staff permission view |
| **4** | **Offline honesty** | Banner; cash-only; no silent success when offline |
| **5** | **Terminal / real printers** | When hardware available; keep mock adapters |
| **6** | **Customer website** | Hard release gate partner; same kitchen + pay rules |
| **7** | **Pilot checklist sign-off** | Phase 14 acceptance in plan/slice |

**Hard release gate:** Thin POS + customer website + polished mobile + web management.

**Pilot hardware:** Android tablet at counter; Ethernet ESC-POS (mock OK); cash drawer (mock OK); card-present reader (PaymentSheet interim). Smoke devices: Samsung S25 / tablet (`R52WA09Z7XV` used for Stripe).

### POS phase tracker (summary)

| Phase | Name | Status |
|-------|------|--------|
| 0 | Repo + docs + scaffold | **PASS** |
| 1 | shared_core domain foundation | **PASS** |
| 2 | PIN session + franchise lock + permissions | **PASS** |
| 3 | Home + open-order board + actions | **PASS** (+ closed board) |
| 4 | Carry-out order entry + modifiers + send | **PASS** |
| 5 | Payments | **PASS (pilot software)** — tax/discount/cash/split/card PaymentSheet; Terminal open |
| 6 | Dine-in tables + open ticket | **PASS (ops)** — floor map + ticket paths in use; polish residual |
| 7 | Delivery + driver assign | **PASS (ops)** — customer capture, COD/till, assign |
| 8 | Staff / driver / waitress records UI | **Open** (models exist) |
| 9 | Large order + 86 + allergens | **Open** (allergen line partial) |
| 10 | Printing pipeline | **PASS (mock)** — kitchen + receipt; hardware open |
| 11 | Incoming online orders | **PASS (MVP)** — in-hours → kitchen + auto ticket; web channel N/A |
| 12 | Settings panel | **Open** |
| 13 | Offline honesty | **Open** |
| 14 | Pilot QA + acceptance | **Open** |

### Residual list (dated 2026-08-01)

Do not mark POS MVP complete until these are done or **explicitly waived in writing**:

| ID | Item | Owner track |
|----|------|-------------|
| R1 | Franchise **tax rate** from config (not provisional 9.25%) | HQ + shared + POS/mobile |
| R2 | Franchise **store hours** from config (not hardcoded 11–21) | HQ + mobile (+ web later) |
| R3 | **Stripe Terminal** or chosen reader (optional if PaymentSheet accepted for pilot) | POS |
| R4 | **Real kitchen/receipt printers** (ESC-POS); mock remains fallback | POS |
| R5 | **Offline honesty** (banner, cash-only, no false paid) | POS |
| R6 | **Station settings** UI (bind, print, staff hints) | POS |
| R7 | **Customer website** MVP | New slice |
| R8 | Staff bootstrap **documented** (PIN seed, claims, dart-defines) | Docs + ops |
| R9 | Phase 14 smoke script pass on pilot tablet | QA |

**Explicit post-MVP:** scheduled orders; partial/card refund reverse; guest cart; live delivery tracking; full time-clock; complex inventory; iOS primary pilot; CF Node 22 before ~2026-10-30.

### Carry-out product flow (locked)

1. Unlock with staff id + PIN.
2. Carry-out → menu → modifiers → **Send to kitchen** (`source: pos`) — **pay at pickup**, not at send.
3. Open board → Take payment (cash / split / card PaymentSheet).
4. Closed board for completed/cancelled; refund from closed (paid only).

### Online intake flow (locked MVP)

1. Mobile checkout **during store hours** → `status: sent_to_kitchen`, `source: mobile`.
2. Mobile **outside hours** → place order blocked (no schedule queue).
3. POS open board **auto** mock kitchen ticket once per online `sent_to_kitchen` order (session set).
4. Manual **Send to kitchen** remains for edge / legacy `placed`.

### Station Auth + run

| Mechanism | Detail |
|-----------|--------|
| Franchise bind | `--dart-define=STATION_FRANCHISE_ID=...` |
| Device Auth | `STATION_AUTH_EMAIL` / `STATION_AUTH_PASSWORD` |
| Stripe | `--dart-define=STRIPE_PK=pk_…` (never `sk_`) |
| Claims | `stationFranchise`, `franchiseIds`, `roles: [pos_station]` |
| Secrets | `secrets/` gitignored |

PowerShell: use **one line** or space before each `` ` `` continuation so dart-defines are not glued.

`FranchiseProvider` still requires `LocalStorage` — no zero-arg.

### Decision locks (do not regress)

Decision 11 / 12 / 14: franchise bind, dual Stripe, thin POS not kitchen-only, manager void/refund, order `source`, no second menu modifier tree, carry-out pays at pickup.

**Windows desktop Firebase CMake:** prefer **Android** for station smoke.

---

**Update this file after significant sessions.**
