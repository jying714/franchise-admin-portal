# Architecture Decision Log (DECISIONS.md)

**Last Updated**: August 15, 2026 (Decision 15 Catalog Health locked)

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
**Status**: Approved (Decision 10 executed on `main`; residual ColorScheme polish COMPLETE July 30)

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
**Status**: **Implemented & smoke-tested 2026-07-30 (test mode). Residual survey timing deferred.**  
**Summary:** Platform Stripe for HQ SaaS; Connect per franchise for **card** customer orders + application fee.  
**Cash** (on pickup / at counter) is handled by the thin POS (Decision **14**) and related feature toggles; it is not a substitute for Connect.  
**Reference:** `docs/slices/stripe-checkout-v1.md` (**COMPLETE**).

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
**Status**: **Approved — thin POS pilot COMPLETE on main**  
**Authority**: this decision · `docs/slices/pos-app-v1.md` · STATUS · HANDOFF  

**Decision summary:** Thin POS station app (not kitchen-only). Pilot Android + Ethernet ESC-POS + drawer. Release gate includes POS + customer website + polished mobile + web management. See full points in prior revision / pos-app-v1 slice.

**Reference:** `docs/slices/pos-app-v1.md`, `STATUS.md`, `HANDOFF.md`.

### 15. Catalog Health (not "schema" in the UI) — Self-serve integrity
**Date**: August 15–16, 2026  
**Status**: **Approved — implement on `feat/pre-hardware-hq-polish`**  
**Authority**: `docs/slices/catalog-health-v1.md`

**Decision**

1. **Owner-facing language:** UI uses **Catalog health** and **Fixes needed**. The word **schema** stays in code, agent docs, and engineering only.
2. **Surfaces (both):**
   - **Onboarding step** — catalog must be healthy (or guided fixes completed) before onboarding can finish.
   - **Post-onboarding** — HQ/Admin **attention card** (count + open sheet), not a permanent embedded schema editor on every form.
3. **Menu item editor (HQ + Admin):** Remove the standing schema issues card. When unresolved issues exist, show an attention control (e.g. pulsing **"N fixes needed"**) in app bar/footer; tap opens a sheet with plain-language issues and primary repair actions.
4. **Publish / save gate:**
   - **Errors block** publish/save.
   - **Warnings do not** (e.g. $0 price allowed as free item, with warning).
5. **Must-error examples:** missing category; missing ingredient ref; required modifier group unbound (`min > 0`, no options); salad profile with empty dressings `sourceTypeId`; **franchise-level duplicate ingredient types** (case-insensitive).
6. **Duplicate types:** User picks survivor **id**; **union** all ingredients onto survivor (`typeId` rewrite); **hard-delete** loser type **after** verified rewrite. Case-insensitive uniqueness on **create and rename**.
7. **Franchise-level problems (e.g. duplicate types):** **Block menu item publish** until fixed (no silent escape hatch by default).
8. **Normalize v1 scope:** types merge + orphan ingredients + menu item ref repair — one Catalog health flow with **dry-run → confirm → apply**.
9. **Scan cadence:** Auto-scan when entering Menu Items and the onboarding Catalog step (debounced/cached) + manual "Scan again".
10. **Data safety v1:** Confirm dialog with dry-run counts is enough; optional audit log later. No 24h undo required for v1.
11. **Success metric:** ≤ **5 purposeful taps** from "duplicate sauces detected" to "merge confirmed" (ideally ≤ 3 with smart defaults); first salad publishable with **zero support**.

**Rationale:** Competitors train operators on internal data models. We undercut support cost by making integrity **self-serve**, **invisible when healthy**, and **impossible to ignore when not** — so we can price below competitors while remaining polished (not "MVP-thin").

**Impact:** New slice `catalog-health-v1`; menu editor UX change; onboarding step + HQ/Admin card; type merge writes; publish gates. Aligns with Decision 10 profiles and foundation types.

**Reference:** `docs/slices/catalog-health-v1.md`, `STATUS.md`, `HANDOFF.md`, `ROADMAP.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Review before major refactors.

**Last Updated**: August 15, 2026
