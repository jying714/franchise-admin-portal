# Slice: POS App v1 (Thin Counter Station)

**Status**: **Active** — pilot baseline **smoke PASS** (2026-08-01); residual list blocks “MVP complete”  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · STATUS · HANDOFF · this file · **`docs/plans/pos-app-v1-development-plan.md`**  
**Depends on**: Decision 12 **COMPLETE**; franchise-scoped orders; shared_core menu/modifier system; mobile+web residual polish **COMPLETE**  
**Pilot device**: **Android tablet** at counter; Flutter multi-platform retained; iOS station post-pilot  
**Smoke devices**: Samsung S25; tablet `R52WA09Z7XV` (Stripe)  
**Supersedes**: Pure kitchen-only framing of Decision 13 / `kitchen-ops-v1.md`

---

## 1. Problem

A standalone thin Kitchen management app will not be used long-term and does not make the product market-viable. Typical single-owner restaurants need a **counter / order-taking station** that can create dine-in, carry-out, and delivery orders; accept card-present and cash (with drawer); seat tables from an owner-defined layout; print to kitchen; track staff/driver/waitress pay participation; 86 across channels; and surface allergens clearly.

---

## 2. Product locks

(Unchanged — Decision 14.) Summary:

| Area | Lock |
|------|------|
| Target | `pos_app` counter station |
| Order types | Dine-in (2D map), Carry-out, Delivery |
| Menu | Full shared modifier system — no second tree |
| Payments | Card (PaymentSheet interim / Terminal later) + cash + drawer; splits; discounts |
| **Carry-out pay timing** | **Pay at pickup** (open board → Take payment), **not** at send |
| Online (MVP) | In store hours → `sent_to_kitchen` immediately; scheduled post-MVP |
| Large orders | Optional threshold → `needs_approval` |
| 86 | Manager-only; multi-channel |
| Staff | PIN session; roles; permissions; drivers/waitresses pay rates |
| States | `draft` → `open` / `needs_approval` → `sent_to_kitchen` → `ready` → `completed` / `cancelled` |
| Print | Mock now; multi-printer by category later; never silent drop of order |
| Offline | Cash only (not implemented) |
| Source | Every order carries `pos` \| `mobile` \| `web` |

---

## 3. Workstreams mapped to development plan

| Plan phase | Status |
|------------|--------|
| 0–4 | **PASS** |
| 5 Payments | **PASS (pilot software)** — Terminal residual |
| 6 Dine-in | **PASS (ops)** |
| 7 Delivery | **PASS (ops)** |
| 8 Staff UI | **Open** |
| 9 Large/86 | **Open** |
| 10 Printing | **PASS (mock)** |
| 11 Online intake | **PASS (MVP)** |
| 12 Settings UI | **Open** |
| 13 Offline | **Open** |
| 14 Pilot QA | **Open** |

---

## 4. Acceptance (implementation)

- [x] Counter can create **carry-out** orders and send to kitchen with `source: pos`
- [x] Counter can create **dine-in** / **delivery** orders (ops baseline)
- [x] Dine-in floor map + open ticket paths in use
- [x] **Cash** / **split** take-payment from open orders
- [x] **Card** via Connect PaymentIntent + PaymentSheet (software; not Terminal)
- [x] Discount UI under permission; pre-tax stack
- [x] Refund skeleton (full cash; closed board; re-PIN)
- [x] Closed orders board (filters + date range)
- [x] PIN session + permissions; forced re-PIN on refund/void paths
- [x] Incoming **mobile** orders in-hours → kitchen + auto mock ticket
- [x] Outside-hours mobile place-order blocked (hardcoded hours)
- [ ] HQ tax rate config (still provisional 9.25%)
- [ ] HQ store hours config
- [ ] Card-present **Terminal** hardware (optional waiver for software pilot)
- [ ] Real drawer / ESC-POS hardware
- [ ] Large-order hold + manager approve
- [ ] 86 multi-channel
- [ ] Staff/driver/waitress **manager UI**
- [ ] Multi-printer category routing
- [ ] Offline limited to cash + honesty UI
- [ ] Station settings panel
- [x] No full Admin / menu editing on the tablet
- [x] Android path smoke-tested

---

## 5. Residual list (2026-08-01)

| ID | Item |
|----|------|
| R1 | Franchise tax rate from config |
| R2 | Franchise store hours from config |
| R3 | Stripe Terminal (or explicit pilot waiver of PaymentSheet-only) |
| R4 | Real printers |
| R5 | Offline honesty |
| R6 | Station settings UI |
| R7 | Customer website (hard release — separate slice) |
| R8 | Staff bootstrap documentation |
| R9 | Phase 14 smoke script sign-off |

---

## 6. Out of scope

Scheduled orders; live delivery tracking; full catering; complex inventory; advanced tips pooling / full time-clock; rich offline card; iOS as primary pilot; replacing Decision 11/12; customer website implementation itself (listed as residual gate, not this slice’s code).

---

## 7. Sequencing

1. ~~Stripe + mobile/web polish~~ **DONE**  
2. ~~POS shell + carry-out + money pilot + print mocks + online intake~~ **DONE** (2026-08-01)  
3. **Config residual** (tax, hours) + settings + offline  
4. Customer website  
5. Hardware (Terminal, printers) as available  
6. Phase 14 acceptance  

---

## 8. Implementation notes (for agents)

- Modifier UI: real Decision 10 fields only.  
- `import 'package:cloud_firestore/cloud_firestore.dart' hide Order;`.  
- Never `FranchiseProvider()` zero-arg.  
- `tableLabel` is POS doc merge field — not an `Order` model getter.  
- Card path: `createOrderPaymentIntent` + PaymentSheet; mock reader fallback only when PK missing / payments disabled.  
- Android: `FlutterFragmentActivity` + AppCompat/MaterialComponents **day and night** themes.  

---

## 9. Bottom line

**Thin counter POS** pilot path is live on Android: PIN → order types → kitchen → cash/split/card → closed/refund; mobile in-hours kitchen intake with auto ticket. Do **not** claim POS MVP complete until residual R1–R9 are done or waived. Hard release gate still includes **customer website**.
