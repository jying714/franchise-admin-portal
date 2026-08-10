# Doughboys Pizzeria Web Admin Portal

Flutter Web admin dashboard for franchise owners, HQ users, platform admins, and developers.

## Current Status (August 9, 2026)

**On main with monorepo soft-release software.** Prefer root **`STATUS.md`** / **`HANDOFF.md`** for the live checklist.

### Recent (Aug 2026)

- **Promos / Codes + Banners v1**
  - Codes: template picker, industry types (BOGO, %/$, free item, delivery), live menu chips, daypart, topping min/max/exact
  - Banners: “When customer taps” → promote deal (dropdown), category, item, URL, or image-only
  - Authority: `docs/slices/promo-system-v1.md` · `lib/admin/promo/**`
- **Portal users** moved to **HQ Owner** (Quick Links → polished `StaffAccessScreen`)
  - Create portal_staff invite, pending list, copy link, revoke
  - Accept flow post-login; `users/{uid}` bind + claims sync trigger
  - RoleGuard: `platform_owner` | `hq_owner` | `developer`
  - Email CF `sendPortalStaffInviteEmail` wired; SendGrid **credits** required for delivery
- **Admin sidebar**: **Staff Management** expansion (Station staff, Schedule, Hours)
- **Station staff** roster: role defaults + **editable permissions**; subtitle shows grants
- Admin ops: KPIs, inventory, order analytics (as previously landed)

### Earlier foundations

- Auth handoff + role dashboards  
- Live branding: `FranchiseProvider` → `DesignTokens.setFranchiseProvider`  
- HQ Design & Branding; onboarding **HQ-only host** (Decision 7)  
- Menu modifier system (Decision 10)  

## Features

- Dynamic white-label branding per franchise  
- HQ onboarding shell (menu foundation / items / review)  
- Admin: menu, categories, inventory, orders, analytics, **promotions (Codes + Banners)**  
- **HQ Portal users** vs **Admin station labor** (see DASHBOARDS)  
- Subscription & billing; franchise picker; role switcher  

## People / access (IA)

| Surface | Where |
|---------|--------|
| Portal users (web login invites) | HQ Quick Links |
| Station staff (PIN / permissions) | Admin → Staff Management |
| Schedule / Hours | Admin → Staff Management |

Registry: `lib/core/section_registry.dart` — `staffAccess` `showInSidebar: false`.

## Promotions IA

| Tab | Purpose |
|-----|--------|
| Codes | Deal rules + redemption code (`Promo` + `PromoPricing`) |
| Banners | Menu carousel creative; link to a deal or category |

## Onboarding placement (Decision 7)

- HQ Owner → Onboarding Progress → `HqOnboardingShellScreen`  
- Code: `lib/admin/hq_owner/onboarding/**`  
- Progress: `franchises/{id}/onboarding_progress/progress`  

## Config delegation

Thin layers (`branding_config.dart`, `design_tokens.dart`) forward to `shared_core`. Do not invent new branding models here.

## Development

```bash
cd web-app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter run -d chrome
```

## Related documentation

- Root `STATUS.md` · `HANDOFF.md` · `docs/DASHBOARDS.md` · `docs/DECISIONS.md`  
- `docs/slices/promo-system-v1.md` · `docs/slices/hq-design-branding-v1.md`  
- `AGENT_SYSTEM.md` · `orchestrator/SCOPE_CARD.md`  

**Last Updated**: August 9, 2026
