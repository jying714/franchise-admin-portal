# shared_core

**Shared Core Package** – Single source of truth for the Doughboys Pizzeria Franchise Platform.

## Purpose
Contains all shared models, services, providers, and utilities used by both the **Web Admin Portal** and **Mobile Customer App**.

## Key Components

### Models (`lib/src/core/models/`)
- `User`, `FranchiseInfo`, `MenuItem`, `Category`, `Order`, `AlertModel`, etc.
- All business entities live here.

### Providers (`lib/src/core/providers/`)
- `FranchiseProvider` – Central franchise state + branding
- `AdminUserProvider` – User role & permissions
- `UserProfileNotifier` – Profile data stream

### Services (`lib/src/core/services/`)
- `FirestoreService` (Abstract + Impl)
- `AuthService`, `InvoiceService`, `AnalyticsService`, etc.

### Utils
- `ErrorLogger`, `LocalStorage`, `DesignTokens` base

## Architecture Rules
- All screens import via `package:shared_core/shared_core.dart` as `shared`
- Franchise scoping enforced everywhere (`franchises/{franchiseId}/...`)
- `FranchiseProvider` is the single source of truth for current franchise context

## Development
```bash
cd shared_core
flutter pub get
flutter analyze