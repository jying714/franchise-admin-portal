# HANDOFF.md

**As of:** Monday, August 17, 2026  
**Active branch:** `feat/pre-hardware-hq-polish`  
**Soft-release:** `main` (includes salad profile + HQ editor polish)

---

## How to start the next chat

| Priority | Path |
|----------|------|
| 1 | `STATUS.md` |
| 2 | `HANDOFF.md` |
| 3 | `docs/DECISIONS.md` (Decision **15** Catalog Health) |
| 4 | `docs/slices/catalog-health-v1.md` |
| 5 | `docs/slices/pos-app-v1.md` (print/drawer when hardware) |

**Repo:** https://github.com/jying714/franchise-admin-portal  
**Local:** `C:\projects\franchise-admin-portal`  
**Firebase:** `doughboyspizzeria-2b3d2`

```powershell
cd C:\projects\franchise-admin-portal
git fetch origin
git checkout feat/pre-hardware-hq-polish
git pull origin feat/pre-hardware-hq-polish
```

---

## Just shipped on main (2026-08-15)

- `MenuProfile.salad`; dressings `sourceTypeId` + `config/menu_profile_salad`
- `freeDressingCount` / `extraDressingUpcharge` persist + mobile prefers item free count
- Optional add-on **price overrides** only (no default-by-size); size topping $ = house extra
- Pricing: salad/sub/dinner non-included extras use `resolveExtra` (override wins)
- HQ editor: template dropdown hidden; section reorder; type-first `MultiIngredientSelector`
- Android night theme Material/AppCompat (Stripe)

**Known residual:** optional chip **label** may still show size topping $ while footer uses override — fix on polish branch if desired.

---

## Locked product direction (Decision 15)

Owners never need the word **schema**. **Catalog health** + **Fixes needed**.

- Standing schema card **out** of menu item sheet → attention control + sheet  
- Onboarding Catalog health step + post HQ/Admin card  
- Errors block publish; warnings don’t  
- Duplicate types (e.g. sauces/Sauces): pick survivor, union ingredients, hard-delete loser  
- Case-insensitive type uniqueness on create and rename  
- Franchise duplicates block menu publish  
- Normalize v1: types + orphans + menu refs  
- ≤ 5 taps to clear duplicate sauces  

Authority: `docs/slices/catalog-health-v1.md`

---

## On this branch (2026-08-16 → 17)

- Catalog health: type merge, ingredient type-label normalize, category duplicate banner + name uniqueness  
- Menu item editor: full-width; **Fixes needed** sheet with map/create (category/ingredient); schema sidebar **removed**  
- Mark Complete: always labeled Mark Complete; disabled when item errors remain  
- POS: `DrawerService` mock used on cash pay + refund paths; `PrintService` mock unchanged  

## Next code

1. Optional: Catalog health **hub** (onboarding step / HQ card) — Decision 15 surface C  
2. Optional: override $ on mobile optional **chip labels**  
3. Merge → `main` when you sign off smoke  
4. Hardware week: real print + drawer behind existing services  

**Hardware:** printer + cash drawer inbound.  
**iOS:** delayed.

---

## Operating rules

- Human is merge gate; agents proposal-only  
- Prefer real paths; no invented schema fields  
- Quote source for surgical edits  

**Bottom line:** Salad on main. Branch has Catalog health foundation + Fixes sheet + DrawerService mock. Optional hub C, then merge; hardware swaps mocks.
