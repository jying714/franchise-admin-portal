# Doughboys Pizzeria Mobile App

Customer-facing Flutter app (Android + iOS) for the multi-tenant white-label franchise platform.

## Current Status (June 06, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**

Core ordering flow is stable and device-tested. The app now shares the same `shared_core` architecture as the web portal.

### Key Features
- Dynamic branding per franchise (colors, logo, name, theming)
- Real-time menu with advanced customization
- Cart, checkout, order history, and scheduled orders
- Favorites & Loyalty system
- QR Scanner + Deep Linking support
- Fully franchise-scoped data under `franchises/{franchiseId}/...`
- Shared models, providers, and services with the web admin portal

## Development

```bash
cd mobile_app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run