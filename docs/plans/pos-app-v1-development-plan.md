# Thin POS (`pos_app`) — Development Plan (Phases 0–14 → polished MVP)

**Status**: Active — pilot baseline complete; residual config/settings/offline/QA  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · `docs/slices/pos-app-v1.md` · STATUS · HANDOFF · this file  
**Last Updated**: August 1, 2026 (~09:40 CDT)  

**Progress:** Phases **0–7 ops + 5 money pilot + 10 mock print + 11 online MVP** smoke PASS.  
**Open:** Phase 8 staff UI, 9 large/86, 12 settings, 13 offline, 14 QA; Terminal/real print; HQ tax & hours config.

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
9. **Online in-hours → kitchen.** Mobile (and later web) within store hours writes `sent_to_kitchen`; scheduled is post-MVP.

---

## Phase 0 — Repo + docs lock — **PASS**

## Phase 1 — Shared domain foundation — **PASS**

## Phase 2 — PIN session shell — **PASS**

## Phase 3 — Home + open-order board — **PASS**

Includes **Closed orders** board (terminal statuses, type filters, date range, refund entry).

## Phase 4 — Carry-out order entry — **PASS**

## Phase 5 — Payments — **PASS (pilot software)**

| Step | Work | Status |
|------|------|--------|
| 5.1 | Payment screen amount due + tender | **Done** |
| 5.2 | Cash tender + change; drawer **mock** | **Done** |
| 5.3 | Card — Connect PI + PaymentSheet | **Done** (Terminal hardware open) |
| 5.4 | Split tenders | **Done** |
| 5.5 | Discount sheet + pre-tax stack | **Done** |
| 5.6 | Complete → paid/completed writes | **Done** |
| 5.7 | Void + refund + forced re-PIN | **Done** (refund cash full; card reverse open) |

**Tax note:** Provisional rate `0.0925` until HQ franchise tax config (STATUS residual R1).

## Phase 6 — Dine-in — **PASS (ops)**

Floor map + seat + ticket + pay at close in use. Chrome polish residual OK.

## Phase 7 — Delivery — **PASS (ops)**

Customer/address, COD, till close, driver assign paths in use.

## Phase 8 — Staff ops UI — **OPEN**

Models exist; manager PIN set/reset + lists UI open.

## Phase 9 — Large order + 86 — **OPEN**

## Phase 10 — Printing — **PASS (mock)**

| Step | Status |
|------|--------|
| Kitchen ticket on POS send | **Done** (mock) |
| Kitchen ticket on board send | **Done** (mock) |
| Auto ticket online `sent_to_kitchen` | **Done** (mock, once per session id) |
| Customer receipt on pay | **Done** (mock) |
| Real ESC-POS / multi-printer routing | **Open** |

## Phase 11 — Incoming online — **PASS (MVP)**

| Step | Status |
|------|--------|
| Board lists mobile/web sources | **Done** |
| Mobile in-hours → `sent_to_kitchen` | **Done** |
| Outside-hours block place order | **Done** (hardcoded 11–21) |
| Auto kitchen ticket on station | **Done** |
| Config-driven store hours | **Open** (R2) |
| Customer website same rules | **Open** (R7) |

## Phase 12 — Settings UI — **OPEN**

## Phase 13 — Offline — **OPEN**

## Phase 14 — Pilot QA — **OPEN**

Use STATUS residual R1–R9 as acceptance gate.

---

## Parallel tracks

| Track | Notes |
|-------|--------|
| HQ tax config | Unblocks R1 |
| HQ store hours | Unblocks R2 |
| Stripe Terminal lab | Optional if PaymentSheet accepted for pilot |
| Printer lab | Mock until hardware |
| Customer website | Hard release partner |

---

## Explicitly after POS polished MVP

1. **Customer website** (hard release gate partner)  
2. Scheduled orders, guest cart, live delivery tracking, full time-clock, complex inventory, iOS primary pilot  
3. Post-order survey scheduled push  

---

## Milestone tags

| Tag | Meaning | Status |
|-----|---------|--------|
| `pos-m1-shell` | Phase 2 done | **Reached** |
| `pos-m2-carryout-pay` | Phases 3–5 pilot | **Reached** |
| `pos-m3-dine-in` | Phase 6 ops | **Reached** |
| `pos-m4-delivery-staff` | Phases 7–8 | **Partial** (7 yes, 8 open) |
| `pos-m5-ops-print` | Phases 9–11 | **Partial** (10–11 yes, 9 open) |
| `pos-m6-mvp` | Phases 12–14 + residual | **Open** |

---

## Next single step

1. **HQ tax rate config** (R1) — shared rate for mobile + POS  
2. **HQ store hours config** (R2) — replace checkout hardcode  
3. Station settings UI (R6)  
4. Offline honesty (R5)  

Do not regress carry-out pickup payment timing or online in-hours kitchen path.
