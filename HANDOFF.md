# HANDOFF.md — Agent Context & Project Status

**Last Updated**: October 1, 2026  
**Active product branch**: **`feat/pre-hardware-hq-polish`**  
**Soft-release**: **`main`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/slices/ordering-customization-normalize-v1.md`** over agent memory.

---

## Resume here

Ordering customization must be normalized. Mobile modal is the reference. Work is on `feat/pre-hardware-hq-polish`. Do not start WeekTally, iOS, printer-by-category, loyalty, custom domains, or home composition Wave 2.

`feat/customization-modal-composition-root` is not a current branch. Containment notes below are historical.

---

## 1. Where we were (August 12 containment)

**Product:** Soft-release on main. Burn-in checklist **GREEN** 2026-08-10. Soft parallel OK. Hard Owner.com cutover waits on sign-off + hardware + ordering parity.

| Phase | State |
|-------|--------|
| A1 MenuRepository | **DONE** |
| A2 ConfigRepository | **DONE** |
| A3 OrderRepository + façade | **DONE** |
| A4 Inventory + Labor repos + call sites | **DONE** |
| B1–B2 MenuPricing + CustomizationController | **DONE** |
| B3 Dual-write removal | **DONE** on composition-root branch |
| B4 Thin modal | **Partial** |
| C BrandingFacade | **Open** |
| D Convergence / local user.dart | **Open** |
| A5 Other god-service contexts | **Optional / open** |

Full progress write-up: `docs/architecture/containment-progress-2026-08-11.md`

```powershell
cd C:\projects\franchise-admin-portal
git checkout feat/pre-hardware-hq-polish
git pull origin feat/pre-hardware-hq-polish
```

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Menu / Config / Order / Inventory / Labor repos | `packages/shared_core/lib/src/core/repositories/` |
| MenuPricing | `packages/shared_core/.../domain/menu_pricing.dart` |
| CustomizationController | `mobile_app/lib/widgets/customization/customization_controller.dart` |
| Customization modal (reference) | `mobile_app/lib/widgets/customization/customization_modal.dart` |
| POS builder | `pos_app/lib/features/customization/pos_customization_sheet.dart` |
| customer_web builder | `customer_web/lib/features/menu/menu_item_detail_screen.dart` |

---

## 3. Locks

- Human is merge gate; no invented schema
- Ordering customization normalize is required before hard cutover
- Soft parallel ≠ hard Owner.com cutover
- WeekTally, iOS, printer-by-category, loyalty, custom domains, Wave 2 studio are not MVP

---

**Bottom line:** Next is ordering customization normalize on polish, then merge to `main`.
