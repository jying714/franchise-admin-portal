# Doughboys Pizzeria Mobile App

Customer-facing Flutter app (Android + iOS) for the multi-tenant white-label franchise platform.  
**One published binary** that can serve unlimited franchises and restaurant types.

## Current Status (August 9, 2026)

**Soft-release software on main** with shared_core ordering, branding, and **promo apply**.  
Prefer root **`STATUS.md`** / **`HANDOFF.md`**. iOS / TestFlight when Mac available; Android pilot stable.

### Key Features
- Dynamic branding per franchise via `shared_core`
- Real-time menu with advanced customization
- Cart, checkout, order history, scheduled orders
- **Promo codes** at checkout via `PromoPricing` (no hardcoded codes)
- **Menu banners** → `pendingPromoCode` on `FranchiseProvider` → checkout auto-apply
- Favorites & Loyalty system
- QR Scanner + deep linking for franchise claiming
- Franchise-scoped data under `franchises/{franchiseId}/...`

### Promo paths

| Path | File |
|------|------|
| Checkout apply | `lib/features/ordering/checkout_screen.dart` |
| Banner tap | `lib/widgets/banner/banner_action_handler.dart` (`case 'promo'`) |
| Carousel host | `lib/features/main_menu/main_menu_screen.dart` + `banner_carousel.dart` |
| Engine | `package:shared_core` → `PromoPricing` |

Authority: `docs/slices/promo-system-v1.md`

## Development

```bash
cd mobile_app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run
```

## Architecture Notes

- Business logic/models/services from `shared_core`
- UI config-driven (`restaurantType`, FeatureGate) where wired
- Agent work follows `AGENT_SYSTEM.md` with human review on major changes

## Related Documentation

- Root `STATUS.md` · `HANDOFF.md`
- `docs/MOBILE_DYNAMIC.md` · `docs/slices/promo-system-v1.md`
- `AGENT_SYSTEM.md`

**Last Updated**: August 9, 2026
