# STATUS.md — Live Project Snapshot

**Last Updated**: August 4, 2026 (~23:30 CDT — inventory + labor cutover gates closed on main)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`main`** (up to date with completed ops + storefront shell work)  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | **On main** |
| Storefront shell Wave 1 | **COMPLETE on main** (in-place menu/cart/checkout, floating bar, customize dialog) |
| Home composition engine Wave 2 | **Deferred** |
| **Inventory v1 (MVP-Ops)** | **COMPLETE on main** — cutover gate satisfied |
| **Staff/labor v1 (MVP-Ops)** | **COMPLETE on main** — cutover gate satisfied |
| POS hardware · iOS Mac | **In transit** |
| Soft parallel / MVP burn-in | **Next** — manager validation before hard Owner.com off |

---

## Owner.com cutover gates (Doughboys)

**Soft release:** POS parallel with current terminal/Owner.com while burn-in runs.  
**Hard swap** (manager bar) requires both gates below — **now implemented**:

| Gate | Plan | Status |
|------|------|--------|
| **Inventory** | `docs/plans/mvp-ops-inventory-v1.md` | **COMPLETE** — `MenuItem.isSellable` / channel filters; `InventoryLedger` paid decrement + void/refund restore; HQ inventory fields |
| **Staff/labor** | `docs/plans/mvp-ops-staff-labor-v1.md` | **COMPLETE** — Admin roster + PIN; week schedule + print; POS clock in/out; hours summary + timesheet print |

Order/pay/ticket already on main for soft parallel.

### Residual (not blocking soft parallel)

- Replace MVP `pos-station@doughboys.local` rules email gate with real **`stationFranchise` custom claims**
- Deploy/confirm **firestore.rules** on production project after every rules change
- Manager burn-in checklist (stock 86, clock, hours, one full web order)

---

## Decision locks (storefront)

| Wave | Plan | State |
|------|------|--------|
| 1 Shell + nested UX + section home | `docs/plans/customer-web-storefront-shell-v1.md` | **COMPLETE on main** |
| 2 Composition engine / HQ studio | `docs/plans/home-page-composition-engine-v1.md` | Deferred |

---

## customer_web

On **main**: `StorefrontShell` + in-place categories/items/cart/checkout/confirm; mobile-parity customize dialog; cream theme; hero/logo from HQ; `store_ops` footer; structured HQ contact address.

---

## Admin labor surfaces (sidebar)

| Section | Role |
|---------|------|
| Portal users | App logins / roles (`StaffAccessScreen`) |
| Station staff | POS roster + PIN (`franchises/{id}/staff`) |
| Schedule | Week shifts + print |
| Hours | Range summary + per-employee timesheet print |

---

## Next product focus (MVP release path)

| Priority | Focus |
|----------|--------|
| **1 – Soft release** | Deploy rules + web/POS builds; Doughboys manager burn-in |
| **2 – Claims** | `stationFranchise` on station Auth user; remove email smoke clause |
| **3 – Hardware** | Terminals + iOS when devices arrive |
| **4 – Growth** | Promos, push/SMS, loyalty, upsells — after soft stability |
| **5 – Wave 2** | Home composition engine (deferred) |

**Decision locks:** 11 / 12 / 14 + storefront Wave 1 + inventory + labor gates closed.

---

**Update this file after significant sessions.**
