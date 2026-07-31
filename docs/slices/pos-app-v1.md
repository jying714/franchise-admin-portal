# Slice: POS App v1 (Thin Counter Station)

**Status**: **Active** (product approved July 30, 2026 — scaffold PASS; Phase 1 next)  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · STATUS · HANDOFF · this file · **`docs/plans/pos-app-v1-development-plan.md`**  
**Depends on**: Decision 12 **COMPLETE**; franchise-scoped orders; shared_core menu/modifier system; mobile+web residual polish **COMPLETE**  
**Pilot device**: **Android tablet** at counter; Flutter multi-platform retained; iOS station post-pilot  
**Supersedes**: Pure kitchen-only framing of Decision 13 / `kitchen-ops-v1.md`

**Scaffold (2026-07-30):** `flutter create pos_app` + full user feature directory tree — **PASS**.

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
| 1 | shared_core models + rules | **Next** |
| 2 | P1 shell: franchise lock, PIN, permissions | Open |
| 3 | Home + open-order board | Open |
| 4 | P4/P5 carry-out entry + modifiers | Open |
| 5 | P6 payments | Open |
| 6 | P3 table map + dine-in ticket | Open |
| 7 | P5 delivery + driver | Open |
| 8 | P2 staff/driver/waitress UI | Open |
| 9 | P7 + P8 large order + 86 | Open |
| 10 | P9 printing | Open |
| 11 | P10 incoming online | Open |
| 12 | P11 settings | Open |
| 13 | P12 offline | Open |
| 14 | P13 pilot acceptance | Open |

---

## 4. Acceptance (implementation)

- [ ] Counter can create full orders (menu + modifiers) for dine-in / carry-out / delivery
- [ ] Dine-in uses owner-defined 2D table map; open ticket; pay at close
- [ ] Card-present and cash + drawer work; split tenders respect max setting
- [ ] Discount UI functional under permission
- [ ] Large-order hold + manager approve (or feature disabled)
- [ ] 86 with channel selection; allergens prominent on ticket and on-screen
- [ ] Driver assignment required on delivery completion; pay-rate data recorded
- [ ] PIN session + role permissions enforce elevated actions
- [ ] Incoming online orders auto-print and appear in shared list
- [ ] Multi-printer category routing + default fallback; no silent drop
- [ ] Offline limited to cash; customer channels reflect POS-down state
- [ ] No full Admin / menu editing / promo / user admin on the tablet
- [ ] Android tablet pilot path documented

---

## 5. Out of scope

Live delivery tracking; full catering; complex inventory/recipe costing; advanced tips pooling / full time-clock; rich offline card; iOS as primary pilot; replacing Decision 11/12; customer website implementation itself.

---

## 6. Sequencing

1. ~~Stripe checkout v1~~ **DONE**  
2. ~~Mobile + web residual polish~~ **DONE**  
3. ~~pos_app scaffold + tree~~ **PASS**  
4. **Phase 1 shared_core foundation** ← **NOW**  
5. Phase 2–14 per development plan  
6. Customer website (separate; hard release gate)

---

## 7. Bottom line

**Thin counter POS** replaces pure kitchen-only app. Scaffold is up. Execute **`docs/plans/pos-app-v1-development-plan.md`** starting at Phase 1. shared_core reuse is mandatory. Hard release gate still includes customer website.
