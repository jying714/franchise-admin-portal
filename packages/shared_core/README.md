# shared_core

**Shared Core Package** – Single source of truth for the Franchise Admin Portal monorepo.

## Purpose

Shared models, providers, services, and configs for **web-app**, **mobile_app**, **customer_web**, and **pos_app**.

## Key Components

### Models (`lib/src/core/models/`)

- `User`, `FranchiseInfo`, `MenuItem`, `Category`, `Order`, `OrderItem`, etc.
- **`Promo`** — industry types (percent, amount, item_*, bogo, free_item, delivery), daypart, topping rules, legacy normalize
- **`Banner`** + **`Action`** — menu carousel slides

### Providers (`lib/src/core/providers/`)

- `FranchiseProvider` — franchise context, branding, **`pendingPromoCode`** (banner → checkout)
- `AdminUserProvider`, `UserProfileNotifier`, …

### Services (`lib/src/core/services/`)

- `FirestoreService` / `FirestoreServiceImpl`
- **`PromoPricing`** — pure `evaluate({ promo, lines, subtotal, deliveryFee, channel })`
- `InventoryLedger`, labor, auth, analytics, …

### Configs (`lib/src/core/config/`)

- Franchise-scoped design tokens / branding / features (see firestore-per-franchise-config)

## Promo rules (strict)

- All customer discount math goes through **`PromoPricing`** — do not hardcode codes in apps
- Codes path: `franchises/{id}/promotions`; banners: `franchises/{id}/banners`
- Export: `shared_core.dart` / `services.dart` must export `promo_pricing.dart`

Authority: `docs/slices/promo-system-v1.md`

## Architecture Rules

- Import via `package:shared_core/shared_core.dart` as `shared`
- Franchise scoping under `franchises/{franchiseId}/...`
- `FranchiseProvider` is runtime franchise + branding source of truth
- Changes affect all apps — keep backward-compatible Firestore reads

## Development

```bash
cd packages/shared_core
flutter clean
flutter pub get
flutter analyze
```

## Related Documentation

- Root `STATUS.md` · `HANDOFF.md`
- `docs/architecture/firestore-per-franchise-config.md`
- `docs/slices/promo-system-v1.md`
- `AGENT_SYSTEM.md`

**Last Updated**: August 9, 2026
