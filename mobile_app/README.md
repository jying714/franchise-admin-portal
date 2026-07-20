# Doughboys Pizzeria Mobile App

Customer-facing Flutter app (Android + iOS) for the multi-tenant white-label franchise platform.  
**One published binary** that can serve unlimited franchises and restaurant types.

## Current Status (July 20, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**

Core ordering flow is stable and device-tested on Samsung S25. The app now shares the same `shared_core` architecture as the web portal.

### Key Features
- Dynamic branding per franchise (colors, logo, name, theming) via shared configs
- Real-time menu with advanced customization
- Cart, checkout, order history, and scheduled orders
- Favorites & Loyalty system
- QR Scanner + Deep Linking support for franchise claiming
- Fully franchise-scoped data under `franchises/{franchiseId}/...`
- **Dynamic UI** — transitioning from pizzeria-hardcoded to fully config-driven (restaurantType support, FeatureGate)

## Development

```bash
cd mobile_app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run

Architecture Notes

All business logic, models, providers, and services come from shared_core
UI is becoming fully dynamic based on configs, restaurantType, FeatureGate, and hybrid single/multi-location logic
Offline support (menu cache + order queue) planned for MVP
Agent work must follow strict scope rules (see AGENT_SYSTEM.md) with human review on major changes

Related Documentation

ARCHITECTURE.md
MOBILE_DYNAMIC.md
DASHBOARDS.md
AGENT_SYSTEM.md (multi-agent governance)

Last Updated: July 20, 2026