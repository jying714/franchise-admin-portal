# Slice: Promo system v1 (Codes + Banners)

**Status:** COMPLETE on `main` (August 9, 2026)  
**Commits:** `e73c2f42` (engine + hub + apply), `a5c84d92` (templates, daypart, toppings, banner pending)

---

## Product model

| Layer | Role |
|-------|------|
| **Promo (Codes)** | Pricing rules + redemption code under `franchises/{id}/promotions` |
| **Banner** | Marketing slide under `franchises/{id}/banners`; optional **Promote a deal** → code |
| **PromoPricing** | Shared pure evaluator used by mobile + customer_web checkout |

Do **not** merge banners into promo docs. Banner never *is* the discount.

---

## Types supported

| `PromoType` | Meaning |
|-------------|--------|
| `percent` / `amount` | Cart-level off (optional item/size/topping scope) |
| `item_percent` / `item_amount` | Qualifying lines only |
| `bogo` | Buy X get Y at % off (`bogoBuyQty`, `bogoGetQty`, `bogoGetDiscountPct`, `bogoApplyTo`) |
| `free_item` | Free menu item (optional max price) |
| `delivery` | Free / amount / percent off delivery fee |

**Qualification:** `qualifyMenuItemIds`, `qualifyCategoryIds`, `qualifySizeLabels`, min/max/exact toppings (`qualifyMinToppings` / `qualifyMaxToppings`).  
**Daypart:** `daysOfWeek` (1=Mon…7=Sun), `daypartStart` / `daypartEnd` (`HH:mm`); enforced via `Promo.isLiveAt` → engine.

Legacy docs: `value` → discount, junk `type` → amount, `title` → name.

---

## Admin (web-app)

| File | Role |
|------|------|
| `promo_management_screen.dart` | Codes \| Banners tabs |
| `promo_template_picker_dialog.dart` | Template cards before Add |
| `promo_form_dialog.dart` | Live menu chips, BOGO, daypart, toppings mode |
| `promo_banners_panel.dart` | Banner list; subtitle “Promotes CODE” |
| `banner_form_dialog.dart` | When customer taps: promote deal / category / item / url / none |

Firestore: `AdminFirestoreService.streamFranchiseBanners` / `saveFranchiseBanner` / `deleteFranchiseBanner`.

---

## Customer surfaces

| Surface | Behavior |
|---------|----------|
| Mobile checkout | Resolve code via `getPromos` + `PromoPricing.evaluate`; no `PIZZA10` |
| customer_web checkout | Same engine path |
| Mobile main menu banners | Existing `BannerCarousel` + `BannerActionHandler` |
| Banner `promo` tap | `FranchiseProvider.setPendingPromoCode` → checkout consumes once |

---

## Key shared APIs

```text
packages/shared_core/lib/src/core/models/promo.dart
packages/shared_core/lib/src/core/services/promo_pricing.dart
FranchiseProvider.pendingPromoCode / setPendingPromoCode / clearPendingPromoCode
```

Export via `shared_core` barrel / `services.dart`.

---

## Explicit non-goals (v1)

- Combo / bundle fixed package price  
- Prix-fixe multi-course  
- Stacking multiple codes  
- First-order-only / win-back identity checks  
- Full category-id → menu-item expansion inside engine (item ids preferred)  
- POS code entry (manager discount remains station-side)  

---

## Smoke checklist

1. Admin: template BOGO + Medium + min toppings 2 → Firestore fields present  
2. Admin: happy hour days + times → outside window fails apply  
3. Mobile: apply code → summary + order.discount  
4. Banner promote deal → snackbar → checkout auto-apply  
5. customer_web: same code applies at checkout  
