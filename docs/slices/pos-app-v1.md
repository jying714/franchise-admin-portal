# Slice: POS App v1 (Thin Counter Station)

**Status**: **Active** — Phases 0–4 + cash pickup close-out **smoke PASS** (2026-07-30)  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · STATUS · HANDOFF · this file · **`docs/plans/pos-app-v1-development-plan.md`**  
**Depends on**: Decision 12 **COMPLETE**; franchise-scoped orders; shared_core menu/modifier system; mobile+web residual polish **COMPLETE**  
**Pilot device**: **Android tablet** at counter; Flutter multi-platform retained; iOS station post-pilot  
**Smoke device used**: Samsung S25 (Android 16)  
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
| Payments | Card-present + cash + drawer; splits; discounts |
| **Carry-out pay timing** | **Pay at pickup** (open board → Take payment), **not** at send |
| Large orders | Optional threshold → `needs_approval` |
| 86 | Manager-only; multi-channel |
| Staff | PIN session; roles; permissions; drivers/waitresses pay rates |
| States | `draft` → `open` / `needs_approval` → `sent_to_kitchen` → `ready` → `completed` / `cancelled` |
| Print | Multi-printer by category; idempotent; never silent drop |
| Offline | Cash only |
| Source | Every order carries `pos` \| `mobile` \| `web` |

Permissions: take_order, take_payment, open_drawer, void_item/void_order, refund, discount, 86_item, view_orders, manage_tables, change_settings, approve_large_order, manager_override.

---

## 3. Workstreams mapped to development plan

Full ordered plan: **`docs/plans/pos-app-v1-development-plan.md`** (Phases 0–14).

| Plan phase | Slice workstreams | Status |
|------------|-------------------|--------|
| 0 | P0 docs + Flutter scaffold + tree | **PASS** |
| 1 | shared_core models + rules + PosFirestoreService | **PASS** |
| 2 | P1 shell: franchise lock, PIN, permissions, station Auth | **PASS** (smoke) |
| 3 | Home + open-order board + centered action dialog | **PASS** (smoke) |
| 4 | Carry-out entry + Decision 10 modifiers + send | **PASS** (smoke) |
| 5 | Payments | **Partial** — cash Take payment PASS; card/drawer/splits/discount/re-PIN open |
| 6 | Table map + dine-in ticket | Open |
| 7 | Delivery + driver | Open |
| 8 | Staff/driver/waitress UI | Open (models exist) |
| 9 | Large order + 86 | Open |
| 10 | Printing | Open |
| 11 | Incoming online | Open (board can list when rules allow) |
| 12 | Settings panel UI | Open (model exists) |
| 13 | Offline | Open |
| 14 | Pilot acceptance | Open |

---

## 4. Acceptance (implementation)

- [x] Counter can create **carry-out** orders (menu + modifiers) and send to kitchen with `source: pos`
- [ ] Counter can create full orders for **dine-in** / **delivery**
- [ ] Dine-in uses owner-defined 2D table map; open ticket; pay at close
- [x] **Cash** take-payment from open orders (pickup close-out)
- [ ] Card-present and cash **drawer** hardware; split tenders respect max setting
- [ ] Discount UI functional under permission
- [ ] Large-order hold + manager approve (or feature disabled)
- [ ] 86 with channel selection; allergens prominent on ticket and on-screen (dialog shows allergens only today)
- [ ] Driver assignment required on delivery completion; pay-rate data recorded
- [x] PIN session + role permissions gate actions (void/pay/take_order); forced re-PIN UI still incomplete
- [ ] Incoming online orders auto-print and appear in shared list
- [ ] Multi-printer category routing + default fallback; no silent drop
- [ ] Offline limited to cash; customer channels reflect POS-down state
- [x] No full Admin / menu editing / promo / user admin on the tablet
- [x] Android path smoke-tested (S25); tablet pilot still open

---

## 5. Out of scope

Live delivery tracking; full catering; complex inventory/recipe costing; advanced tips pooling / full time-clock; rich offline card; iOS as primary pilot; replacing Decision 11/12; customer website implementation itself.

---

## 6. Sequencing

1. ~~Stripe checkout v1~~ **DONE**  
2. ~~Mobile + web residual polish~~ **DONE**  
3. ~~pos_app scaffold + tree~~ **PASS**  
4. ~~Phase 1–4 + cash close-out~~ **PASS** (2026-07-30)  
5. **Phase 5 remainder / Phase 6 / Phase 7** ← choose next  
6. Customer website (separate; hard release gate)

---

## 7. Implementation notes (for agents)

- Modifier UI must use real fields: `ModifierGroup.label`, `min`/`max`, `selectMode`, `ModifierOption.label`, `defaultSelected`.
- `MenuItem` availability filter: `availability && available && !archived && hideInMenu != true` (no `isAvailable` getter).
- Hide Firestore `Order` name clash: `import 'package:cloud_firestore/cloud_firestore.dart' hide Order;`.
- Prefer `Provider.of<T>(context, listen: false)` when `context.read` is ambiguous with shared_core extensions.
- Never `FranchiseProvider()` zero-arg — requires `LocalStorage`.

---

## 8. Bottom line

**Thin counter POS** replaces pure kitchen-only app. Carry-out loop is live on Android: PIN → menu/modifiers → send → board → cash pay at pickup. Continue payments depth or dine-in/delivery per plan. shared_core reuse is mandatory. Hard release gate still includes customer website.
