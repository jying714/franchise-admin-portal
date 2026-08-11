# Containment progress vs original plan

**Date:** 2026-08-11  
**Baseline plan:** Soft-release `main` ~SHA `606097e`, STATUS/HANDOFF ~2026-08-08  
**Goal:** Extract + rewire only; zero behavior change; human merge gate

---

## Phase map (plan → reality)

| Plan phase | Intent | Status | Notes |
|------------|--------|--------|--------|
| Phase 0 | Guardrails + slice docs | **DONE** | bounded-context-repos-v1, customization-modal-decompose-v1, manager-burn-in-v1, A4 slice |
| A1 MenuRepository | Interface + impl + façade | **DONE** | Menu/category; Admin partly aligned |
| A2 ConfigRepository | Toggles / franchise info / hours | **DONE** | User franchise_profiles deferred |
| A3 OrderRepository | Cart + core orders | **DONE** | Abstract + concrete + façade |
| A4 Inventory + Labor | Formalize escapes | **DONE + exceeded** | Wrappers **and** call-site migration |
| A5 Other contexts | Billing, audit, etc. | **Not started** | Optional |
| B1 Pure pricing / selection | Shared domain | **DONE** | MenuPricing, MenuCustomizationSelection |
| B2 CustomizationController | State + pricing + mutations | **Mostly done** | Modal still large + lockstep |
| B3–B4 Thin modal | Composition root ~20–30 KB | **Partial** | |
| C Branding hygiene | BrandingFacade / DesignTokens | **Not started** | |
| D Convergence + cleanup | Shared helpers, local user.dart | **Not started** | |
| E Hardening | Caching, N+1, agent templates | **Not started** | |

---

## Issue completion depth

### P0-1 God FirestoreService

- Repos for Menu, Config, Order, Inventory, Labor: **yes**
- Façade forwards (menu/config/order): **yes**
- Inventory/labor UI on repos: **yes**
- Order/menu/config full call-site migration: **partial** (mostly façade)
- A5 contexts: **no**
- Deprecate forwards: **no** (correct until call sites done)

**Net:** Contained at key seams; abstract+impl still large.

### P0-2 God customization_modal

- MenuPricing: **yes**
- Controller mutations (incl. pizza sauces): **yes**
- Thin composition root only: **no**
- Drinks/wings on controller: **deferred**
- Shared with customer_web/POS: **no**

**Net:** Business rules extracted; file size goal not finished.

### P1–P2

| Item | Depth |
|------|--------|
| MenuItem policy / dual-tree | Pricing helpers only; policy stub never real; dual-tree waits re-seed |
| BrandingFacade | Not started (live FranchiseProvider path still true) |
| Cross-surface pricing | Mobile yes; web/POS no |
| Local mobile user.dart | Still present |

---

## Scorecard

| Goal | Progress |
|------|----------|
| Start A1 | **Exceeded** (A1–A4) |
| Customization rules out of modal | **~70%** |
| Slim MenuItem + policy | **~30%** |
| Branding hygiene | **~10%** |
| Shared cart/pricing all surfaces | **~40%** |
| Kill god service entirely | **~40%** |
| Burn-in safety | **Met** |

**Not required for hardware cutover:** A5, dual-tree deletion, shared_ui, Phase E.

---

## Recommended remaining sequence (optional extract)

1. `feat/customization-modal-composition-root` — finish Phase B
2. `feat/order-repository-callsites` — A3 depth like A4
3. `feat/branding-facade-v1` — Phase C
4. Surgical: delete local `user.dart` if imports clean
5. Docs snapshot; close plan phases

**Bottom line:** First half of the original plan is largely done. Second half (thin modal, MenuItem policy, branding façade, cross-surface convergence) remains for a full architectural finish—not more empty stubs.
