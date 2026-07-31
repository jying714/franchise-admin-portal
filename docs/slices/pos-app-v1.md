# Slice: POS App v1 (Thin Counter Station)

**Status**: **Active** (product approved July 30, 2026 — implementation open)  
**Branch**: `feat/pos-app-v1`  
**Authority**: Decision **14** · STATUS · HANDOFF · this file  
**Depends on**: Decision 12 (Stripe Connect + card-present path) **COMPLETE**; franchise-scoped orders; shared_core menu/modifier system; Admin feature-toggle patterns; mobile+web residual polish **COMPLETE**  
**Pilot device**: **Android tablet** at counter; Flutter multi-platform codebase retained; iOS station post-pilot  
**Supersedes**: Pure kitchen-only framing of Decision 13 / `kitchen-ops-v1.md`

---

## 1. Problem

A standalone thin Kitchen management app will not be used long-term and does not make the product market-viable. Typical single-owner restaurants need a **counter / order-taking station** that can:

- Create and manage dine-in, carry-out, and delivery orders
- Accept card-present and cash (with drawer)
- Seat tables from an owner-defined layout
- Send tickets to kitchen printers
- Track staff / driver / waitress participation for financials
- 86 items across channels and surface allergens clearly

The station must stay thin enough to ship after Stripe and mobile/web polish, while being the intentional foundation for later expansion.

---

## 2. Product locks

### App target & placement

| Item | Lock |
|------|------|
| Target / flavor | `pos_app` (new Flutter target) |
| Primary placement | Counter / order-taking station |
| Hardware pilot | Android tablet + Ethernet ESC-POS printer(s) in kitchen(s) + cash drawer (printer kick) + card-present reader |
| Codebase | Flutter multi-platform retained |

### Home & order types

- **Dine-in** → full custom 2D table map (built in web-app) → seat table → open ticket → order → close & pay at end of meal
- **Carry-out** / **Delivery** → shared order-creation flow
- **Delivery** first collects customer + address (auto-fill name + phone + address when known)

### Order creation & incoming orders

- Full menu + existing modifier system (reuse mobile_app / shared_core patterns)
- Incoming mobile / website orders: **auto-print**, appear in same open-order list, full management actions available
- Order source field (structural: `pos` | `mobile` | `web` | …) for future metrics

### Payments & drawer

- Card-present required in thin MVP
- Cash tender + **automatic cash-drawer open** on cash sale
- Explicit open-drawer remains a permission
- Split tenders: manager-configurable max (default **3**); card + cash supported
- Discount UI (percentage / fixed amount) in MVP
- Dine-in: open ticket, settle at end of meal

### Large orders

- Manager sets threshold (dollar amount and/or item count) in settings, or disables entirely
- Over-threshold orders enter **`needs_approval`** and stay held until manager approves

### 86’ing & allergens

- 86: **manager-only**; dialog chooses channels (mobile, customer website, in-store); all selected by default
- Allergens: sourced from existing menu-item data; **prominent on printed tickets**; high-visibility badge/section on-screen

### Staff, roles, PIN, drivers, waitresses

- PIN session model: unlock once, session timeout; forced re-PIN on void / refund / 86 / large-order approval / settings
- Manager creates roles and assigns permissions from the defined list
- Thin staff records: roles + hourly pay + critical-only fields
- **Separate lightweight driver list** (name + pay rate) — assignment required on delivery completion (critical for financials)
- **Separate lightweight waitress list** (name + pay rate) — same financial tracking need
- No live delivery status tracking in MVP

### Order states (MVP)

`draft` → `open` / `needs_approval` → `sent_to_kitchen` → `ready` → `completed` / `cancelled`  
+ driver assigned at completion for delivery orders

### Printing

- Multi-printer ready; route by menu category → printer(s); default fallback (never silent drop)
- Prefer Ethernet ESC-POS; idempotent print jobs
- Absorbs prior cash/print toggle rules (card on `paid`; cash rules via settings / toggles)

### Offline

- Cash orders only when offline
- Card and receiving mobile/website orders require online
- If POS is down, customer channels should reflect that new orders cannot be accepted

### Customer identity

- Prefer link to existing Auth users (mobile / future website)
- Fallback: lightweight POS customer (name + phone + address)
- Autofill MVP = name + phone + address
- Every order carries source + optional customer/user reference

### Permissions (model supports all; elevated protected)

- take_order
- take_payment
- open_drawer
- void_item / void_order
- refund
- discount
- 86_item
- view_orders
- manage_tables
- change_settings
- approve_large_order
- manager_override

### Settings panel (first version)

- Large-order threshold + enable/disable
- Max split tenders (default 3)
- Prep / promised time
- PIN session timeout
- Auto-print rules
- Default tip prompts

### Table map

- Full custom 2D footprint (tables, walls, etc.) built **only in web-app**
- POS tablet consumes the saved layout for seating / clearing / open tickets

---

## 3. Workstreams (high level)

| ID | Deliverable | Status |
|----|-------------|--------|
| **P0** | Docs lock (this file + Decision 14) | **Done** |
| **P1** | `pos_app` target/shell: auth, franchise lock, PIN session, role permissions | **Next** |
| **P2** | Staff / driver / waitress lightweight records + pay rates | Open |
| **P3** | Web-app 2D table layout editor + POS consume/seat/clear | Open |
| **P4** | Order creation (full menu + modifiers) + dine-in open ticket / close-at-end | Open |
| **P5** | Carry-out / Delivery flows + customer auto-fill + driver assignment | Open |
| **P6** | Payments: card-present + cash + drawer + split tenders + discount UI | Open |
| **P7** | Large-order threshold + needs_approval + manager approve | Open |
| **P8** | 86 multi-channel + allergen display (ticket + on-screen) | Open |
| **P9** | Printing pipeline (category routing, idempotency, auto-print rules) | Open |
| **P10** | Incoming online orders (auto-print + shared list + management) | Open |
| **P11** | Settings panel (first version) | Open |
| **P12** | Offline cash-only path + customer-channel honesty when POS down | Open |
| **P13** | Android pilot smoke + acceptance | Open |

**Prerequisites satisfied (July 30, 2026):** Stripe checkout v1 COMPLETE; mobile+web residual polish COMPLETE on `main`.

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

## 5. Out of scope (this slice)

- Live delivery status tracking
- Full catering packages
- Complex inventory / recipe costing
- Advanced tips pooling or full time-clock beyond basic hourly
- Rich offline card processing
- iOS as primary pilot device
- Replacing Decision 11 / 12
- Customer website implementation itself (separate surface; only origin awareness + 86 channel here)

---

## 6. Sequencing note

1. ~~Finish Stripe checkout v1 (Decision 12)~~ **DONE**
2. ~~Polish mobile_app + web-app management~~ **DONE**
3. **Implement `pos_app` per this slice** ← current
4. Customer website (separate decision/slice) remains part of the hard release gate alongside thin POS

---

## 7. Bottom line

**Thin counter POS** (`pos_app`) replaces a pure kitchen-only app. Full order entry, dine-in tables (web-app 2D editor), card + cash + drawer, split tenders, discounts, large-order holds, multi-channel 86, allergens, staff/driver/waitress pay tracking, and shared online-order list. Manager-only destructive actions. Android pilot. Hard release gate includes customer website. shared_core reuse is mandatory.

**Start here:** P1 — scaffold `pos_app`, franchise lock, PIN session, role permissions.
