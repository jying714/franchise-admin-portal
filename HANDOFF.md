# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 26, 2026 (night — HQ foundation residual + Platform Owner MVP)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\projects\franchise-admin-portal`

Prefer **STATUS.md + this handoff + slice docs under `docs/slices/`** over agent memory.

---

## 1. Latest session (HQ onboarding foundation residual)

Authority: `docs/slices/hq-onboarding-foundation-residual-v1.md`  
Code commit (example): `HQ onboarding: orphan gate, Unassigned grouping, ingredient dialog save/pop fixes`

### Product decisions (locked)

| Decision | Choice |
|----------|--------|
| Menu Items when orphans exist | **Hard block** |
| Orphan definition | Any ingredient with empty **or** unknown `typeId` (not in live franchise types) |
| Fix UX | Filter + first highlight (not multi-row yellow for 100+) |
| Unassigned section | Top of list; label **Unassigned**; tooltip shows discrepancy samples |
| Grouping | Only by **matched franchise type**; case-sensitive canonical type **name**; do not invent groups from stale type strings |

### Implemented

- Menu Items readiness: orphan = unknown typeId; CTA sets `FoundationFocusRequest` then `switchToSection('onboarding_menu_foundation')`
- Foundation: on handoff, Ingredients tab (index 1)
- Ingredients: orphan FilterChip; ordered Unassigned-first groups; unique keys; row error border for orphans
- Shell providers: CNP + Proxy for type/metadata Impl (Menu Items counts update without full leave/re-enter)
- Form: `saveChanges()` not `saveAllChanges()` under dialog; pop via `dialogContext` / nearest navigator; one-time type seed

### Still soft / watch

- Ingredient form may still leave a barrier on some hosts after save (debug: `[Ingredients] onSaved pop canPop=…`). Prefer nearest navigator; avoid `load()` while dialog open.
- Doughboys franchise still has large historical orphan set until user assigns types in Unassigned section.

---

## 2. Platform Owner MVP (same day, earlier)

Authority: `docs/slices/platform-owner-dashboard-v1.md`

| Item | Status |
|------|--------|
| Routes plans/subscriptions | Done |
| Invite list + submit | Done (Admin FS, rules, dialog Provider, CF nodejs20) |
| Subscriptions card | Done |
| Revenue overview | Done (top-level aggregation; single card UI) |
| Layout | HQ-like grid; revenue 2-wide; plans card removed |

Ops: Functions **nodejs20**; `functions` `main`: `lib/src/index.js`; project `doughboyspizzeria-2b3d2`.

---

## 3. Prior HQ closures (same day)

| Slice | Status |
|-------|--------|
| `hq-onboarding-hq-polish-v1` | COMPLETE |
| `hq-financial-honesty-v1` | COMPLETE |
| `hq-platform-billing-v1` | COMPLETE |
| AlertsCard UI honesty | Card-only |

Onboarding host = HQ only; 5 product keys including `onboarding_design_branding`.

---

## 4. What’s left (prioritized)

1. **Admin dashboard** — inventory / real vs stub  
2. **Developer dashboard** — same  
3. **HQ residual** — form dismiss if still flaky; data cleanup orphans; optional bulk type map later  
4. **Mobile** — multi-type QA discussion later  
5. **CF Node 22** before ~2026-10-30  
6. Optional Platform revenue franchise-scoped invoice rollup  

**Not next:** Cash Flow / Multi-brand (post-MVP).

---

## 5. Architecture reminders

- `shared_core` SSoT; franchise-scoped Firestore  
- Onboarding = `HqOnboardingShellScreen` only  
- AdminFirestoreService for heavy admin/platform reads  
- Dialogs that need local CNPs must re-provide into `showDialog`  
- Do not invent DesignTokens/BrandingConfig fields or `FranchiseProvider()` zero-arg  
- Progress path: `franchises/{id}/onboarding_progress/progress` (load+write, not stream)

---

**Bottom line:** Platform Owner MVP + HQ foundation orphan path are in. Next product focus remains **Admin** then **Developer** dashboards unless human prioritizes form/data cleanup.
