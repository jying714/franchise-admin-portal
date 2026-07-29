# STATUS.md — Live Project Snapshot

**Last Updated**: July 29, 2026 (~15:20 CDT — mobile design tokens T1–T9 complete on feature branch)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/mobile-design-tokens-v1`  
**Main**: menu-modifier M1–M5, wings/calzone W0–W7+W2, Hosting deploy on push; Developer dashboard may still be on separate branch until merged

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (on `main`).  
**Menu modifier system rebuild (Decision 10)** — **M1–M5 complete; wings + calzone W0–W7 + W2 complete** (on `main`).  
**Mobile Design Tokens v1** — **T1–T9 implementation Complete** on `feat/mobile-design-tokens-v1` (human smoke + merge gate open).

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7); foundation residual
- [x] HQ Design & Branding v1/v1.1; financial honesty; platform billing honesty
- [x] Platform Owner dashboard MVP
- [x] Ingredient type sortOrder uniqueness + ingredients group edit
- [x] `feat/onboarding-4step` → `main`; Hosting
- [x] Admin exhaustive smoke (July 27)
- [x] **Admin dashboard ops fixes v1** — merged `main`
- [x] **M1–M5** menu modifier rebuild + wings/calzone + W2 sauce pool — merged `main`
- [x] **Mobile Design Tokens v1 (T0–T7, T9, T10)** — scheme from primary/secondary; live franchise branding stream; customer chrome on ColorScheme roles; status chips fixed feedback (D4); QR scan consistent. **Authority:** `docs/slices/mobile-design-tokens-v1.md`. Branch: `feat/mobile-design-tokens-v1`.

### Mobile design tokens — progress

| Stream | Status |
|--------|--------|
| **T0** Map lock | **Done** |
| **T1** ColorScheme + theme injection | **Done** |
| **T2** Shell / app bar / MainMenu surface + status bar | **Done** |
| **T3** CategoryCard | **Done** |
| **T4** MenuItemCard + CTA/favorite widgets | **Done** |
| **T5** Customization family | **Done** |
| **T6** Cart | **Done** |
| **T7** Profile, history, favorites, language, addresses | **Done** |
| **T8** Auth + social + franchise selector | **Deferred** (explicit) |
| **T9** QR + residual snackbars | **Done** |
| **T10** Docs / STATUS close | **Done** |

**Locks (do not regress):** HQ seeds only (primary, secondary, appName, logo); no per-widget Firestore colors; favorite active = error; prices = onSurface; status chips not brand-tinted; live `franchises/{id}` snapshots drive theme.

### Active focus

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | Human smoke mobile design tokens → merge `feat/mobile-design-tokens-v1` → `main` when green | `docs/slices/mobile-design-tokens-v1.md` §10 |
| **2** | Developer dashboard merge (if still on feature branch) | `docs/slices/developer-dashboard-v1.md` |
| **3** | Optional residual: checkout / confirmation / item detail / auth (T8) token polish | Same slice deferred notes |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| HQ Design page full semantic vocabulary editors | Deferred — seeds only for mobile v1 |
| Cash Flow Forecast / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| CF Node 22 | Before ~2026-10-30 |
| Combos / bundles | Deferred |
| Auth/social ColorScheme pass (T8) | Deferred after mobile tokens merge |
| Order-experience prompt post-delivery | Post-MVP (storage + MainMenu due check landed) |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens color fields for widgets; progress under `franchises/{id}/onboarding_progress/progress`; mobile theme = derived ColorScheme from franchise seeds.

---

**Update this file after significant sessions.**
