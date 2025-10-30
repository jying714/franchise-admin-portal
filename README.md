# Doughboys Pizzeria — Franchise Platform

Monorepo for **web admin portal** + **mobile customer app**.

- **Web**: `franchisehq.io` — Admin dashboard (Flutter Web)
- **Mobile**: Customer ordering app (Flutter Android/iOS)
- **Backend**: Firebase (Firestore, Auth, Functions, Hosting)

---

## Quick Start

```bash
# Clone
git clone https://github.com/jying714/franchise-admin-portal.git
cd franchise-admin-portal

# Web (Admin)
cd web-app
flutter pub get
flutter run -d chrome

# Mobile
cd ../mobile_app
flutter pub get
flutter run