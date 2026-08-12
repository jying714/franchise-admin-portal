# Containment progress vs original plan

**Date:** 2026-08-11 (B3/B4 partial update 2026-08-12)  
**Baseline plan:** Soft-release `main` ~SHA `606097e`, STATUS/HANDOFF ~2026-08-08  
**Goal:** Extract + rewire only; zero behavior change; human merge gate  
**Product now:** Burn-in checklist **GREEN** (2026-08-10). Soft parallel OK. Hard Owner.com cutover waits on sign-off + hardware.

---

## Phase map (plan → reality)

| Plan phase | Intent | Status | Notes |
|------------|--------|--------|--------|
| Phase 0 | Guardrails + slice docs | **DONE** | bounded-context-repos-v1, customization-modal-decompose-v1, manager-burn-in-v1, A4 slice |
| A1 MenuRepository | Interface + impl + façade | **DONE** | Menu/category; Admin partly aligned |
| A2 ConfigRepository | Toggles / franchise info / hours | **DONE** | User franchise_profiles deferred |
| A3 OrderRepository | Cart + core orders | **DONE** | Abstract + concrete + façade |
| A4 Inventory + Labor | Formalize escapes | **DONE + exceeded** | Wrappers **and** call-site migration |
| A5 Other contexts | Billing, audit, etc. | **Not started** | Optional for soft-release |
| B1 Pure pricing / selection | Shared domain | **DONE** | MenuPricing, MenuCustomizationSelection |
| B2 CustomizationController | State + pricing + mutations | **DONE** | On composition-root branch |
| B3 Dual-write removal | Runtime maps → controller | **DONE** | cheeses/toppings/sauces/dressings/add-ons |
| B4 Thin modal | Composition root ~20–30 KB | **Partial** | Init dual maps + PizzaSauceSelection + sauceSplit + SauceSelectorGroup maps removed; portions/radio/wings local; smoke before merge |
| C Branding hygiene | BrandingFacade / DesignTokens | **Not started** | Live FranchiseProvider path already true |
| D Convergence + cleanup | Shared helpers, local user.dart | **Not started** | |
| E Hardening | Caching, N+1, agent templates | **Not started** | |

---

## Issue completion depth

### P0-1 God FirestoreService

| Work | Done? |
|------|--------|
| Menu / Config / Order / Inventory / Labor repos | **Yes** |
| Façade forwards (menu/config/order) | **Yes** |
| Inventory/labor UI on repos | **Yes** |
| Order/menu/config full call-site migration | **Partial** (mostly façade) |
| A5 (billing, audit, …) | **No** |
| Deprecate forwards | **No** (correct until call sites done) |

**Net:** Contained at key seams; abstract+impl still large.

### P0-2 God customization_modal

| Work | Done? |
|------|--------|
| MenuPricing | **Yes** |
| Controller mutations (incl. pizza sauces) | **Yes** |
| Runtime dual-write removal (B3) | **Yes** |
| Init dual maps + PizzaSauceSelection class (B4 partial) | **Yes** |
| Thin composition root only (~20–30 KB) | **No** |
| Drinks/wings on controller | **Deferred** |
| Shared with customer_web/POS | **No** |

**Net:** Business rules + dual-write extracted; file size / reviewability goal not finished. Branch: `feat/customization-modal-composition-root` — smoke before merge.

### P1–P2

| Item | Depth |
|------|--------|
| MenuItem policy / dual-tree | Pricing helpers only; policy never filled; dual-tree waits re-seed |
| BrandingFacade | Not started |
| Cross-surface pricing | Mobile yes; web/POS no |
| Local mobile `user.dart` | Still present |

---

## Scorecard

| Goal from original plan | Progress |
|-------------------------|----------|
| Start A1 MenuRepository | **Exceeded** (A1–A4) |
| Customization rules out of modal | **~85%** (B3 done; B4 partial) |
| Slim MenuItem + policy | **~30%** |
| Branding hygiene | **~10%** |
| Shared cart/pricing all surfaces | **~40%** |
| Kill god service entirely | **~40%** |
| Burn-in / soft-release safety | **Met** |

**Not required for hardware cutover:** A5, dual-tree deletion, shared_ui, Phase E.

---

## Full finish checklist (original plan end state)

### 1. Service containment
- [ ] Order call sites prefer OrderRepository **or** documented façade-only inventory
- [ ] Menu / Config same documentation
- [ ] A5 only if needed
- [ ] STATUS lists façade-only vs call-site-done

### 2. Customization modal (Phase B)
- [ ] Modal ≤ composition root (~20–30 KB wiring)
- [x] Drop dual lockstep maps (B3 + B4 partial on composition-root branch)
- [ ] Optional drinks/wings on controller
- [ ] Re-smoke pizza / calzone / salad / wings / dinner on branch before merge

### 3. MenuItem + domain
- [ ] Real MenuItemPolicy (`isSellable`, inventory block, schema helpers)
- [ ] Dual-tree only after deliberate re-seed

### 4. Branding (Phase C)
- [ ] BrandingFacade (or equivalent)
- [ ] Document single live path

### 5. Convergence (Phase D)
- [ ] customer_web (and POS if needed) shared pricing helpers
- [ ] Delete local mobile `user.dart` after import audit
- [ ] “Where does X live?” architecture note

### 6. Product / ops
- [ ] Soft parallel → hard cutover on sign-off
- [ ] Hardware pilot when devices arrive
- [ ] iOS postponed; SendGrid when credits allow

---

## Recommended remaining sequence (optional extract)

1. **Smoke** `feat/customization-modal-composition-root` → merge when green (B3 done; B4 partial)
2. Optional further B4 (portions / radio / wings) after merge if needed
3. `feat/order-repository-callsites` — A3 depth like A4
4. Phase C BrandingFacade when branding work resumes

---
