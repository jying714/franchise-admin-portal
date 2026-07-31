# Thin POS (`pos_app`) — Development Plan (Phases 0–14 → polished MVP)

**Status**: Active  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · `docs/slices/pos-app-v1.md` · STATUS · HANDOFF · this file  
**Last Updated**: July 30, 2026 (~23:55 CDT)  

**Progress:** Phases **0–4 PASS** (Android smoke). Phase **5 partial** (cash Take payment on open orders).  
**Next:** Phase 5 remainder (card / drawer / splits / discount / forced re-PIN) **or** Phase 6/7 by product priority.

Hard release gate (product-wide) still includes **customer website** after POS polished MVP.

---

## Guiding rules (do not skip)

1. **Schema before UI.** Extend `shared_core` + Firestore rules under human review before screens depend on new fields.
2. **Session before money.** PIN + permissions before void/refund/pay/86.
3. **Ticket before tenders.** Order entry + open ticket before card/cash/drawer.
4. **Online path before offline.** Happy-path online station first; offline cash is late.
5. **Hardware last among core flows.** Mock printers/drawer/Terminal early; real devices at pilot.
6. **No second menu tree.** Reuse `MenuItem` / modifier profile from shared_core + mobile patterns.
7. **No kitchen-only binary.** Everything lives in `pos_app` + shared open-order list for online orders.
8. **Carry-out pays at pickup.** Send → kitchen open order; **Take payment** from board when customer arrives — do not force pay at send.

---

## Phase 0 — Repo + docs lock — **PASS**

| Step | Work | Exit |
|------|------|------|
| 0.1 | `feat/pos-app-v1` branch; STATUS/HANDOFF/ROADMAP/slice updated | Docs say POS is active |
| 0.2 | `flutter create pos_app` + user tree script | Empty tree + Flutter shell on disk |
| 0.3 | `pubspec.yaml` → `shared_core` path dep; `flutter pub get` | Resolves without errors |

---

## Phase 1 — Shared domain foundation — **PASS**

| Step | Work | Status |
|------|------|--------|
| 1.1 | Order `source` (`pos` \| `mobile` \| `web`) | **Done** |
| 1.2 | `OrderStatus` constants + board helpers | **Done** |
| 1.3 | Staff: `pinHash`, `hourlyPay`, `posEnabled`, `franchiseId` | **Done** |
| 1.4 | Driver / Waitress models | **Done** |
| 1.5 | PosSettings model | **Done** |
| 1.6 | PosTableLayout / PosTableNode | **Done** |
| 1.7 | PrintJob model | **Done** |
| 1.8 | Firestore rules POS paths + `isPosStation` | **Done** (keep repo ↔ Console in sync) |
| 1.9 | `PosFirestoreService` (thin; not mega FirestoreService bloat) | **Done** |

---

## Phase 2 — PIN session shell — **PASS (smoke)**

| Step | Work | Status |
|------|------|--------|
| 2.1 | Bootstrap Firebase + `firebase_options` | **Done** |
| 2.2 | Franchise bind via `STATION_FRANCHISE_ID` dart-define (no silent default) | **Done** |
| 2.3 | `PinSessionProvider` (unlock, idle timer, lock/repin) | **Done** |
| 2.4 | `PosPermissions` + `PermissionGate` + `PinHash` | **Done** |
| 2.5 | `PinUnlockScreen` | **Done** |
| 2.6 | Unlock → home via `PosApp` Consumer | **Done** |
| — | Station Auth email/password + custom claims + `getIdToken(true)` | **Done** |

---

## Phase 3 — Home + open-order board — **PASS (smoke)**

| Step | Work | Status |
|------|------|--------|
| 3.1 | Dine-in / Carry-out / Delivery tiles | **Done** (dine-in/delivery still stubs) |
| 3.2 | Open-orders stream `franchises/{id}/orders` | **Done** |
| 3.3 | Source badge + status; **centered action dialog** | **Done** |
| 3.4 | Needs-approval queue | Open |

Actions in dialog: Take payment, Mark ready, Void, Refund (stub).

---

## Phase 4 — Carry-out order entry — **PASS (smoke)**

| Step | Work | Status |
|------|------|--------|
| 4.1 | Menu grid from `menu_items` | **Done** (flat grid; category rail optional later) |
| 4.2 | Ticket panel qty / remove / subtotal | **Done** |
| 4.3 | `PosModifierDialog` using Decision 10 groups | **Done** |
| 4.4 | Allergen line in modifier dialog | **Partial** |
| 4.5 | Send → `sent_to_kitchen` | **Done** |
| 4.6 | Persist `source: pos`, staff id/name | **Done** |

---

## Phase 5 — Payments — **PARTIAL**

| Step | Work | Status |
|------|------|--------|
| 5.1 | Payment screen amount due + tender | **Done** |
| 5.2 | Cash tender + change; drawer kick **mock print only** | **Partial** |
| 5.3 | Card-present / Terminal | Open |
| 5.4 | Split tenders | Open |
| 5.5 | Discount sheet | Open |
| 5.6 | Complete → `completed` on cash success | **Done** |
| 5.7 | Void from board (permission); forced re-PIN | **Partial** (void works; re-PIN UI incomplete) |

**Product rule:** Carry-out payment is invoked from **Open orders → Take payment**, not from Send.

---

## Phase 6 — Dine-in — **OPEN**

Web table layout editor + POS consume/seat/open ticket/pay at close.

---

## Phase 7 — Delivery — **OPEN**

Customer + address first; driver required at completion.

---

## Phase 8 — Staff ops UI — **OPEN**

Models exist; manager PIN set/reset + lists UI open.

---

## Phase 9 — Large order + 86 — **OPEN**

---

## Phase 10 — Printing — **OPEN**

---

## Phase 11 — Incoming online — **OPEN**

Board already streams franchise orders; auto-print + management parity open.

---

## Phase 12 — Settings UI — **OPEN**

`PosSettings` model exists; panel UI open.

---

## Phase 13 — Offline — **OPEN**

---

## Phase 14 — Pilot QA — **OPEN**

---

## Parallel tracks

| Track | Can overlap with | Blocked until |
|-------|------------------|---------------|
| Web table layout editor | Phase 5+ | Phase 1 layout model (**done**) |
| Stripe Terminal sandbox | Now | Phase 5 payment screen (**done**) |
| Printer lab | Now | Phase 10 for production rules |
| Staff seed | Ongoing | Phase 1 staff schema (**done**) |

---

## Explicitly after POS polished MVP

1. **Customer website** (hard release gate partner)
2. Guest cart, live delivery tracking, full time-clock, complex inventory, iOS primary pilot
3. Post-order survey scheduled push (deferred from Stripe slice)

---

## Milestone tags

| Tag | Meaning | Status |
|-----|---------|--------|
| `pos-m1-shell` | Phase 2 done | **Reached** |
| `pos-m2-carryout-pay` | Phases 3–5 done | **Near** (cash only) |
| `pos-m3-dine-in` | Phase 6 done | Open |
| `pos-m4-delivery-staff` | Phases 7–8 done | Open |
| `pos-m5-ops-print` | Phases 9–11 done | Open |
| `pos-m6-mvp` | Phases 12–14 done | Open |

---

## Next single step

Human prioritizes one of:

1. **Phase 5.3+** — card-present adapter, drawer permission, splits, discount, forced re-PIN on void/refund  
2. **Phase 7** — delivery customer capture + driver assign on complete  
3. **Phase 6** — web table layout editor + POS map consume  

Do not regress carry-out pickup payment timing.
