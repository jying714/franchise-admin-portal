# STATUS.md — Live Project Snapshot

**Last Updated**: August 11, 2026 (~11:00 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`main`** (soft-release); extract A4: **`feat/bounded-context-repos-a4-inventory-labor`**  
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
| OrderRepository (A3) | **DONE** (merged / on main) |
| **A4 Inventory + Labor** | **COMPLETE** on `feat/bounded-context-repos-a4-inventory-labor` — repos + call-site migration; **merge to main** |
| Portal invite email (SendGrid) | Wired; blocked on credits |
| Station hardware · iOS | Waiting / postponed |

---

## God-object containment (extract)

| Slice | State |
|-------|--------|
| A1 MenuRepository | DONE |
| A2 ConfigRepository | DONE |
| A3 OrderRepository | DONE |
| A4 Inventory + Labor | **COMPLETE** — wrappers + call sites (checkout, POS, Admin schedule/hours, PIN clock) |
| Customization B1–B2.2.3 | COMPLETE on main |

Authority: `docs/slices/bounded-context-repos-v1.md`, `docs/slices/bounded-context-repos-a4-inventory-labor.md`

---

## Next product focus

| Priority | Focus |
|----------|--------|
| **1** | Merge A4 → main; soft parallel with Owner.com |
| **2** | Hard cutover after sign-off + hardware |
| **3** | Hardware pilot when devices arrive; iOS when Mac available |
| **4** | SendGrid credits → portal invite email |
| **5** | Promo residuals only if needed |

---

**Update this file after significant sessions.**
