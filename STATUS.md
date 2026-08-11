# STATUS.md — Live Project Snapshot

**Last Updated**: August 10, 2026 (~21:30 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`main`** (soft-release); burn-in: **`feat/manager-burn-in-fixes`**  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | **On main** |
| Storefront shell Wave 1 | **COMPLETE** |
| **Modern storefront template** | **COMPLETE** |
| **Modern polish** | **COMPLETE** |
| Home composition engine Wave 2 | **Deferred** |
| **Inventory v1 (MVP-Ops)** | **COMPLETE on main** |
| **Staff/labor v1 (MVP-Ops)** | **COMPLETE on main** |
| Station `stationFranchise` claims | **COMPLETE** |
| POS clock gates | **COMPLETE** |
| **Portal users (HQ)** | **COMPLETE** — invite create/accept, pending/revoke, RoleGuard HQ-only, Quick Link |
| **Station staff permissions editor** | **COMPLETE** — role defaults + per-person grants; list shows grants |
| **POS delivery close-out** | **COMPLETE** — Accept & deliver → in route → Returned → Close out (cash); card needs manager_override |
| **Promos / Codes + Banners v1** | **COMPLETE on main** — shared engine, Admin templates, daypart, mobile+web apply, banner→pending code |
| Station POS hardware · iOS Mac | **In transit** |
| Soft parallel / manager burn-in | **Active** — authority `docs/slices/manager-burn-in-v1.md` on `feat/manager-burn-in-fixes` |
| Portal invite email (SendGrid) | **Wired**; blocked on SendGrid **credits** until go-live billing |

---

## Owner.com cutover gates (Doughboys)

| Gate | Plan | Status |
|------|------|--------|
| **Inventory** | `docs/plans/mvp-ops-inventory-v1.md` | **COMPLETE** |
| **Staff/labor** | `docs/plans/mvp-ops-staff-labor-v1.md` | **COMPLETE** |

Soft parallel OK. Hard swap after manager burn-in sign-off.

---

## Promotions (Codes + Banners)

| Layer | State |
|-------|--------|
| Shared `Promo` model (types, BOGO, daypart, toppings) | **COMPLETE** |
| `PromoPricing.evaluate` pure engine | **COMPLETE** |
| Admin Codes hub + template picker | **COMPLETE** |
| Admin Banners (promote deal / category / item) | **COMPLETE** |
| Mobile checkout apply (no hardcoded PIZZA10) | **COMPLETE** |
| customer_web checkout apply | **COMPLETE** |
| Banner tap → `FranchiseProvider.pendingPromoCode` → checkout | **COMPLETE** |

Authority: `docs/slices/promo-system-v1.md`  
Paths: `packages/shared_core/.../promo.dart`, `promo_pricing.dart` · `web-app/lib/admin/promo/**` · mobile `checkout_screen` + `banner_action_handler`

**Deferred:** combo/bundle type, prix-fixe, tiered spend-more-save-more, first-order-only flag, full category→item resolution in engine.

---

## customer_web templates

| `config/storefront.templateId` | Layout |
|--------------------------------|--------|
| `default` (or missing) | Plain MVP `StorefrontHomeScreen` |
| `modern` | Modern landing + full order path + branded chrome |

HQ: Restaurant settings → Website → **Storefront template**.  
Cart: shell **side sheet** (`StorefrontShell.openCartSheet`); checkout in-shell.  
Authority: `docs/plans/customer-web-template-modern-v1.md` · `customer_web/README.md`

---

## Admin / HQ people surfaces

| Section | Host | Role |
|---------|------|------|
| **Portal users** | **HQ** Quick Link → `StaffAccessScreen` | Web logins / invites (`franchisee_invitations` portal_staff) |
| **Station staff** | Admin → **Staff Management** | POS roster + PIN + **editable permissions** |
| **Schedule** | Admin → Staff Management | Week shifts + print |
| **Hours** | Admin → Staff Management | Range summary + timesheet print |

Admin sidebar: Station staff / Schedule / Hours under expandable **Staff Management**. Portal users **not** on Admin nav (`showInSidebar: false`).

---

## POS delivery (software)

```text
Accept & deliver     → out_for_delivery (in route)
Returned (unpaid)    → pending_till
Close out (cash)     → delivered (cash only; card needs manager_override)
Returned (paid)      → delivered
```

Authority: `pos_app/lib/features/orders/open_orders_screen.dart` · `OrderStatus`

---

## God-object containment (extract)

| Slice | State |
|-------|--------|
| `docs/slices/bounded-context-repos-v1.md` | MenuRepository A1 + ConfigRepository A2.1–A2.2 on extract branches |
| `docs/slices/customization-modal-decompose-v1.md` | B1–B2.2 customization pricing/controller (smoke 2026-08-10) |
| `docs/slices/manager-burn-in-v1.md` | **ACTIVE** — burn-in checklist; no extract on this branch |

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Manager burn-in — checklist in `docs/slices/manager-burn-in-v1.md`; code only for logged gaps on `feat/manager-burn-in-fixes` |
| **2** | Soft parallel with Owner.com |
| **3** | Hardware when devices arrive; customer iOS when Mac available |
| **4** | SendGrid credits → portal invite email live |
| **5** | Promo polish residual (bundle type, auto-nav on banner promo) only if burn-in needs it |
| **6** | Home composition Wave 2 (deferred) |

---

**Update this file after significant sessions.**
