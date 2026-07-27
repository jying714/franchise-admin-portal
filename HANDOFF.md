# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 27, 2026 (menu-modifier M1–M3 HQ)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/menu-modifier-system-rebuild-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\projects\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 27, 2026 — evening)

### Admin ops (closed)

- Slice `admin-dashboard-ops-fixes-v1` completed and **merged to `main`**.
- Categories persist/delete/bulk; promos CRUD; orders ⋮ + refund + Refunded filter; Active Promotions KPI; menu delete snackbar duration; Import CSV / Columns removed from overflow.

### Menu modifier rebuild (active)

Authority: Decision **10**, `docs/slices/menu-modifier-system-rebuild-v1.md`.

**Landed on `feat/menu-modifier-system-rebuild-v1`:**

- **M1:** `modifier_group.dart`, `menu_profile_templates.dart`; MenuItem `menuProfile`, `modifierGroups`, inventory fields; exports in `models.dart`.
- **M2:** `effectiveMenuProfile` / `effectiveModifierGroups` legacy adapter on MenuItem.
- **M3 HQ:** Profile-first `menu_item_editor_sheet`; pizza hides base price; size-derived price on save; `Modifier_groups_ingredient_binder` (type-filtered chips, min/max/maxFree); structural types filtered in multi-ingredient selector; legacy included/optional/customizationGroups UI **removed**; save clears legacy lists; inventory switch + stock count persist.
- Pizza template seeds: Crust/Cook/Cut (label-only), Sauce, Meats/Veggies/Cheeses.
- Human **wiped** Doughboys `menu_items` for clean canonical re-seed.

**Still open (web then mobile):**

- M3 **Admin** Menu editor parity + remove Customize spinner.
- M4 mobile schema-driven modal (emulator setup pending).
- M5 cutover / delete dual production paths.

### Product rules (do not regress)

- Optional customer add-ons = **modifier groups with min 0** + size topping upcharge / option upcharge — **not** a separate optionalAddOns editor.
- Web authors **rules**; mobile **enforces** them (M4).
- Cook/Cut/Crust never as ingredient types.

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Foundation residual / ingredient group edit | Done |

---

## 3. What’s next

1. Finish **web** remaining: Admin Menu canonical write / Customize dead  
2. Re-seed Doughboys menu items via HQ under new schema  
3. M4 mobile when emulator ready  
4. M5 cutover  
5. Developer dashboard  

**Not next:** Cash Flow / Multi-brand HQ cards.

---

## 4. Architecture reminders

- `shared_core` SSoT; franchise-scoped Firestore  
- HQ Menu Items = guided; Admin Menu = day-2; same schema (Decision 9)  
- No DesignTokens invention; no `FranchiseProvider()` zero-arg  

---

**Bottom line:** Admin ops closed. Menu rebuild **HQ write path live** on feature branch; Admin + mobile + cutover remain. Pull `feat/menu-modifier-system-rebuild-v1` before continuing.
