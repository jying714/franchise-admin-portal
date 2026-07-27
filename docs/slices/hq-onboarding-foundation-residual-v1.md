# Slice: hq-onboarding-foundation-residual-v1

**Status:** MOSTLY COMPLETE (2026-07-26 night) — product path live; form dismiss watch  
**Branch:** `feat/onboarding-4step`  
**Surface:** HQ onboarding Step 3 (Core Menu Foundation) + Step 4 (Menu Items) gate

---

## Goal

Stop Menu Items from proceeding on broken ingredient typing; give a clear repair path on Foundation Ingredients; stop Flutter duplicate-key crashes on messy franchise data (e.g. Doughboys).

---

## Locked decisions

1. **Hard block** Menu Items until orphan count = 0.  
2. **Orphan** = `typeId` empty **or** not present in live franchise `ingredient_types` ids.  
3. **UX** = orphan filter + scroll/highlight **first** orphan (not highlight-all for large sets).  
4. **Unassigned** group at **top**; tooltip shows sample discrepancies.  
5. Group valid ingredients only under **canonical franchise type names** (case as stored on the type doc).

---

## Done

### Menu Items (`onboarding_menu_items_screen.dart`)

- Readiness uses unknown-type orphan rule + existing min typed/types/categories checks.  
- “Open Core Menu Foundation” sets `FoundationFocusRequest.showOrphansOnly` / `firstOrphanId` then `switchToSection('onboarding_menu_foundation')`.  
- Watches `IngredientMetadataProviderImpl` (and shell CNP wiring) so counts update without leaving HQ.

### Foundation (`onboarding_menu_foundation_screen.dart`)

- `FoundationFocusRequest` one-shot handoff.  
- Post-frame: if handoff, `_tabController.index = 1` (Ingredients).  
- Progress/continue orphan math aligned with unknown-type rule.

### Ingredients (`onboarding_ingredients_screen.dart`)

- Orphan FilterChip; ordered entries Unassigned-first.  
- List keys `id#index` (no Duplicate keys fatal).  
- Handoff applies filter + `scrollAndHighlightIngredient`.  
- Dialog: `useRootNavigator: false`; `onSaved` pops `dialogContext`.

### Form (`ingredient_form_card.dart`)

- One `Dialog` under `showDialog`.  
- After save: `saveChanges()` not full `saveAllChanges()`/`load()` under open dialog.  
- Type seed once (`_typeSeeded`).  
- Parent owns `Navigator.pop` via `onSaved`.

### Shell (`hq_onboarding_shell_screen.dart`)

- `ChangeNotifierProvider` + `ProxyProvider` for ingredient type/metadata Impl (live rebuilds).

---

## Watch / residual

- If dialog barrier still sticks after save: verify `[Ingredients] onSaved pop canPop=true` and that no second `SEED once` runs after pop.  
- Large franchise orphan sets are **data** work (assign types in Unassigned), not a missing gate.  
- Bulk type remap not in this slice.

---

## Key paths

- `web-app/lib/admin/hq_owner/onboarding/screens/onboarding_menu_items_screen.dart`
- `web-app/lib/admin/hq_owner/onboarding/screens/onboarding_menu_foundation_screen.dart`
- `web-app/lib/admin/hq_owner/onboarding/screens/onboarding_ingredients_screen.dart`
- `web-app/lib/admin/hq_owner/onboarding/widgets/ingredients/ingredient_form_card.dart`
- `web-app/lib/admin/hq_owner/onboarding/screens/hq_onboarding_shell_screen.dart`
