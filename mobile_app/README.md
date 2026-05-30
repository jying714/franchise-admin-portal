# Doughboys Pizzeria — Franchise Platform

**Monorepo** for **Web Admin Portal** + **Mobile Customer App** + **Shared Core**.

- **Web**: `franchisehq.io` — Full admin dashboard (Flutter Web)
- **Mobile**: Customer ordering app (Flutter Android/iOS)
- **Backend**: Firebase (Firestore, Auth, Functions, Hosting)
- **Shared Core**: Pure domain layer (`packages/shared_core`)

---

## Current Status (May 30, 2026)

**Option B – Core Ordering Flow: COMPLETE ✅**  
The customer ordering path is stable and device-tested on Samsung S25:

**Login → Franchise Selection → Menu → Category → Item → Customization → Cart → Checkout → Confirmation**

- FranchiseProvider unification complete (shared_core is the single source of truth).
- All direct `src/` imports cleaned across 6 batches.
- Duplicated models cleaned (Address, Banner, Category, MenuItem, Order, ScheduledOrder, etc.).
- FirestoreService 3-tier split enforced.
- No more fallback spam ("unknown"/"default").

**Git Branch**: `fix/core-flow-stabilization-phase1` (active)

---

## Quick Start

```bash
# Clone
git clone https://github.com/jying714/franchise-admin-portal.git
cd franchise-admin-portal

# Mobile (Customer App)
cd mobile_app
flutter pub get
flutter run

# Web (Admin Dashboard)
cd ../web-app
flutter pub get
flutter run -d chrome