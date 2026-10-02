# STATUS.md — Live Project Snapshot

**Last Updated**: October 1, 2026
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch**: soft-release **`main`** · product work **`feat/pre-hardware-hq-polish`**
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Out of franchiseHQ production MVP

**WeekTally / weekly tally is not a franchiseHQ product feature and is not an MVP acceptance item.**

`firebase.json` on `main` (commit `fe62dafe`, 2026-09-30) rewrites `/tally` and `/tally/**` to Cloud Run service `weektally`. That is a personal household finance tool hosted on the same Firebase project. It is not HQ, Admin, POS, customer web, or customer mobile scope. Do not track it in burn-in, Owner.com cutover, or release %.

Also deferred past MVP: **iOS**, **printer-by-category**, **loyalty**, **custom domains**, **home composition Wave 2** (HQ homepage widget studio; Wave 1 shell is complete).

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | **On main** |
| Ordering customization parity | **Open** — `docs/slices/ordering-customization-normalize-v1.md` (work on polish) |
| Storefront shell Wave 1 + Modern | **COMPLETE** |
| Inventory v1 + Staff/labor v1 | **COMPLETE on main** |
| POS clock / delivery COD / portal users / promos v1 | **COMPLETE** |
| Manager burn-in checklist | **GREEN 2026-08-10** |
| Soft parallel / hard Owner.com cutover | Soft parallel OK; hard cutover after sign-off + hardware |
| Portal invite email (SendGrid) | Wired; blocked on credits |
| Station hardware · iOS | Hardware on polish; **iOS post-MVP** |
| WeekTally `/tally` | **Out of MVP** — personal finance, not franchiseHQ |

Product next is on `feat/pre-hardware-hq-polish`: normalize ordering customization, then merge. This file's August containment notes below are historical.

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

**Not required for hardware cutover:** A5, dual-tree deletion, shared_ui, Phase E, WeekTally, iOS, printer-by-category, Wave 2 studio.

---

## Next product / extract focus

| Priority | Focus |
|----------|--------|
| **1** | Ordering customization normalize on polish, then merge to `main` |
| **2** | Delivery range on mobile + POS (callable is polish-only today) |
| **3** | Catalog health phase C; Functions Node 22 before ~2026-10-30 |
| **4** | Optional extract leftovers (B4, Order call sites, BrandingFacade) |
| **5** | SendGrid credits if portal invites are required |

---

**Update this file after significant sessions.**
