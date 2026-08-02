# STATUS.md — Live Project Snapshot

**Last Updated**: August 2, 2026 (~12:30 CDT — HQ Restaurant settings slice locked; customer_web on main)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: **`main`**  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io  
**Storefront**: https://franchise-storefront.web.app

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| HQ / Admin / menu / mobile / POS pilot | **On main** |
| **Customer website MVP path** | **On main** (bind → menu → auth → cart → Connect → POS `source: web`) |
| **Customer web parity + brand storefront** | Plan locked: `docs/plans/customer-web-parity-brand-storefront-v1.md` |
| **HQ Restaurant settings** | **Slice locked — not started:** `docs/slices/hq-restaurant-settings-v1.md` |

### HQ Restaurant settings (next HQ work)

- **One card:** Restaurant settings (absorbs Design & Branding + Customer website entry + Tax & hours).  
- **Shell:** top tabs — Brand · Website · Store ops · Channels · Payments · Station · Contact.  
- Feature Setup onboarding **unchanged** until shell complete.  
- POS tab **now** (stub unimplemented fields).

### Customer website (baseline on main)

| Capability | State |
|------------|--------|
| `/f/{franchiseId}` + Hosting storefront | **Done** |
| Menu + Phase 4b pricing + cart/checkout | **Done** |
| HQ StorefrontLinkCard (URL/QR) | **Done** (to move under Restaurant settings → Website) |

**Parity wave (not started):** category-first menu, full customize, delivery, promos, loyalty, marketing home — see parity plan.

### Active focus (priority)

| Priority | Work |
|----------|------|
| **1** | **HQ Restaurant settings v1** (shell → Brand → Store ops → Website → …) |
| **2** | customer_web parity / brand storefront (after or parallel once Website fields exist) |
| **3** | POS residuals (Terminal / printers / staff bootstrap) |

**Decision locks:** 11 / 12 / 14.  
**Docs:** `docs/slices/hq-restaurant-settings-v1.md` · `docs/plans/customer-web-parity-brand-storefront-v1.md`

---

**Update this file after significant sessions.**
