# Franchise Admin Portal — Multi-tenant restaurant SaaS

Flutter **monorepo** for franchise-scoped ordering and ops: HQ/Admin web, customer web + mobile, and station POS.

| Surface | Path | URL / notes |
|---------|------|-------------|
| **Admin / HQ** | `web-app/` | franchisehq.io |
| **Customer storefront** | `customer_web/` | https://franchise-storefront.web.app · `/f/{franchiseId}` |
| **Customer mobile** | `mobile_app/` | Android / iOS |
| **Station POS** | `pos_app/` | Android pilot; station claims |
| **Shared domain** | `packages/shared_core/` | Models, Firestore services, branding |
| **Orchestrator** | `orchestrator/` | Local multi-agent (proposal-only) |

**Backend:** Firebase (Auth, Firestore, Functions, Hosting, Storage)  
**Repo:** https://github.com/jying714/franchise-admin-portal  
**Primary branch:** `main`

---

## Current status (August 6, 2026)

Prefer **`STATUS.md`** and **`HANDOFF.md`** for the live checklist.

**On main (high level):**

- Franchise-scoped config & live branding  
- HQ onboarding, Design & Branding, menu modifier system  
- Stripe Connect checkout (web/mobile)  
- **customer_web** shell + **Modern** template (optional `templateId`) + cart side sheet  
- **Inventory v1** + **Staff/labor v1** (Admin schedule/hours; POS clock + PIN)  
- Station `stationFranchise` claims hardening  
- Soft release / **manager burn-in** before hard Owner.com cutover  

**Deferred:** Home composition Wave 2, growth (promos/push/loyalty), POS hardware in transit.

---

## Project structure

```text
franchise-admin-portal/
├── packages/shared_core/     # Single source of domain models & services
├── web-app/                  # HQ Owner + Admin (Flutter web)
├── customer_web/             # Public storefront (Flutter web)
├── mobile_app/               # Customer app
├── pos_app/                  # Counter station POS
├── orchestrator/             # Local agent CLI (proposal-only)
├── docs/                     # Architecture, plans, slices
├── STATUS.md                 # Live “what’s done”
├── HANDOFF.md                # Session handoff
└── ROADMAP.md
```

---

## App READMEs

| Package | Doc |
|---------|-----|
| Storefront | [`customer_web/README.md`](customer_web/README.md) |
| POS | [`pos_app/README.md`](pos_app/README.md) |
| Admin/HQ | [`web-app/README.md`](web-app/README.md) |
| Mobile | [`mobile_app/README.md`](mobile_app/README.md) |
| Shared core | [`packages/shared_core/README.md`](packages/shared_core/README.md) |
| Agents | [`orchestrator/README.md`](orchestrator/README.md) |

---

## Architecture docs

- `docs/architecture/firestore-per-franchise-config.md` — per-franchise config  
- `docs/DASHBOARDS.md` · `docs/MOBILE_DYNAMIC.md` · `docs/DECISIONS.md`  
- `docs/plans/*` — inventory, labor, storefront shell, Modern template  
- `AGENT_SYSTEM.md` · `orchestrator/SCOPE_CARD.md` — agent safety  

---

## Quick start

```powershell
git clone https://github.com/jying714/franchise-admin-portal.git
cd franchise-admin-portal
git checkout main
git pull origin main

# Admin
cd web-app && flutter pub get && flutter run -d chrome

# Storefront
cd ..\customer_web && flutter pub get
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
# open /f/{franchiseId}

# POS (Android preferred)
cd ..\pos_app && flutter pub get
flutter run -d <device> `
  --dart-define=STATION_FRANCHISE_ID=... `
  --dart-define=STATION_AUTH_EMAIL=... `
  --dart-define=STATION_AUTH_PASSWORD=...
```

---

## Development approach

- Franchise-scoped data; `shared_core` is the domain source of truth  
- Local multi-agent orchestrator is **proposal-only** (human merge gate)  
- Small iterative changes; STATUS/HANDOFF updated after significant sessions  

**Last updated:** August 6, 2026
