# Doughboys Pizzeria — Franchise Platform

**Monorepo** for **Web Admin Portal** + **Mobile Customer App** + **Shared Core**.

- **Web**: `franchisehq.io` — Admin dashboard (Flutter Web)
- **Mobile**: Customer ordering app (Flutter Android/iOS)
- **Backend**: Firebase (Firestore, Auth, Functions, Hosting)

---

## Current Status (June 06, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**

### Major Achievements
- Critical auth handoff & persistent spinner resolved (`main.dart`, `sign_in_screen.dart`, `AdminUserProvider`, `FranchiseProvider`)
- `hq_owner` login now fully functional with correct `franchiseId` resolution (`"test"`)
- Franchise-aware providers stabilized (`FranchiseProvider.initializeWithUser`, `setFranchiseId`)
- Large-scale surgical cleanup of duplicated widgets, type issues, deprecated APIs, and RenderFlex overflows
- Firestore security rules refined for proper `hq_owner` access
- Dynamic theming, QR/deep linking, and core ordering flow production-ready

**Next Phase**: P3 – Advanced Features & Production Readiness

---

## Quick Start

```bash
git clone https://github.com/jying714/franchise-admin-portal.git
cd franchise_platform

# Web Admin Portal
cd web-app
flutter clean && flutter pub get && flutter gen-l10n
flutter run -d chrome

# Mobile App
cd mobile_app
flutter clean && flutter pub get && flutter gen-l10n
flutter run