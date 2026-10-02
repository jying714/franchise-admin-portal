# HANDOFF.md

**As of:** October 1, 2026  
**Active branch:** `feat/pre-hardware-hq-polish`  
**Soft-release:** `main`

---

## How to start the next chat

| Priority | Path |
|----------|------|
| 1 | `STATUS.md` |
| 2 | `HANDOFF.md` |
| 3 | `docs/slices/ordering-customization-normalize-v1.md` |
| 4 | `docs/slices/pos-app-v1.md` |
| 5 | `docs/DECISIONS.md` (Decision **15**) |

**Repo:** https://github.com/jying714/franchise-admin-portal  
**Local:** `C:\\projects\\franchise-admin-portal`  
**Firebase:** `doughboyspizzeria-2b3d2`

```powershell
cd C:\\projects\\franchise-admin-portal
git fetch origin
git checkout feat/pre-hardware-hq-polish
git pull origin feat/pre-hardware-hq-polish
```

---

## Hosting lock — WeekTally domain

WeekTally is not franchiseHQ MVP. It must keep working at franchisehq.io `/tally`.

`firebase.json` admin target on this branch (`b6692319`) and on `main` rewrites `/tally/api/**`, `/tally`, and `/tally/**` to Cloud Run `weektally` in `us-central1`, before the `**` catch-all. Do not remove those rewrites. Do not deploy Hosting from a tree that lacks them.

---

## Resume here

Ordering flow must be normalized. Mobile is the reference. Do not start iOS, printer-by-category, loyalty, custom domains, home composition Wave 2, or WeekTally product work.

1. Shared cart payload in `packages/shared_core`, called from mobile confirm, `pos_customization_sheet.dart` `_payload()`, and customer_web `_buildPosCustomizationsMap()`.
2. customer_web salad dressings + dinner included/optional (`menu_item_detail_screen.dart` has neither).
3. POS and customer_web: `franchises/{id}/config/menu_profile_wings` when the item sauce list is empty.
4. Sauce amount on POS and web, or an explicit drop on mobile.
5. Then merge this branch to `main`. `functions/functions/delivery_range.ts` is not on `main`.

August 21 idle-fail and “delivery range next” notes are stale relative to commit `d428a034`. Re-smoke idle before checking that box. Delivery range is on HQ store_ops and customer_web on this branch; mobile checkout and POS entry still do not call `estimateDeliveryRange`.

---

## Out of MVP

WeekTally product work (`/tally` hosting rewrites stay). iOS. Printer-by-category (`station_settings_panel.dart` coming soon; one TSP143). Loyalty. Custom domains. Home composition Wave 2 (HQ widget studio). Drinks flavor until a drink is sold on web and POS.

---

## Shipped on this branch (still true)

- Profile builders in `pos_customization_sheet.dart` (not mobile-parity).
- Cash tip close-out, EOD, StarGraphic + DK drawer.
- `d428a034`: PIN pad, idle overlay work, delivery range callable, storefront cart/checkout polish.
- `b6692319`: admin `/tally` rewrites restored on this branch.

**Do not add** `paymentMethod` / `tableId` to `Order` — read the order document.

---

## Operating rules

- Human is merge gate; agents proposal-only
- Prefer real paths; no invented schema fields
- Quote source for surgical edits
- Do not deploy Hosting without the `/tally` rewrites

**Bottom line:** Next work is ordering customization normalize, then merge polish to `main`.
