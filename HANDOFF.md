# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 28, 2026 (~13:50 CDT — wings + calzone plan locked)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/menu-modifier-system-rebuild-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 28 afternoon)

### Pizza path (done)

- HQ included + optional add-ons persist; mobile optionalAddOns pools; cheeses/sauces section parity; CBR PASS.
- Doughboys categories / ingredient_types / ingredient_metadata / menu_items seeded and verified.

### Wings + calzone (planned — product locked)

Authority: **`docs/slices/hq-wings-calzone-v1.md`**.

| Topic | Lock |
|--------|------|
| Wings portions | Max **2** always |
| Plain | No toss on portion; **still gets free cups** |
| Sauces | Catalog type **`sauces`**; one **franchise shared pool**; item **binds** same list for toss + side cups |
| Free cups / extra $ | Menu item creation per size → `freeDipCupCount` / `sideDipUpcharge` (existing MenuItem fields) |
| UI | Build your wings + **Dipping sauces** only |
| Calzone | **`menuProfile: calzone`**; pizza twin; **no left/right** |

**Implementation order:** W1 shared_core → W4 mobile wings (seed maps) → W5 calzone mobile → W3 HQ → W2 franchise pool → W6 seed → W7 smoke → M5.

### Still open

1. Wings + calzone W1–W7  
2. **M5** cutover  
3. Developer dashboard  

### Do not regress

- Pizza optionalAddOns contract (Current / Additional / Cheeses / Sauces / Order Details)  
- HQ included + optional persist  
- No `FranchiseProvider()` zero-arg / DesignTokens invention  
- No Cook/Cut/Crust as ingredient types  
- No new `wing_sauces` ingredient type  

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Menu rebuild M1–M4 pizza + optionalAddOns UX | Done on feature branch |
| Foundation seed Doughboys | Done |
| Wings + calzone product lock (W0) | Done (docs only) |

---

## 3. What’s next

1. W1: `MenuProfile.calzone` + templates  
2. W4/W5: mobile wings + calzone  
3. W3/W2: HQ editor + franchise sauce pool  
4. Seed + smoke → M5  

---

## 4. Key references

- `docs/slices/hq-wings-calzone-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  
- `packages/shared_core/.../menu_item.dart` (wings fields already present)  
- `packages/shared_core/.../menu_profile_templates.dart`  
- `mobile_app/.../customization_modal.dart`  
- `web-app/.../menu_item_editor_sheet.dart`  

---

**Bottom line:** Pizza UX locked and seeded. Next product work is **wings + calzone** per slice; do not start M5 until that acceptance is green unless human expands scope.
