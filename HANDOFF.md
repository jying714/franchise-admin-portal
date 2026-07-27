# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 26, 2026 (late evening — Platform Owner dashboard MVP)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\projects\franchise-admin-portal`

Prefer **STATUS.md + this handoff + slice docs under `docs/slices/`** over agent memory.

---

## 1. Session outcomes (Platform Owner arc, July 26 evening)

### Closed product work

| Item | Status | Notes |
|------|--------|--------|
| Platform Owner routes | Done | Explicit plans/subscriptions routes before platform catch-all |
| Invite Franchisees (list + submit) | Done | Admin Firestore overrides; rules; dialog Provider.value; CF nodejs20 |
| Franchise Subscriptions summary card | Done | Admin `getFranchiseSubscriptions` |
| Platform revenue overview | Done | Real Admin aggregation; single consolidated card UI |
| Platform Owner layout | Done | HQ-like grid; revenue 2-wide; plans card removed from dashboard |

Authority: `docs/slices/platform-owner-dashboard-v1.md`

### Ops / infra (same session)

- Firebase Functions runtime: **nodejs18 → nodejs20** (all callables including `inviteAndSetRole`)
- `functions/package.json` `main`: `lib/src/index.js` (matches `tsc` output layout)
- Root `.firebaserc` / `firebase use doughboyspizzeria-2b3d2` for deploys from monorepo root

---

## 2. Prior HQ closures (same day, earlier)

| Slice | Status |
|-------|--------|
| `hq-onboarding-hq-polish-v1` | COMPLETE |
| `hq-financial-honesty-v1` | COMPLETE |
| `hq-platform-billing-v1` | COMPLETE |
| AlertsCard UI honesty | Card-only (no producers) |

---

## 3. What’s left (prioritized)

1. **Admin dashboard** — cleanup, inventory of real vs stub cards  
2. **Developer dashboard** — same  
3. **HQ Owner residual wiring** — small remaining product wiring only  
4. **Mobile app** — many tests expected; originally pizzeria-shaped; restaurant-type-agnostic layouts/config acceptance is a **later discussion**, not this session  
5. Optional: franchise-scoped `platform_invoices` in Platform revenue if top-level stays empty in prod data  
6. Before ~2026-10-30: Cloud Functions **Node 22** migration  

**Explicitly not next:** Cash Flow Forecast, Multi-Brand Overview (post-MVP).

---

## 4. Architecture reminders (do not regress)

- `shared_core` single source of domain models  
- Franchise-scoped Firestore under `franchises/{id}/...`  
- Onboarding host = **HQ only** (`HqOnboardingShellScreen`)  
- Platform Owner / HQ financial heavy reads = **AdminFirestoreService**  
- Web live branding: `FranchiseProvider` → `DesignTokens.setFranchiseProvider`  
- Invite CF role gate still: `platform_owner | owner | developer | admin` (not `hq_owner`) — callers must hold one of those claims  
- Local invitation `ChangeNotifierProvider` must be **re-provided** into `showDialog` (root navigator does not see panel subtree)

---

## 5. Agent instructions

- Read `STATUS.md` first, then this file, `AGENT_SYSTEM.md`, `orchestrator/SCOPE_CARD.md`  
- Do not invent BrandingConfig / DesignTokens fields or `FranchiseProvider()` zero-arg  
- Do not reintroduce Admin onboarding or top-level `onboarding_progress/{id}`  
- Prefer smallest safe next step; human is merge gate

---

**Bottom line:** HQ Owner financial + Platform Owner dashboard MVP are usable. Next conversations should start on **Admin dashboard** and/or **Developer dashboard**, then HQ residuals — not re-opening deferred HQ shells or mobile multi-type redesign until human expands scope.
