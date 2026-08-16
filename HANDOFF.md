# HANDOFF.md

**As of:** Saturday, August 15, 2026  
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

## Next code (this branch)

1. **A4** — Remove standing schema panel; **N fixes needed** + sheet (HQ menu item editor, then Admin).  
2. **B1–B2** — Detect + merge duplicate types with dry-run.  
3. **B3 / C** — Orphans, ref repair, onboarding step + HQ card.  
4. **D** — POS `KitchenPrinter` / drawer interfaces + mock ticket preview.  

**Hardware:** printer + cash drawer inbound — keep software ports ready.  
**iOS:** delayed; simulator bring-up when started (no hardware dependency).

---

## Operating rules

- Human is merge gate; agents proposal-only  
- Prefer real paths; no invented schema fields  
- Quote source for surgical edits  

**Bottom line:** Salad path is on main. Pre-hardware focus is **Catalog health self-serve** + **POS print/drawer interfaces**. Schema UI becomes Catalog health per Decision 15.
