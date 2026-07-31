# Thin POS (`pos_app`) — Development Plan (Phases 0–14 → polished MVP)

**Status**: Active  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · `docs/slices/pos-app-v1.md` · STATUS · HANDOFF · this file  
**Last Updated**: July 30, 2026  

Scaffold: `flutter create pos_app` + user feature tree — **PASS**.  
Next implementation: **Phase 1** shared domain foundation, then **Phase 2** PIN shell.

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

---

## Phase 0 — Repo + docs lock

| Step | Work | Exit |
|------|------|------|
| 0.1 | `feat/pos-app-v1` branch; STATUS/HANDOFF/ROADMAP/slice updated | Docs say POS is active |
| 0.2 | `flutter create pos_app` + user tree script | Empty tree + Flutter shell on disk |
| 0.3 | `pubspec.yaml` → `shared_core` path dep; `flutter pub get` | Resolves without errors |

**Status (2026-07-30):** Scaffold + schema tree **PASS**. Wire `shared_core` if not already.

**Gate:** Package builds a default counter app; no product logic required yet.

---

## Phase 1 — Shared domain foundation (before almost any POS UI)

Extend **shared_core** (and rules) only as needed. Prefer additive fields.

| Step | Work | Notes |
|------|------|------|
| 1.1 | **Order source** on every order: `pos` \| `mobile` \| `web` | Structural; metrics later |
| 1.2 | **Station order states** | `draft` → `open` / `needs_approval` → `sent_to_kitchen` → `ready` → `completed` / `cancelled` |
| 1.3 | **Staff model expansion** | PIN reference, roles, permissions list, hourly pay, active flag (extend existing `Staff`) |
| 1.4 | **Driver / waitress** lightweight models | Name + pay rate; franchise-scoped collections |
| 1.5 | **POS settings** model | Large-order threshold, max splits, PIN timeout, auto-print rules, tip prompts |
| 1.6 | **Table layout** model | 2D nodes (id, label, x, y, w, h, seats, status); path under franchise config |
| 1.7 | **Print job** minimal model | Idempotent job id, category route, status |
| 1.8 | Firestore **rules** for staff/PIN, station orders, drivers, layout, POS settings | Fail-closed; franchise-scoped |
| 1.9 | FirestoreService / providers hooks (read/write only what POS needs) | No Admin surface |

**Gate:** Models compile; rules deployed to a test project; no invented zero-arg `FranchiseProvider`.

---

## Phase 2 — P1 shell: franchise lock + PIN session + permissions

| Step | Work |
|------|------|
| 2.1 | Bootstrap: Firebase, single `FranchiseProvider`, theme from franchise seeds |
| 2.2 | Franchise bind for station (device ↔ franchiseId; no silent default tenant) |
| 2.3 | `PinSessionProvider`: unlock, idle timeout, force re-PIN on elevated actions |
| 2.4 | Permission constants + `PermissionGate` widget |
| 2.5 | `PinUnlockScreen` → station home shell (empty tiles OK) |
| 2.6 | Router: unlock → home; block routes without session |

**Gate:** Staff can PIN in, session expires, elevated action demands re-PIN; wrong franchise cannot operate.

---

## Phase 3 — Station home + open-order board (read path)

| Step | Work |
|------|------|
| 3.1 | Home: **Dine-in / Carry-out / Delivery** tiles |
| 3.2 | Open-orders stream (franchise-scoped; all sources) |
| 3.3 | Order cards: source badge, status chip, basic actions (view only) |
| 3.4 | Needs-approval queue surface (empty until thresholds exist) |

**Gate:** Online mobile/web test orders appear on the board when present; POS can open detail read-only.

---

## Phase 4 — Order entry (carry-out first)

Carry-out is the simplest full ticket path (no table, no driver).

| Step | Work |
|------|------|
| 4.1 | Category rail + menu grid from shared menu/categories |
| 4.2 | Ticket panel (lines, qty, remove, subtotal) |
| 4.3 | POS customization sheet (reuse modifier groups / sizes / profile — same schema as mobile) |
| 4.4 | Allergen callout on item + ticket line |
| 4.5 | Send → `sent_to_kitchen` (status only; print stub OK) |
| 4.6 | Persist order with `source: pos`, staff id on ticket |

**Gate:** Full carry-out ticket create → send; modifiers correct for pizza/wings/etc.; no dual menu write paths.

---

## Phase 5 — Payments (card-present + cash + drawer) — online only

| Step | Work |
|------|------|
| 5.1 | Payment screen: balance due, tender list |
| 5.2 | Cash tender + change due; **drawer kick** (mock interface first) |
| 5.3 | Card-present adapter interface; Stripe Terminal (or chosen SDK) integration |
| 5.4 | Split tenders (max from settings; default 3) |
| 5.5 | Discount sheet (permission-gated) |
| 5.6 | Complete order → `completed`; fail-closed if payment fails |
| 5.7 | Manager-only void / refund + forced re-PIN |

**Gate:** Cash path demoable without real drawer; card path works in test mode; voids require manager.

---

## Phase 6 — Dine-in: tables + open ticket / pay at close

| Step | Work |
|------|------|
| 6.1 | **Web-app** table layout editor (HQ/Admin): save layout to franchise config |
| 6.2 | POS `TableMapScreen`: consume layout; seat / clear |
| 6.3 | Open ticket on table → order entry linked to `tableId` |
| 6.4 | Pay at close (reuse payment phase); clear table on complete |

**Gate:** Owner builds a map in web; tablet seats a table, orders, pays, clears.

---

## Phase 7 — Delivery flow + driver assignment

| Step | Work |
|------|------|
| 7.1 | Delivery flow: customer + address first (lookup Auth user or lightweight POS customer) |
| 7.2 | Order entry after customer |
| 7.3 | Driver list CRUD (manager); pay rate |
| 7.4 | **Require driver assign** on delivery completion |
| 7.5 | No live tracking (out of scope) |

**Gate:** Delivery cannot complete without driver; pay-rate data stored for financials later.

---

## Phase 8 — Staff / drivers / waitresses (ops records)

| Step | Work |
|------|------|
| 8.1 | Staff list + role/permission assignment (manager) |
| 8.2 | PIN set/reset flows (secure; no plaintext in logs) |
| 8.3 | Waitress list + pay rate (parallel to drivers) |
| 8.4 | Tie active session staff to order audit fields |

**Gate:** Manager can provision a cashier PIN and role; elevated actions respect permissions.

---

## Phase 9 — Large orders + 86 + allergens honesty

| Step | Work |
|------|------|
| 9.1 | POS settings: threshold enable + amount/count |
| 9.2 | Over-threshold → `needs_approval`; hold until approve |
| 9.3 | 86 sheet: manager-only; channels mobile / website / in-store (default all) |
| 9.4 | Propagate 86 to menu availability consumers |
| 9.5 | Allergens prominent on-screen + on ticket payload |

**Gate:** Held orders cannot send/pay until approved (or feature disabled); 86 hits selected channels.

---

## Phase 10 — Printing pipeline

| Step | Work |
|------|------|
| 10.1 | Category → printer mapping in settings |
| 10.2 | Idempotent print jobs; default fallback printer (never silent drop) |
| 10.3 | Auto-print rules: card on paid; cash rules; incoming online orders |
| 10.4 | Reprint dialog; failure surfacing to manager |
| 10.5 | Ethernet ESC-POS integration on pilot hardware |

**Gate:** Kitchen ticket prints reliably; dual-submit does not double-print; failure is visible.

---

## Phase 11 — Incoming online orders (shared list)

| Step | Work |
|------|------|
| 11.1 | Auto-print on new `mobile`/`web` paid (or accepted) orders |
| 11.2 | Same open-order list + full management actions as POS-created |
| 11.3 | Source badge always visible |

**Gate:** Phone order appears on station, prints, can be advanced/voided under permissions.

---

## Phase 12 — Settings panel (first version complete)

| Step | Work |
|------|------|
| 12.1 | Large-order threshold + enable |
| 12.2 | Max split tenders |
| 12.3 | Prep / promised time |
| 12.4 | PIN session timeout |
| 12.5 | Auto-print rules |
| 12.6 | Default tip prompts |

**Gate:** All Decision 14 settings exist and persist franchise-scoped.

---

## Phase 13 — Offline + station honesty

| Step | Work |
|------|------|
| 13.1 | Connectivity provider; offline banner |
| 13.2 | Offline = **cash only**; block card + online intake |
| 13.3 | When POS down, customer channels reflect “cannot accept new orders” (feature flag / config write) |
| 13.4 | Queue/sync policy for cash tickets created offline (define and test) |

**Gate:** Pulling network drops card path; cash still works; honesty message path defined.

---

## Phase 14 — Hardening, QA, pilot polish

| Step | Work |
|------|------|
| 14.1 | Permission matrix test (each elevated action) |
| 14.2 | Menu regression: pizza / wings / calzone / standard profiles on POS |
| 14.3 | Multi-printer + drawer + Terminal on **Android tablet** pilot |
| 14.4 | Error surfaces, empty states, session timeout UX |
| 14.5 | Performance: menu load, open-order stream under load |
| 14.6 | Security review: PIN storage, rules, no secret logging |
| 14.7 | Integration test: android pilot smoke |
| 14.8 | Slice acceptance checklist in `pos-app-v1.md` all checked |
| 14.9 | STATUS/HANDOFF: POS MVP complete; remaining gate = customer website |

**Gate:** Acceptance criteria in slice §4 all pass on pilot hardware.

---

## Parallel tracks (do not reorder hard dependencies)

| Track | Can overlap with | Blocked until |
|-------|------------------|---------------|
| Web table layout editor | Phase 4–5 | Phase 1 layout model |
| Stripe Terminal sandbox | Phase 4 | Phase 5 payment interface |
| Printer lab setup | Phase 4–8 | Phase 10 for production rules |
| Staff seed data for Doughboys | Phase 2+ | Phase 1 staff schema |

---

## Explicitly after POS polished MVP

1. **Customer website** (hard release gate partner)
2. Guest cart, live delivery tracking, full time-clock, complex inventory, iOS primary pilot
3. Post-order survey scheduled push (deferred from Stripe slice)

---

## Milestone tags

| Tag | Meaning |
|-----|---------|
| `pos-m1-shell` | Phase 2 done |
| `pos-m2-carryout-pay` | Phases 4–5 done |
| `pos-m3-dine-in` | Phase 6 done |
| `pos-m4-delivery-staff` | Phases 7–8 done |
| `pos-m5-ops-print` | Phases 9–11 done |
| `pos-m6-mvp` | Phases 12–14 done — polished MVP |

---

## Next single step

**Phase 1.1–1.3 in shared_core:** order `source` + station statuses + staff PIN/permissions fields, with rules — then Phase 2 PIN shell in `pos_app`.

Do not build payment UI or table map before session + order entry foundations exist.
