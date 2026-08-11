# STATUS.md — Live Project Snapshot

**Last Updated**: August 11, 2026 (~10:35 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`main`** (soft-release); extract A3: **`feat/bounded-context-repos-a3-orders`**  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | **On main** |
| Storefront shell Wave 1 + Modern | **COMPLETE** |
| Inventory v1 + Staff/labor v1 | **COMPLETE on main** |
| POS clock / delivery COD / portal users / promos v1 | **COMPLETE** |
| Manager burn-in checklist | **GREEN 2026-08-10** |
| Soft parallel / hard Owner.com cutover | Soft parallel OK; hard cutover after sign-off + hardware |
| **OrderRepository (A3)** | **DONE** on `feat/bounded-context-repos-a3-orders` — merge to main |
| **A4 Inventory + Labor formalize** | **DONE** on `feat/bounded-context-repos-a4-inventory-labor` — merge to main |
| Portal invite email (SendGrid) | Wired; blocked on credits |
| Station hardware · iOS | Waiting / postponed |

---

## God-object containment (extract)

| Slice | State |
|-------|--------|
| A1 MenuRepository | DONE (merged / on main path) |
| A2 ConfigRepository | DONE (toggles + franchise info + hours) |
| A3 OrderRepository | **DONE** on `feat/bounded-context-repos-a3-orders` |
| A4 Inventory + Labor | **NEXT** on `feat/bounded-context-repos-a4-inventory-labor` |
| Customization B1–B2.2.3 | COMPLETE on main |

Authority: `docs/slices/bounded-context-repos-v1.md`, `docs/slices/bounded-context-repos-a4-inventory-labor.md`, `docs/slices/customization-modal-decompose-v1.md`

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Soft parallel with Owner.com; hard cutover after sign-off + hardware |
| **2** | Merge A3 → main; then A4 inventory/labor formalize (no reimplement) |
| **3** | Hardware pilot when devices arrive; iOS when Mac available |
| **4** | SendGrid credits → portal invite email |
| **5** | Promo residuals only if needed |

---

**Update this file after significant sessions.**
