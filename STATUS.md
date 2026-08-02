# STATUS.md — Live Project Snapshot

**Last Updated**: August 2, 2026 (~14:00 CDT — HQ Restaurant settings v1 nearly complete on feature branch)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch (active work)**: **`feat/hq-restaurant-settings-v1`**  
**Main**: customer_web MVP path + prior HQ/Admin/POS; merge Restaurant settings when human gates  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| HQ / Admin / menu / mobile / POS pilot | **On main** |
| Customer website MVP path | **On main** |
| **HQ Restaurant settings v1** | **S0–S9 done** on `feat/hq-restaurant-settings-v1` — merge residual |
| customer_web parity + brand storefront | Plan locked; **not started** |

### HQ Restaurant settings (feat/hq-restaurant-settings-v1)

**One card:** Restaurant settings → shell with top tabs:

| Tab | Status |
|-----|--------|
| Brand | DesignBrandingScreen embedded |
| Website | URL/QR + Save → `config/storefront` |
| Store ops | Tax, hours, delivery, pickup, online intake, **timezone dropdown** |
| Channels | `config/features` toggles |
| Payments | Stripe Connect setup/refresh |
| Station | `config/pos` + printer/tip stubs |
| Contact | public address/phone/email/map |

**HQ cleanup:** Customer website card removed from grid; Quick Links Tax & hours → Store ops tab.

**Authority:** `docs/slices/hq-restaurant-settings-v1.md`

### Remaining (this branch)

- [ ] Human merge → `main`  
- [ ] Optional: FAQ/gallery/careers fields on Website panel  
- [ ] Optional: delete dead `StorefrontLinkCard` / `LiveBrandingPreviewCard` code if still in dashboard file  
- [ ] Feature Setup onboarding deep-link (**deferred**)  

### Next product (after merge)

| Priority | Work |
|----------|------|
| **1** | Merge HQ Restaurant settings  
| **2** | customer_web parity D0+ (`docs/plans/customer-web-parity-brand-storefront-v1.md`) reading `config/storefront`  
| **3** | POS residual: read `config/pos`  

**Decision locks:** 11 / 12 / 14.

---

**Update this file after significant sessions.**
