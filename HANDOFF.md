# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 28, 2026 (~12:45 CDT — pizza customization UX locked)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/menu-modifier-system-rebuild-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 28)

### What landed

| Area | What |
|------|------|
| **HQ editor** | Restored **Included toppings** + **Optional add-ons** via `MultiIngredientSelector`; save persists draft lists (no longer wipes to `const []`) |
| **shared_core** | `includedIngredients` parse accepts **string ids** as well as maps |
| **Mobile pizza** | Available meats/veggies/cheeses/sauces from **`optionalAddOns` by `typeId`** |
| **Current Toppings** | Food only; cheeses & sauces excluded |
| **Additional** | Meats \| Veggies tabs from optional pool minus Current |
| **Cheeses** | ExpansionTile Add/Remove + portion + Regular/Double; included pre-selected; not moved to Current |
| **Sauces** | **Same UI as cheeses** (not SauceSelectorGroup radios/clear); pool = optional ∪ included; included sauce pre-selected |
| **Platform** | Categories stream; ChangeNotifierProvider FranchiseProvider; Android Gradle/JVM align on Minisforum |

**Human smoke (CBR):** PASS for this contract.

### Locked product rules (do not regress)

1. **`optionalAddOns`** = available pool for pizza typed sections (meats, veggies, cheeses, sauces by `typeId`).
2. **`includedIngredients`** = defaults; food → Current; cheeses/sauces → pre-select in their sections only.
3. **modifierGroups** = crust/cook/cut + max/maxFree rules; do not replace optionalAddOns as the customer-facing available list when optionalAddOns is populated.
4. Cheeses and sauces **never** appear under Current Toppings.
5. Flat Optional add-ons block **hidden** on pizza/calzone.
6. Do not reintroduce SauceSelectorGroup as the primary pizza sauces UI.

### Still open

1. Full Doughboys re-seed under this contract  
2. Broader M4 QA (wings / standard / Liberty)  
3. **M5** cutover  
4. Developer dashboard  

### Prior product rules (still valid)

- Cook/Cut/Crust = label-only modifier options, never ingredient types  
- Web authors rules; mobile enforces  
- No production `category.contains('pizza')` for behavior (profile-first)  
- No DesignTokens invention; no `FranchiseProvider()` zero-arg  

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Menu rebuild M1–M3 HQ + M3 Admin | Done on feature branch |
| M4 pizza path + optionalAddOns UX | Done on feature branch |

---

## 3. What’s next

1. Re-seed remaining menu items like CBR (included + full optionalAddOns by type)  
2. Smoke matrix non-pizza  
3. M5 cutover + merge when green  
4. Developer dashboard  

---

## 4. Key files (this arc)

- `web-app/lib/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart`
- `mobile_app/lib/widgets/customization/customization_modal.dart`
- `packages/shared_core/lib/src/core/models/menu_item.dart`
- `mobile_app/android/*` (Gradle toolchain; Minisforum)

---

**Bottom line:** Pizza customization contract is **human-locked**. Agents must not strip included/optional HQ fields or collapse cheeses/sauces back into Current or SauceSelectorGroup. Next is seed + M5.
