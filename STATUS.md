# STATUS.md — Live Project Snapshot

**Last Updated**: August 5, 2026 (~22:50 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`main`** (feature work: `feat/customer-web-template-modern-v1` for Modern template if not yet merged)  
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
| **Modern storefront template** | **COMPLETE** (`templateId: modern`) — hero, Featured, category→items→cart→checkout, footer, HQ picker |
| Home composition engine Wave 2 | **Deferred** |
| **Inventory v1 (MVP-Ops)** | **COMPLETE on main** |
| **Staff/labor v1 (MVP-Ops)** | **COMPLETE on main** |
| Station `stationFranchise` claims | **COMPLETE** (email smoke gate removed) |
| POS clock gates | **COMPLETE** — unlock requires clock-in; off-shift needs manager override; live schedule server read |
| POS hardware · iOS Mac | **In transit** |
| Soft parallel / manager burn-in | **Active** — ops validation before hard Owner.com off |

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
| `modern` | Pizzon-inspired Modern landing + full order path |

HQ: Restaurant settings → Website → **Storefront template** dropdown.

Authority: `docs/plans/customer-web-template-modern-v1.md`

---

## Admin labor surfaces

| Section | Role |
|---------|------|
| Portal users | App logins / roles |
| Station staff | POS roster + PIN |
| Schedule | Week shifts + print |
| Hours | Range summary + timesheet print |

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Manager burn-in (inventory 86, clock, web order, Modern if enabled) |
| **2** | Soft parallel with Owner.com |
| **3** | Hardware when devices arrive |
| **4** | Growth (promos, push, loyalty) after soft stability |
| **5** | Home composition Wave 2 (deferred) |

---

**Update this file after significant sessions.**
