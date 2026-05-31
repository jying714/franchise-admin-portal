# Doughboys Pizzeria — Franchise Platform

**Monorepo** for **Web Admin Portal** + **Mobile Customer App**.

- **Web**: `franchisehq.io` — Admin dashboard (Flutter Web)
- **Mobile**: Customer ordering app (Flutter Android/iOS)
- **Backend**: Firebase (Firestore, Auth, Functions, Hosting)

## Current Status (May 30, 2026)

**P2 – White-Label & Scalability: NEARLY COMPLETE**

**Major Achievements**
- Full dynamic theming reactivity + remote logo handling
- Real QR Code Scanner (`mobile_scanner`) + Deep Linking (`fhq://` + https)
- Comprehensive styling cleanup (Tier 1–3) — UiConfig is now dominant
- Firebase multi-tenant hardening + security rules proposal
- FranchiseProvider unification + strict scoping under `franchises/{franchiseId}/...`

**Next (Phase 2.3)**
- Deploy security rules
- Comprehensive testing + error boundaries
- Payment gateway foundations
- Production build validation

## Quick Start

```bash
git clone https://github.com/jying714/franchise-admin-portal.git
cd franchise_platform

# Mobile
cd mobile_app
flutter pub get
flutter run

# Web Admin
cd web-app
flutter pub get
flutter run -d chrome