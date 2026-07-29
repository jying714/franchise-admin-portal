# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 29, 2026 (Decision 13 — kitchen ops + cash on pickup)

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
**Note:** Kitchen thin app is an **ops station surface**, not a fifth full dashboard; staff/manager roles gate actions (Decision 13).

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
**Status**: **Approved — implementation not started**  
**Summary:** One customer binary; session = one `franchiseId`; QR/SMS primary + directory foundation; signed-out browse until checkout; cart clear on switch.  
**Reference:** `docs/slices/customer-franchise-context-v1.md`.

### 12. Payments — Platform Stripe + Connect per Franchise
**Date**: July 29, 2026  
**Status**: **Approved — implementation not started**  
**Summary:** Platform Stripe for HQ SaaS; Connect per franchise for **card** customer orders + application fee.  
**Cash on pickup** is a separate fulfillment mode under Decision **13**, not a substitute for Connect.  
**Reference:** `docs/slices/stripe-checkout-v1.md`.

### 13. Kitchen Ops — Thin App, Print Routing, Cash Feature Toggles
**Date**: July 29, 2026  
**Status**: **Approved — implementation not started**  
**Decision:**

1. **Not a full POS for MVP.** Kitchen visibility and printing via a **thin dedicated Flutter Kitchen app** (make-line tablet), not full Admin on the pass device. Cooks must not access menu/promos/users/Stripe/refunds accidentally.
2. **Primary kitchen UI:** Live franchise-scoped orders; limited forward status actions; reprint; printer/connectivity honesty. **Void / cancel / refund: manager-only.**
3. **Placement:** DoorDash-like — tablet above make line, printer beside it. **Pilot hardware: Android tablet** (kiosk + printer ecosystem). **Codebase remains Flutter multi-platform**; iOS kitchen station is post-pilot unless explicitly pulled in.
4. **Printing:**
   - Prefer **Ethernet ESC-POS** (Star/Epson-class) for reliability.
   - **Multi-printer ready:** map **menu category id(s) → printer(s)**; many categories per printer; unmapped → default printer (never silent drop).
   - **Card orders:** auto-print when order reaches **`paid`** (Connect).
   - **Cash orders:** see feature toggles below.
5. **Cash on pickup (v1 yes):**
   - Franchise **Admin dashboard feature card** (same family as Inventory and other feature toggles): master **`cashOnPickup`** (name TBD in implementation).
   - When ON: customer checkout may select cash on pickup; tickets/board show **PAY CASH** clearly.
   - **Sub-toggle** (only if master ON): **`cashPrintOnAcceptOnly`** — when ON, print cash tickets only after cook **Accept**; when OFF (**default**), **print on submit**.
6. **Manager safety net:** Push + SMS to assigned manager(s) on kitchen tablet offline (heartbeat) and print failures. Admin on manager phone is **backup**, not the make-line system of record.
7. **Full POS** (cash drawer, card-present terminal suite, complex table service): **out of MVP.**

**Rationale:** Personal pizzeria pilot needs DoorDash-class kitchen loop without giving line cooks full Admin; cash remains cultural reality behind flags; multi-printer by category matches real stations.  
**Impact:** New kitchen app target/flavor; Admin feature toggles; franchise printer config; order status/print job idempotency; notification path.  
**Reference:** `docs/slices/kitchen-ops-v1.md`, `STATUS.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Review before major refactors.

**Last Updated**: July 29, 2026
