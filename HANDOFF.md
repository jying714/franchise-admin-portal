# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 27, 2026 (Admin smoke + menu rebuild direction)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `main`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\projects\franchise-admin-portal`  
**Firebase project**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main`)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 27, 2026)

### Git / deploy

- `feat/onboarding-4step` merged into `main` (fast-forward).
- CI: `intl` pinned to **0.19.0** (Flutter 3.29.2 / flutter_localizations); Hosting deploy succeeded.

### Admin dashboard smoke (exhaustive)

Full section_registry walk completed. **Shell/chrome mostly PASS.** Broken product paths documented in STATUS and `docs/slices/admin-dashboard-ops-fixes-v1.md`.

Notable: Staff + Support Chat registry entries are **placeholders**; real `StaffAccessScreen` / `ChatManagementScreen` exist but are **not** wired.

### Menu customization — rebuild decision (locked)

Human rejected patch-only MVP fixes for modifiers. **Full rebuild** of the menu modifier system so Doughboys pizza UX and non-pizza restaurants share one model.

Authority:

- `docs/slices/menu-modifier-system-rebuild-v1.md`
- `docs/DECISIONS.md` Decision **10**
- Surface split: Decision **9**

**Do not** “lightly fix” Admin Customize spinner while leaving dual `customizations[]` vs `customizationGroups` + mobile `category.contains('pizza')`.

---

## 2. Prior closures (still true)

| Slice / area | Status |
|--------------|--------|
| HQ onboarding sole host | Done |
| Foundation residual (orphans / Unassigned) | Done |
| Platform Owner MVP | Done |
| HQ polish / financial honesty / platform billing | Done |
| Ingredient sortOrder + group edit | Done (pre-merge) |

---

## 3. What’s next (prioritized)

1. **Menu modifier system rebuild** (M1–M5) — schema, migration, unified editors, mobile renderer, cutover  
2. **Admin ops fixes** — categories/promos/orders/franchise refresh/KPI wire/remove CSV noise (**not** modifier architecture)  
3. Developer dashboard inventory  
4. CF Node 22 before decommission window  

**Not next:** Cash Flow / Multi-brand HQ cards.

---

## 4. Architecture reminders

- `shared_core` SSoT; franchise-scoped Firestore  
- Onboarding = `HqOnboardingShellScreen` only  
- Admin Menu = **day-2 ops**; HQ Menu Items = **guided setup** — same underlying menu model after rebuild  
- Prefer ingredient-linked modifiers; free-text ad-hoc allowed as escape hatch  
- Item-level inventory: `inventoryTracked` + `stockCount` (SKU link later)  
- Do not invent DesignTokens/BrandingConfig fields or `FranchiseProvider()` zero-arg  

---

**Bottom line:** Main is live. Next epic is **menu modifier rebuild**; Admin P0 ops fixes are parallel/narrow. Pull `main` before starting either slice branch.
