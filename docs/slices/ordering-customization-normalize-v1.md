# Slice: Ordering customization normalize v1

**Status:** Locked open (2026-10-01). Not started as a shared writer.  
**Authority:** STATUS · HANDOFF · ROADMAP · this file  
**Reference surface:** `mobile_app/lib/widgets/customization/customization_modal.dart` + `customization_controller.dart`  
**Must match:** `pos_app/lib/features/customization/pos_customization_sheet.dart`, `customer_web/lib/features/menu/menu_item_detail_screen.dart`  
**Catalog only (not an order customizer):** `web-app/lib/admin/menu/menu_item_form_dialog.dart`

---

## 1. Problem

Doughboys ordering customization is not one flow. Mobile is the most complete. POS and customer web each build and persist a different map. Kitchen tickets and cart edit assume POS-style keys. A mobile line will not reopen or print the same way.

## 2. Confirmed payload split (polish `d428a034`)

| Surface | Confirm map |
|---------|-------------|
| Mobile | `currentIngredients`, `groupSelections`, `selectedAddOns`, `size`, radio keys, `ingredientOptions`, `cheeses`, `cheeseOptions`, `sauces` as counts, `dressings` as counts, `sideDipCups`, `dippedSplits`, `ingredientAmounts`, `sauce: [{id, portion, amount}]` |
| POS | group-id lists, `size`, `wingHalves`, `portions`, `doubles`, `optionLabels`, `addonPrices`, `_linePrice` |
| customer_web | `size`, `toppings` / `cheeses` / `sauces` id lists, `portions`, `doubles`, `optionLabels`, `wingHalves`, `sideDipCups`, `cartSummary` |

## 3. Behavior gaps vs mobile

| Rule | Mobile | POS | customer_web |
|------|--------|-----|----------------|
| Pizza L/R + Double (max 4); cheeses max 2; sauces max 2 forced L+R | Yes | L/R pizza; Dbl pizza/calzone/sub/dinner | Yes for pizza/calzone/sub/wings |
| Sauce amount light/regular/extra | Yes | No | No |
| Salad dressings + `freeDressingCount` / extra upcharge | Yes (`MenuPricing.isSalad`) | Yes, local `_addonPrices` | No salad builder; category-name check only |
| Dinner included + optional | Yes | Dinner/standard extras group | No |
| Wings halves + Plain + dip cups | Yes | Yes | Yes |
| `config/menu_profile_wings` fallback | Yes | Not in sheet | Not in detail screen |
| Drinks flavor | `DrinksFlavorSelector` | No | No |
| Pricing | `shared.MenuPricing` | Local `_addonPrices` | Local `_unitPrice` |
| Edit prefill | Mobile map | `wingHalves` / `portions` / `doubles` | POS-shaped map only |

HQ must keep writing `menuProfile`, `freeDressingCount` / `maxFreeDressings`, `extraDressingUpcharge`, `sideDipSauceOptions`, `sideDipUpcharge`, `freeDipCupCount`. Empty wing sauce list must still resolve from franchise config on every order surface.

## 4. Required order

1. One payload writer in `packages/shared_core` used by all three confirm handlers. Emit ticket keys (`optionLabels`, `portions`, `doubles`, `wingHalves`, `sideDipCups`) and keep mobile sauce `amount` plus dressing counts.
2. customer_web salad dressing section and dinner included/optional section, using `MenuPricing.freeDressingCount`.
3. POS and customer_web load `franchises/{id}/config/menu_profile_wings` when the item sauce list is empty.
4. Sauce amount on POS and customer_web, or an explicit product drop on mobile. Do not leave three sauce products.
5. Drinks flavor stays mobile-only until a drink is sold on web and POS.

Do not add `Order.paymentMethod` or `Order.tableId` getters.

## 5. Out of this slice

WeekTally. iOS. Printer-by-category. Loyalty. Custom domains. Home composition Wave 2 (`docs/plans/home-page-composition-engine-v1.md`). Stripe Terminal. SendGrid credits.

## 6. Acceptance

- [ ] Shared writer; mobile, POS, and customer_web call it
- [ ] Same pizza line edits on the surface that created it and prints WHOLE/LEFT/RIGHT with names
- [ ] Salad free dressings + extra upcharge match on all three
- [ ] Wings Plain halves + dip cups match; empty item sauce list uses franchise wing config
- [ ] Dinner included/optional present on customer_web
