# Doughboys Pizzeria Web Admin Portal

Flutter Web admin dashboard for franchise owners, HQ users, platform admins, and developers.

## Current Status (July 20, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**

### Major Achievements
- Critical login flow & auth handoff stabilized
- `hq_owner` dashboard loads correctly with proper `franchiseId` resolution
- Franchise-aware providers (`FranchiseProvider`, `AdminUserProvider`) unified
- Large-scale cleanup of duplicated code, type issues, and UI problems
- Dynamic theming, QR/deep linking, and core admin UI stabilized
- Firestore security rules refined
- 4-step onboarding flows stabilized

## Features
- **Dynamic white-label branding** per franchise (via dedicated Design & Branding page with live preview)
- Menu, Category, Ingredient management with onboarding wizard
- Orders, analytics, staff, and financial tools
- Subscription & billing management
- Franchise picker and role-based dashboards (HQ Owner, Admin/Staff, Developer)
- Real-time updates via Firestore
- Hybrid single/multi-location support with automatic UI simplification

## Development

```bash
cd web-app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run -d chrome

Architecture Notes

All business logic and models come from shared_core
Design & Branding page allows franchise owners to manage their look & feel with live preview (franchise-scoped)
Role-based access, dashboard switching, and FeatureGate supported
Agent work must follow AGENT_SYSTEM.md rules with human review on architecture, config, and design changes

Related Documentation

ARCHITECTURE.md
DASHBOARDS.md
ROADMAP.md
AGENT_SYSTEM.md (multi-agent governance)

Last Updated: July 20, 2026