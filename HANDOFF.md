# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 28, 2026 (~17:25 CDT — W7 PASS; salad/dinner mobile polish; M5 next)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/menu-modifier-system-rebuild-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 28 evening)

### Pizza path (done + polish)

- HQ included + optional add-ons persist; mobile optionalAddOns pools; cheeses/sauces section parity; CBR PASS.
- Order Details: Crust/Cook/Cut via stored groups **or** pizza template fallback when omitted.
- Flat “Add-ons” checkbox groups hidden on pizza/calzone.
- Included ingredients **do not** inflate base price (only doubles / true extras charge).

### Wings + calzone (W0–W7 **Done**)

Authority: **`docs/slices/hq-wings-calzone-v1.md`**.

| Topic | Lock |
|--------|------|
| Wings portions | Max **2** always |
| Plain | No toss on portion; **still gets free cups** |
| Sauces | Catalog type **`sauces`**; item **binds** via modifier groups; save projects to `dippingSauceOptions` / `sideDipSauceOptions` |
| Free cups / extra $ | Menu item per size → `freeDipCupCount` / `sideDipUpcharge` |
| UI | Build your wings + **Dipping sauces** only; no included/optional; no Order Details |
| Calzone | **`menuProfile: calzone`**; pizza twin; **no left/right**; cheeses/sauces like pizza |

Human acceptance: wings, calzone, pizza — **PASS**.

### Salad / dinner mobile (done this session)

- No Order Details for salad/dinner.
- Optional ingredients only when HQ set `optionalAddOns` (`menuProfile: standard` — no new profiles).
- Salad: optional pool uses Click to Add (Additional Toppings-style cards); selected items move to Current only; included not listed on both; remove from Current returns to optional pool.
- Pricing: included never auto-added to starting total.

### Still open

1. **M5** dual-tree cutover (next epic gate)  
2. Optional **W2** franchise `config/menu_profile_wings` pool  
3. Developer dashboard  
4. Ensure latest local mobile salad/optional commits are on `origin` if any remain unstaged  

### Do not regress

- Pizza optionalAddOns contract (Current / Additional / Cheeses / Sauces / Order Details)  
- HQ included + optional persist (non-wings profiles)  
- Included ingredients not charged as extras until double or truly extra  
- No `FranchiseProvider()` zero-arg / DesignTokens invention  
- No Cook/Cut/Crust as ingredient types  
- No new `wing_sauces` ingredient type  
- Wings: single dipping list; no dual tabs; no included/optional UI  

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Menu rebuild M1–M4 pizza + optionalAddOns UX | Done on feature branch |
| Foundation seed Doughboys | Done |
| Wings + calzone W0–W7 | **Done** on feature branch |
| Salad/dinner mobile optional UX + pricing honesty | Done on feature branch |

---

## 3. What’s next

1. **M5** dual-tree cutover: canonical-only write/read; backfill live items; remove legacy production paths  
2. Optional **W2** franchise shared sauce pool (ops convenience only)  
3. Developer dashboard after menu path stable on `main`  

---

## 4. Key references

- `docs/slices/hq-wings-calzone-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  
- `docs/MOBILE_DYNAMIC.md`  
- `packages/shared_core/.../menu_item.dart`  
- `packages/shared_core/.../menu_profile_templates.dart`  
- `mobile_app/.../customization_modal.dart`  
- `mobile_app/.../optional_addons_group.dart`  
- `mobile_app/.../wings_portion_selector.dart` / `wings_dip_sauce_selector.dart`  
- `web-app/.../menu_item_editor_sheet.dart`  

---

**Bottom line:** Wings + calzone acceptance is **green**. Pizza Order Details + pricing honesty + salad/dinner optional UX landed. **Next product-technical gate is M5 cutover** (not more wings feature work unless W2 is explicitly requested).
