# STATUS.md — Live Project Snapshot

**Last Updated**: August 8, 2026 (~19:40 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`main`**  
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
| Station POS hardware · iOS Mac | **In transit** |
| Soft parallel / manager burn-in | **Active** |
| Portal invite email (SendGrid) | **Wired**; blocked on SendGrid **credits** until go-live billing |

---

## Owner.com cutover gates (Doughboys)

| Gate | Plan | Status |
|------|------|--------|
| **Inventory** | `docs/plans/mvp-ops-inventory-v1.md` | **COMPLETE** |
| **Staff/labor** | `docs/plans/mvp-ops-staff-labor-v1.md` | **COMPLETE** |

Soft parallel OK. Hard swap after manager burn-in sign-off.

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

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Manager burn-in (inventory 86, clock, web order, delivery COD, Modern if enabled) |
| **2** | Soft parallel with Owner.com |
| **3** | Hardware when devices arrive; customer iOS when Mac available |
| **4** | SendGrid credits → portal invite email live |
| **5** | Growth (promos, push, loyalty) after soft stability |
| **6** | Home composition Wave 2 (deferred) |

---

**Update this file after significant sessions.**
