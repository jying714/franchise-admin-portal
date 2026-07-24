# Doughboys Pizzeria Web Admin Portal

Flutter Web admin dashboard for franchise owners, HQ users, platform admins, and developers.

## Current Status (July 24, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**  
**Phase 1 Workstream B**: Live branding path wired; HQ Live Branding card (colors + app name); dark theme verified

### Major Achievements
- Critical login flow & auth handoff stabilized
- `hq_owner` dashboard loads correctly with proper `franchiseId` resolution
- Franchise-aware providers (`FranchiseProvider`, `AdminUserProvider`) unified
- Large-scale cleanup of duplicated code, type issues, and UI problems
- Dynamic theming, QR/deep linking, and core admin UI stabilized
- Firestore security rules refined
- 4-step onboarding flows stabilized (currently still launched from Admin paths)
- Web live branding: `FranchiseProvider` → `DesignTokens.setFranchiseProvider` → live primary/secondary

## Features
- **Dynamic white-label branding** per franchise (HQ Live Branding preview card; full Design & Branding page still open)
- Menu, Category, Ingredient management with onboarding wizard
- Orders, analytics, staff, and financial tools
- Subscription & billing management
- Franchise picker and role-based dashboards (HQ Owner, Admin/Staff, Developer)
- Real-time updates via Firestore
- Hybrid single/multi-location support with automatic UI simplification

## Onboarding placement (Decision 7)

- **Target home**: HQ Owner dashboard (`OwnerHQDashboardScreen`)
- **Current code**: onboarding screens still under `web-app/lib/admin/dashboard/onboarding/` and primarily reached from Admin
- **Plan**: conditional Onboarding progress tile on HQ Owner → existing screens → demote Admin entry
- See `docs/DECISIONS.md` Decision 7 and `docs/DASHBOARDS.md`

## Config Delegation
Web-app uses thin delegation layers (`branding_config.dart`, `design_tokens.dart`) that forward to `shared_core`. Do not add new config logic here.

## Development

```bash
cd web-app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run -d chrome
```

## Architecture Notes

- All business logic and models come from `shared_core`
- Design & Branding allows franchise owners to manage look & feel with live preview (franchise-scoped)
- Role-based access, dashboard switching, and FeatureGate supported
- Agent work must follow `AGENT_SYSTEM.md` rules with human review on architecture, config, and design changes
- Onboarding belongs on HQ Owner long-term (not Admin)

## Related Documentation

- `ARCHITECTURE.md`
- `docs/DASHBOARDS.md`
- `docs/DECISIONS.md`
- `ROADMAP.md`
- `STATUS.md`
- `AGENT_SYSTEM.md` (multi-agent governance)

**Last Updated**: July 24, 2026
