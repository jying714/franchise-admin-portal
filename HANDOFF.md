# HANDOFF.md

**As of:** Tuesday, August 18, 2026 (TSP100 StarGraphic print + drawer PASS)  
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
| 5 | `docs/slices/pos-app-v1.md` (print/drawer) |

**Repo:** https://github.com/jying714/franchise-admin-portal  
**Local:** `C:\\projects\\franchise-admin-portal`  
**Firebase:** `doughboyspizzeria-2b3d2`

```powershell
cd C:\\projects\\franchise-admin-portal
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

## On this branch (2026-08-16 → 18)

- Catalog health: type merge, ingredient type-label normalize, category uniqueness  
- Menu item editor: full-width; **Fixes needed** sheet; schema sidebar **removed**  
- POS: StarGraphic kitchen/receipt + DK drawer on TSP143 LAN; plugin vendored  

## Next code

1. Merge when Catalog health + POS print signed off  
2. Receipt **layout** polish (formatters now; HQ editor later)  
3. Stripe Terminal when scheduled (reader does not print)  
4. Doughboys: map existing kitchen printers; this TSP100 as counter receipt  
5. Optional: POS station field for host (drop dart-define)  

### Station hardware (2026-08-18)

| Item | Status |
|------|--------|
| Star TSP143 LAN `192.168.1.21` | **Print + drawer live** (StarGraphic) |
| Stripe card reader | On site (payment only) |
| Cash drawer | **Live** on TSP100 DK |
| Extra kitchen printers | At Doughboys; one unit for all MVP dev |

**iOS:** delayed.

---

## Operating rules

- Human is merge gate; agents proposal-only  
- Prefer real paths; no invented schema fields  
- Quote source for surgical edits  

**Bottom line:** Salad on main. Catalog health on branch. **TSP143 StarGraphic print + cash drawer PASS** (one printer for all MVP roles). Receipt copy polish and Doughboys multi-printer mapping later.
