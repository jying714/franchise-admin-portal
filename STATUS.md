# STATUS.md — Live Project Snapshot

**Last Updated**: August 2, 2026 (~10:50 CDT — customer_web Phase 4b + cart/account polish)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/customer-website-v1`  
**Main**: POS pilot + cleanup; customer website epic on feature branch (merge when human gates)

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Thin POS software pilot: COMPLETE on `main` (2026-08-01).**  
**Customer website (`customer_web`): vertical slice + Phase 4b pricing + storefront chrome PASS** on `feat/customer-website-v1`.

| Area | State |
|------|--------|
| HQ / Admin / menu / mobile / POS pilot | **Done on main** |
| **Customer website** | **MVP-ready vertical path** on feature branch |

### Customer website — done (2026-08-02)

| Capability | State |
|------------|--------|
| Bind `/f/{franchiseId}` + Hosting `franchise-storefront.web.app` | **Done** |
| Menu browse + item detail | **Done** |
| **Phase 4b pricing** | **Done** — `SizeData.basePrice` + option `upcharge`/`upchargeBySize` **or** `SizeData.toppingPrice` (Doughboys add-ons) |
| Cart: customizations subtitle, qty steppers, remove | **Done** |
| Auth Google + email; shell cart + sign-in/out | **Done** |
| Checkout Connect + `source: 'web'` + store_ops | **Done** |
| Order confirmation + **My orders** history | **Done** |
| HQ StorefrontLinkCard copy / open / QR | **Done** |
| Path→hash bootstrap + mobile QR bind | **Done** |

**Public URL:** `https://franchise-storefront.web.app/f/{franchiseId}`  
**Build:** `flutter build web --release --pwa-strategy=none --dart-define=STRIPE_PK=...`

### Active focus

| Priority | Work | Notes |
|----------|------|--------|
| **1** | **Human merge gate** | Review → merge `feat/customer-website-v1` → `main` |
| **2** | Optional custom domains | CNAME + hostname→franchiseId (deferred schema) |
| **3** | Responsive / empty-state polish | Non-blocking |
| **4** | Staff bootstrap / Terminal / printers | POS residuals |

### Residual list

| ID | Item | Status |
|----|------|--------|
| R7 | Customer website MVP | **Vertical + 4b PASS** — merge residual |
| R3–R4 | Terminal / printers | **Open** |
| R8 | Staff bootstrap docs | **Open** |

**Decision locks:** 11 / 12 / 14.  
**Pricing lock:** prefer option upcharges when set; else `sizes[].toppingPrice` × selected add-ons + `sizes[].basePrice`.

---

**Update this file after significant sessions.**
