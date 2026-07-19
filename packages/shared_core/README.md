# shared_core

**Shared Core Package** – Single source of truth for the Doughboys Pizzeria Franchise Platform.

## Purpose
Contains all shared models, services, providers, configs, and utilities used by both the **Web Admin Portal** and **Mobile Customer App**.

## Key Components

### Models (`lib/src/core/models/`)
- `User`, `FranchiseInfo`, `MenuItem`, `Category`, `Order`, `AlertModel`, etc.
- All business entities live here.

### Providers (`lib/src/core/providers/`)
- `FranchiseProvider` – Central franchise state + branding + hybrid single/multi-location logic
- `AdminUserProvider` – User role & permissions
- `UserProfileNotifier` – Profile data stream

### Configs (`lib/src/core/config/`)
- `design_tokens.dart`, `app_config.dart`, `branding_config.dart`, `feature_config.dart`, `ui_config.dart`
- Fully franchise-scoped and dynamic

### Services (`lib/src/core/services/`)
- `FirestoreService` (Abstract + Impl)
- `AuthService`, `InvoiceService`, `AnalyticsService`, etc.

### Utils
- `ErrorLogger`, `LocalStorage`, `DesignTokens` base, FeatureGate

## Architecture Rules (Strict)
- All screens import via `package:shared_core/shared_core.dart` as `shared`
- Franchise scoping enforced everywhere (`franchises/{franchiseId}/...`)
- `FranchiseProvider` is the single source of truth for current franchise context, branding, and hybrid logic
- Dynamic theming, FeatureGate, and config-driven UI are mandatory
- Changes here affect both web and mobile — maintain backward compatibility

## Development
```bash
cd shared_core
flutter clean
flutter pub get
flutter analyze

Related Documentation

ARCHITECTURE.md
MOBILE_DYNAMIC.md