# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 30, 2026 (Decision 14 — Thin POS Station App supersedes pure kitchen framing)

This file records major architectural and design decisions for the Doughboys Pizzeria Franchise Platform.

## Decision Log

### 1. Hybrid Single/Multi-Location Support
**Date**: July 2026  
**Status**: Approved  
**Decision**: Hybrid single/multi-location ops UI.  
**Note:** Customer multi-tenant selection is Decision **11**.

### 2. Unified Config System in shared_core + Firestore
**Date**: July 2026  
**Status**: Approved  
**Reference**: `/docs/architecture/firestore-per-franchise-config.md`

### 3. Design & Branding Management
**Date**: July 2026  
**Status**: Approved (Decision 8 delivered)

### 4. Mobile App Dynamic UI
**Date**: July 2026  
**Status**: Approved (Decision 10 executed on `main`)

### 5. Multi-Agent Development Approach
**Date**: July 2026  
**Status**: Approved

### 6. Dashboard Roles
**Date**: July 2026  
**Status**: Approved  
**Reference**: `docs/DASHBOARDS.md`  
**Note:** Station surface is now the thin POS app (Decision **14**), not a pure kitchen-only app. Staff/manager roles and permissions gate actions.

### 7. Onboarding Home = HQ Owner Dashboard (not Admin)
**Date**: July 24–25, 2026  
**Status**: **Implemented**

### 8. HQ Design & Branding v1 / v1.1
**Date**: July 24–25, 2026  
**Status**: **Complete**

### 9. Admin Menu vs HQ Menu Items (surface split)
**Date**: July 27–28, 2026  
**Status**: **Approved + implemented**

### 10. Menu Modifier System — Full Rebuild
**Date**: July 27–28, 2026  
**Status**: **Complete on `main`**  
**Reference**: `docs/slices/menu-modifier-system-rebuild-v1.md`, `docs/slices/hq-wings-calzone-v1.md`.

### 11. Customer App — Hybrid Multi-Tenant Binary & Franchise Context
**Date**: July 29, 2026  
**Status**: **Complete on `main`**  
**Summary:** One customer binary; session = one `franchiseId`; QR/SMS/https primary + directory foundation; signed-out **menu browse**; **add-to-cart / cart / checkout require auth** (cart is user-scoped in Firestore; guest cart deferred); cart clear on switch; single `FranchiseBindService` pipeline.  
**Reference:** `docs/slices/customer-franchise-context-v1.md`.

### 12. Payments — Platform Stripe + Connect per Franchise
**Date**: July 29, 2026  
**Status**: **Approved — implementation in progress** (`feat/stripe-checkout-v1`)  
**Summary:** Platform Stripe for HQ SaaS; Connect per franchise for **card** customer orders + application fee.  
**Cash** (on pickup / at counter) is handled by the thin POS (Decision **14**) and related feature toggles; it is not a substitute for Connect.  
**Reference:** `docs/slices/stripe-checkout-v1.md`.

### 13. Kitchen Ops — Thin App, Print Routing, Cash Feature Toggles (HISTORICAL / PARTIALLY SUPERSEDED)
**Date**: July 29, 2026  
**Status**: **Superseded in framing by Decision 14 (July 30, 2026)**  
**Original decision (retained for cash/print toggle context):**

1. Originally framed as **not a full POS for MVP** — thin dedicated Flutter Kitchen app (make-line tablet).
2. Live franchise-scoped orders; limited forward status; reprint; printer honesty. **Void / cancel / refund: manager-only.**
3. Placement was DoorDash-like make-line. Pilot hardware Android tablet.
4. Printing: Ethernet ESC-POS preferred; multi-printer by menu category; card auto-print on `paid`; cash print rules via Admin toggles.
5. Cash on pickup master + sub-toggle for print-on-accept.
6. Manager push + SMS on offline / print failure.
7. Full POS (cash drawer, card-present, complex table service) was marked out of MVP.

**Rationale at the time:** Safe cook-facing board without full Admin blast radius.

**Supersession note (July 30, 2026):** Product direction changed. A pure kitchen-only management app will not be shipped as a long-term surface. The station surface is now the **thin POS app** (Decision 14). Cash-on-pickup toggles, multi-printer category routing, manager-only destructive actions, and print rules remain valid and are absorbed into the POS slice. Do not implement a separate kitchen-only binary.

**Reference (historical):** `docs/slices/kitchen-ops-v1.md` (marked superseded).

### 14. Thin POS Station App (`pos_app`) — Counter-Focused MVP Station
**Date**: July 30, 2026  
**Status**: **Approved — implementation not started** (docs locked)  
**Authority**: this decision · `docs/slices/pos-app-v1.md` · STATUS · HANDOFF  

**Decision summary:**

1. **Strike the standalone thin Kitchen management app** as the MVP station surface. Replace it with a **thin POS app** (`pos_app` Flutter target/flavor) whose primary placement is the **counter / order-taking station**.
2. **Pilot hardware**: Android tablet + Ethernet ESC-POS printer(s) in kitchen(s) + cash drawer (printer-kick) + card-present reader (Stripe Terminal or equivalent). Codebase remains Flutter multi-platform; iOS station post-pilot.
3. **Release gate (hard)**: The overall product is **not** considered releasable until **thin POS + customer website + polished mobile_app + web-app management** are all at MVP quality.
4. **Order types on home**: Dine-in, Carry-out, Delivery.
   - Dine-in → full custom 2D table map (owner builds layout in web-app) → seat → open ticket → close & pay at end of meal.
   - Carry-out / Delivery share order-creation flow; Delivery first collects customer + address (auto-fill name/phone/address when known).
5. **Order creation**: Full menu + existing modifier system (reuse mobile_app / shared_core patterns).
6. **Incoming online orders** (mobile / future website): auto-print, appear in the same open-order list, full management actions available.
7. **Payments**: Card-present required; cash + automatic drawer open on cash tender; split tenders (manager-configurable max, default 3); discount UI (percentage/fixed) in MVP.
8. **Large orders**: Manager sets threshold (amount and/or item count) or disables; over-threshold orders enter `needs_approval` and stay held until approved.
9. **86’ing**: Manager-only; dialog chooses channels (mobile, customer website, in-store); all selected by default.
10. **Allergens**: From existing menu-item data; prominent on printed tickets; high-visibility on-screen.
11. **Staff / roles / PIN**: PIN session model (session timeout; forced re-PIN on void/refund/86/large-order/settings). Manager can create roles and assign permissions from the defined list. Thin staff records include roles + hourly pay + critical fields only. Separate lightweight driver and waitress lists (name + pay rate) for financial tracking.
12. **Driver assignment**: Required on delivery order completion (critical for pay). No live delivery status tracking in MVP.
13. **Order states (MVP)**: `draft` → `open` / `needs_approval` → `sent_to_kitchen` → `ready` → `completed` / `cancelled` (+ driver assigned at completion for delivery).
14. **Offline**: Cash orders only when offline. Card and receiving mobile/website orders require online. If POS is down, customer channels should reflect inability to accept new orders.
15. **Printing**: Multi-printer by menu category (or default); Ethernet ESC-POS preferred; idempotent print jobs. Absorbs prior cash/print toggle thinking.
16. **Customer identity**: Prefer link to existing Auth users; fallback lightweight POS customer (name + phone + address). Every order carries source + optional customer/user reference.
17. **Permissions model** (elevated actions protected): take_order, take_payment, open_drawer, void_item/void_order, refund, discount, 86_item, view_orders, manage_tables, change_settings, approve_large_order, manager_override.
18. **Settings panel (first version)**: large-order threshold + enable/disable; max split tenders; prep/promised time; PIN session timeout; auto-print rules; default tip prompts.
19. **Explicitly out of this MVP**: live delivery status tracking, full catering packages, complex inventory/recipe costing, advanced tips pooling or full time-clock, rich offline card processing, iOS as primary pilot device, complex multi-station orchestration beyond category→printer.

**Rationale:** A pure kitchen-only app would not be used long-term and would not make the product market-viable. A counter-focused thin POS that can take orders, accept card + cash, open a drawer, seat tables, assign drivers, and reuse shared_core is the correct station surface. It starts thin enough to ship after Stripe and mobile/web polish, then expands.

**Impact:** New `pos_app` target; web-app table-layout editor; staff/driver/waitress lightweight records; order source + customer linkage; expanded order states; permission model; absorption of prior kitchen print/cash rules; hard release gate includes customer website.

**Reference:** `docs/slices/pos-app-v1.md`, `STATUS.md`, `HANDOFF.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Review before major refactors.

**Last Updated**: July 30, 2026
