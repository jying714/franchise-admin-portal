# shared_core

**Shared Core Package** – Single source of truth for the Doughboys Pizzeria Franchise Platform.

## Purpose
Contains all shared models, providers, services, configs, and utilities used by both the **Web Admin Portal** and **Mobile Customer App**.

## Key Components

### Models (`lib/src/core/models/`)
- `User`, `FranchiseInfo`, `MenuItem`, `Category`, `Order`, `AlertModel`, `LocalizationOverride`, etc.
- All business entities live here.

### Providers (`lib/src/core/providers/`)
- `FranchiseProvider` – Central franchise state + branding + hybrid single/multi-location logic
- `AdminUserProvider` – User role & permissions
- `UserProfileNotifier` – Profile data stream

### Configs (`lib/src/core/config/`)
- `design_tokens.dart`, `app_config.dart`, `branding_config.dart`, `feature_config.dart`, `ui_config.dart`
- **Fully franchise-scoped and dynamic** (Firestore-backed with strong defaults)
- Authoritative reference: `/docs/architecture/firestore-per-franchise-config.md`

### Services (`lib/src/core/services/`)
- `FirestoreService` (Abstract + Impl)
- `AuthService`, `InvoiceService`, `AnalyticsService`, `FranchiseOnboardingService`, etc.

### Utils
- `ErrorLogger`, `LocalStorage`, `FeatureGate`, `LocalizationService` (hybrid hardcoded + DB)

## Architecture Rules (Strict)
- All screens import via `package:shared_core/shared_core.dart` as `shared`
- Franchise scoping enforced everywhere (`franchises/{franchiseId}/...`)
- `FranchiseProvider` is the single source of truth for current franchise context, branding, and hybrid logic
- Dynamic theming, FeatureGate, and config-driven UI are mandatory
- Changes here affect both web and mobile — maintain backward compatibility and test thoroughly
- Agent work must follow `AGENT_SYSTEM.md` rules (scope control, human review on config/schema changes)

## Development
```bash
cd packages/shared_core
flutter clean
flutter pub get
flutter analyze
Related Documentation

ARCHITECTURE.md
MOBILE_DYNAMIC.md
DASHBOARDS.md
AGENT_SYSTEM.md (multi-agent governance and scope rules)
ROADMAP.md
/docs/architecture/firestore-per-franchise-config.md ← Config & Firestore Schema Authority

Last Updated: July 20, 2026