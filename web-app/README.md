# Doughboys Pizzeria Web Admin Portal

Flutter Web admin dashboard for franchise owners, HQ users, platform admins, and developers.

## Current Status (July 25, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**  
**Phase 1**: Live branding; HQ Design & Branding **v1.1**; onboarding **HQ-only host**

### Major Achievements
- Auth handoff + role dashboards stabilized
- Franchise-aware providers unified (`FranchiseProvider`, `AdminUserProvider`)
- Web live branding: `FranchiseProvider` → `DesignTokens.setFranchiseProvider` → live colors
- **HQ Design & Branding v1.1**: card CTA → screen; Save writes franchise branding + `config/ui_config`
- **Onboarding (Decision 7)**: full migration under HQ Owner
  - Host: `web-app/lib/admin/hq_owner/onboarding/` + `HqOnboardingShellScreen`
  - Admin onboarding tree removed; Admin sidebar is ops-only
  - Deep link: `/hq/onboarding?section=…`
  - Progress: `franchises/{id}/onboarding_progress/progress`; HQ card watches `OnboardingProgressProviderImpl`
  - Feature Setup → progress card verified; steps 2–4 writers still being hardened

## Features
- Dynamic white-label branding per franchise (HQ Design & Branding)
- Menu / category / ingredient management via **HQ onboarding shell**
- Orders, analytics, staff, financial tools (Admin ops)
- Subscription & billing; franchise picker; role switcher
- Hybrid single/multi-location support

## Onboarding placement (Decision 7 — implemented)

- **Home**: HQ Owner → Onboarding Progress card → **Continue** → `HqOnboardingShellScreen`
- **Code**: `web-app/lib/admin/hq_owner/onboarding/**` (Admin onboarding tree deleted)
- **Registry**: `section_registry.dart` has no onboarding sections
- **Progress keys**: `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`
- Foundation tab marks update **detail %** only; product step 2 via foundation continue
- See `docs/DECISIONS.md` Decision 7 and `STATUS.md`

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

- Business logic and models from `shared_core`
- Role-based access, dashboard switching, FeatureGate
- Agent work: `AGENT_SYSTEM.md` + `orchestrator/SCOPE_CARD.md`; human merge gate
- Do not reintroduce Admin onboarding host or top-level `onboarding_progress/{id}`

## Related Documentation

- `ARCHITECTURE.md`
- `docs/DASHBOARDS.md`
- `docs/DECISIONS.md`
- `docs/slices/hq-design-branding-v1.md`
- `ROADMAP.md`
- `STATUS.md`
- `AGENT_SYSTEM.md`

**Last Updated**: July 25, 2026
