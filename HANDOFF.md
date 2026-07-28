# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 28, 2026 (~16:00 CDT — wings + calzone W1–W6 code + seed)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/menu-modifier-system-rebuild-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 28 afternoon/evening)

### Pizza path (done)

- HQ included + optional add-ons persist; mobile optionalAddOns pools; cheeses/sauces section parity; CBR PASS.
- Doughboys categories / ingredient_types / ingredient_metadata / menu_items seeded and verified.

### Wings + calzone (W1–W6 done — W7 acceptance open)

Authority: **`docs/slices/hq-wings-calzone-v1.md`**.

| Topic | Lock |
|--------|------|
| Wings portions | Max **2** always |
| Plain | No toss on portion; **still gets free cups** |
| Sauces | Catalog type **`sauces`**; item **binds** via modifier groups; save projects to `dippingSauceOptions` / `sideDipSauceOptions` (same list) |
| Free cups / extra $ | Menu item per size → `freeDipCupCount` / `sideDipUpcharge` (existing MenuItem fields) |
| UI | Build your wings + **Dipping sauces** only; no included/optional on wings profile |
| Calzone | **`menuProfile: calzone`**; pizza twin; **no left/right** |

**Landed this session:**

- W1: `MenuProfile.calzone` + seedGroups pizza clone; wings template notes
- W3: HQ editor wings free-cups panel, save projection, hide included/optional, layout cleanup, binder chip fix
- W4/W5: mobile + web profile helpers; wings portion callback; single dipping list; size resync
- W6: wings + calzone items seeded (human)

### Still open

1. **W7** full acceptance smoke (wings + calzone + pizza regression)  
2. Optional **W2** franchise `config/menu_profile_wings` pool  
3. **M5** cutover  
4. Developer dashboard  

### Do not regress

- Pizza optionalAddOns contract (Current / Additional / Cheeses / Sauces / Order Details)  
- HQ included + optional persist (non-wings profiles)  
- No `FranchiseProvider()` zero-arg / DesignTokens invention  
- No Cook/Cut/Crust as ingredient types  
- No new `wing_sauces` ingredient type  
- Wings: no dual Dips/Sauces tabs; no included/optional toppings UI  

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Menu rebuild M1–M4 pizza + optionalAddOns UX | Done on feature branch |
| Foundation seed Doughboys | Done |
| Wings + calzone product lock (W0) | Done |
| Wings + calzone W1–W6 (code + seed) | Done on feature branch |

---

## 3. What’s next

1. **W7** acceptance smoke: wings (2 portions, Plain, free cups by size, single dipping list, cart totals) + calzone (pizza path, no left/right) + pizza CBR regression  
2. Optional **W2** franchise shared sauce pool (item bind already works)  
3. **M5** dual-tree cutover only after W7 green  

---

## 4. Key references

- `docs/slices/hq-wings-calzone-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  
- `packages/shared_core/.../menu_item.dart` (wings fields already present)  
- `packages/shared_core/.../menu_profile_templates.dart`  
- `mobile_app/.../customization_modal.dart`  
- `mobile_app/.../wings_portion_selector.dart` / `wings_dip_sauce_selector.dart`  
- `web-app/.../menu_item_editor_sheet.dart`  
- `web-app/.../modifier_groups_ingredient_binder.dart`  

---

**Bottom line:** Pizza UX locked. Wings + calzone **code + seed (W1–W6) landed** on feature branch. Next is **W7 acceptance**; do not start M5 until that is green unless human expands scope.
