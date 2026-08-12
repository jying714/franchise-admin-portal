# STATUS.md — Live Project Snapshot

**Last Updated**: August 12, 2026
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: **`feat/customization-modal-composition-root`** (B3 done; B4 partial; merge pending smoke) · soft-release remains **`main`**
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
| Portal invite email (SendGrid) | Wired; blocked on credits |
| Station hardware · iOS | Waiting / postponed |

---

## God-object containment (original plan → reality)

Authority: `docs/slices/bounded-context-repos-v1.md`, `docs/slices/customization-modal-decompose-v1.md`, `docs/slices/bounded-context-repos-a4-inventory-labor.md`, `docs/architecture/containment-progress-2026-08-11.md`

| Phase | Intent | State |
|-------|--------|--------|
| **0** Guardrails + slice docs | Living authority | **DONE** |
| **A1** MenuRepository | Interface + impl + façade | **DONE** |
| **A2** ConfigRepository | Toggles / franchise info / hours | **DONE** (user franchise_profiles deferred) |
| **A3** OrderRepository | Cart + core orders + façade | **DONE** |
| **A4** Inventory + Labor | Wrappers + **call-site migration** | **DONE** (exceeded plan) |
| **A5** Other contexts | Billing, audit, etc. | **Not started** (optional) |
| **B1** MenuPricing + selection snapshot | Pure domain | **DONE** |
| **B2** CustomizationController | State + pricing + mutations | **DONE** |
| **B3** Dual-write removal | Runtime maps → controller | **DONE** on `feat/customization-modal-composition-root` |
| **B4** Thin composition-root modal | Init dual maps + PizzaSauceSelection + sauceSplit + SauceSelectorGroup maps removed | **Partial** — smoke before merge; portions/radio/wings still modal-local; file still large |
| **C** BrandingFacade / DesignTokens hygiene | Single live path | **Not started** |
| **D** Surface convergence + local user.dart | Shared helpers | **Not started** |
| **E** Caching / N+1 / agent templates | Post-containment | **Not started** |

**Scorecard (honest):** A1–A4 exceeded start plan; customization dual-write **removed** (B3); B4 partial (init dual maps / PizzaSauceSelection / sauceSplit / SauceSelectorGroup maps gone); modal still large; portions/radio/wings local; MenuItem policy ~30%; branding hygiene ~10%; god service contained at key seams ~40%; burn-in safety **met**.

**Not required for hardware cutover:** A5, dual-tree deletion, shared_ui, Phase E.

---

## Next product / extract focus

| Priority | Focus |
|----------|--------|
| **1** | Soft parallel; hard cutover after sign-off + hardware |
| **2** | Device smoke on `feat/customization-modal-composition-root` → merge when green; optional further B4 (portions/radio/wings) after |
| **3** | Optional: OrderRepository call-site migration (make A3 as real as A4) |
| **4** | Optional: Phase C BrandingFacade |
| **5** | Hardware pilot; iOS when Mac; SendGrid credits |

---

**Update this file after significant sessions.**
