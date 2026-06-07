# Doughboys Pizzeria Web Admin Portal

Flutter Web admin dashboard for franchise owners, HQ users, and platform admins.

## Current Status (June 06, 2026)

**P2.5 Web-App Cleanup Sprint: COMPLETE**

### Major Achievements
- Critical login flow & auth handoff stabilized (`main.dart`, `sign_in_screen.dart`, providers)
- `hq_owner` dashboard now loads correctly with proper `franchiseId` resolution
- Franchise-aware providers (`FranchiseProvider`, `AdminUserProvider`) unified
- Large-scale cleanup of type issues, duplicated code, deprecated APIs, and RenderFlex overflows
- Dynamic theming, QR/deep linking foundations, and core admin UI stabilized
- Firestore security rules refined for proper `hq_owner` access

## Features
- Dynamic white-label branding per franchise
- Menu, Category, Ingredient management with onboarding wizard
- Orders, analytics, staff, and financial tools
- Subscription & billing management
- Franchise picker and role-based dashboards
- Real-time updates via Firestore

## Development

```bash
cd web-app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run -d chrome