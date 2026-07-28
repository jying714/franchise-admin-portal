# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 28, 2026 (~00:50 CDT — menu-modifier M3 Admin + M4 pizza)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/menu-modifier-system-rebuild-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 27 night → July 28 early morning)

### Menu modifier rebuild — where we landed

Authority: Decision **10**, `docs/slices/menu-modifier-system-rebuild-v1.md`.

**Already on branch before this arc:**

- **M1:** `modifier_group.dart`, `menu_profile_templates.dart`; MenuItem `menuProfile`, `modifierGroups`, inventory fields.
- **M2:** `effectiveMenuProfile` / `effectiveModifierGroups`.
- **M3 HQ:** Profile-first editor, binder, min/max/maxFree, pizza size pricing, inventory, legacy dual UI removed.
- Doughboys `menu_items` wiped for clean re-seed; Cook/Cut/Crust removed from ingredient types.

**Landed this arc (commits on `feat/menu-modifier-system-rebuild-v1`):**

| Area | What |
|------|------|
| **M3 Admin** | `MenuItemEditorPanel` hosts shared `MenuItemEditorSheet`; `AdminFirestoreService.saveMenuItem`; `MenuItemProvider` sync; UUID when id empty; always write `sortOrder`; `getMenuItems` client-side sort so docs without sortOrder still load |
| **M4 Web** | `customization_modal.dart`: `_groupsForUi`, profile-first pizza/wings, maxFree, min/max submit, SizeData `.label` keys, optionLabels, structural filter |
| **M4 Mobile entry** | `menu_item_card.dart`: `_hasCustomizations` includes `modifierGroups` and `sizes` (canonical pizza no longer Add-to-cart only) |
| **M4 Mobile modal** | `_groupsForUi`, radio/select via groups, min/max, topping/cheese max, maxFree pricing, SizeData `basePrice`/`toppingPrice`, Current Toppings empty-hide + structural filter, cart payload excludes crust/cook/cut ids, optionLabels on tabs/cheeses/radios, skip empty tabs/cheeses |
| **Radio widgets** | Mobile + web `radio_customization_group.dart` use `optionLabels` |

### Device / product smoke (human-verified)

- Samsung S25 debug: categories + menu load; **Customize** opens on HQ pizza.
- Order Details shows Crust / Cook / Cut with human labels.
- Current toppings does **not** list `crust_*` / `cook_*` / `cut_*`.
- Confirm → cart customizations keep structural choices via radio keys; not as topping ids in `currentIngredients`.

### Known data gaps (not code blockers)

- Partial re-seed only (e.g. CBR pizza): empty `includedIngredients`, empty veggies options, no sauces group → empty Current toppings / limited Additional is **expected** until HQ binds more options.
- Liberty Diner legacy items still load via adapter for regression.

### Still open

1. Full Doughboys re-seed under canonical schema  
2. Broader M4 QA (non-pizza profiles)  
3. **M5** cutover — STATUS marks complete **only after M5**  
4. Developer dashboard (after menu path clear)

### Product rules (do not regress)

- Optional add-ons = **modifier groups with min 0** + size topping upcharge — not a separate optionalAddOns editor.
- Web authors **rules**; mobile **enforces** them.
- Cook/Cut/Crust never as ingredient types.
- Current toppings ≠ Order Details structural radios.

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Foundation residual / ingredient group edit | Done |
| Menu rebuild M1–M3 HQ | Done on feature branch |
| Menu rebuild M3 Admin | Done on feature branch |
| Menu rebuild M4 pizza path (web + mobile) | Done on feature branch |

---

## 3. What’s next

1. Re-seed Doughboys pizza/wings/standard items with full groups (sauces, included toppings, veggies)  
2. Smoke matrix: pizza maxFree pricing, wings, standard dessert, legacy franchise  
3. M5 cutover plan + merge when green  
4. Developer dashboard  

**Not next:** Cash Flow / Multi-brand HQ cards.

---

## 4. Architecture reminders

- `shared_core` SSoT; franchise-scoped Firestore  
- HQ Menu Items = guided; Admin Menu = day-2; same schema (Decision 9)  
- No DesignTokens invention; no `FranchiseProvider()` zero-arg  
- `SizeData`: `label`, `basePrice`, `toppingPrice` (typed doubles)

---

## 5. Key files touched (M3 Admin / M4)

- `packages/shared_core/lib/src/core/models/menu_item.dart`
- `packages/shared_core/lib/src/core/services/firestore_service_impl.dart`
- `web-app/lib/admin/menu/menu_item_editor_panel.dart`
- `web-app/lib/admin/menu/menu_editor_screen.dart`
- `web-app/lib/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart`
- `web-app/lib/admin/hq_owner/onboarding/widgets/menu_items/menu_item_utility.dart`
- `web-app/lib/widgets/customization/customization_modal.dart`
- `web-app/lib/widgets/customization/radio_customization_group.dart`
- `mobile_app/lib/widgets/menu_item_card.dart`
- `mobile_app/lib/widgets/customization/customization_modal.dart`
- `mobile_app/lib/widgets/customization/radio_customization_group.dart`

---

**Bottom line:** Admin ops closed on `main`. Menu rebuild **HQ + Admin write + M4 pizza runtime** live on feature branch. Next is data completeness, broader QA, then **M5 cutover**. Pull `feat/menu-modifier-system-rebuild-v1` before continuing.
