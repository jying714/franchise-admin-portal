# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 6, 2026 (~20:40 CDT)  
**Active branch**: **`main`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*` + app READMEs** over agent memory.

---

## 1. Where we are

**main** includes:

- Full order path (customer_web, mobile, POS software pilot)
- Storefront shell Wave 1 + **Modern template** + **Modern polish** (side-sheet cart, branded cards/cart, story band, HQ template + story photo upload)
- Inventory v1 + Staff/labor v1 + station claims + POS clock gates

| Plan | State |
|------|--------|
| `docs/plans/mvp-ops-inventory-v1.md` | **COMPLETE** |
| `docs/plans/mvp-ops-staff-labor-v1.md` | **COMPLETE** |
| `docs/plans/customer-web-storefront-shell-v1.md` | **COMPLETE** |
| `docs/plans/customer-web-template-modern-v1.md` | **COMPLETE** (+ polish) |
| `docs/plans/home-page-composition-engine-v1.md` | Deferred |

**Operator next:** Manager burn-in → soft parallel → hard Owner.com off on sign-off.

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Template resolver | `customer_web/lib/features/storefront/storefront_landing.dart` |
| Modern landing | `customer_web/.../templates/modern/modern_storefront_home.dart` |
| Shell + cart sheet | `customer_web/lib/widgets/storefront_shell.dart` |
| Cart (branded sheet) | `customer_web/lib/features/cart/cart_screen.dart` |
| HQ Website | `web-app/.../website_settings_panel.dart` |
| POS unlock / clock | `pos_app/lib/features/session/pin_unlock_screen.dart` |
| Labor service | `packages/shared_core/.../labor_firestore_service.dart` |
| Inventory sellability | `MenuItem.isSellable` · InventoryLedger |

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
```

---

## 3. Locks

- Hard Owner.com cutover ≠ soft parallel  
- Inventory: opt-in qty; zero blocks sell-through  
- Unlock requires open punch; off-shift needs manager PIN  
- `isPosStation` = `stationFranchise` claim only  
- Modern optional via `templateId`; default layout unchanged  
- Public cart UX = shell side sheet (not dual in-page stacks)  
- Growth after soft stability  

---

## 4. READMEs

| Path | Covers |
|------|--------|
| `README.md` | Monorepo overview |
| `customer_web/README.md` | Storefront templates, shell, run |
| `pos_app/README.md` | Station POS, claims, clock, run defines |
| `packages/shared_core/README.md` | Shared domain |
| `web-app/README.md` | Admin / HQ portal |
| `mobile_app/README.md` | Customer mobile |

---

**Bottom line:** Ops gates + Modern storefront (incl. polish) on main. Next = burn-in / soft parallel.
