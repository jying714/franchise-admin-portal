# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 11, 2026 (~11:10 CDT)  
**Active branch**: **`main`** (soft-release)  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*` + `docs/slices/*` + app READMEs** over agent memory.

---

## 1. Where we are

**Product:** Soft-release on main. Burn-in checklist **GREEN** 2026-08-10. Soft parallel OK. Hard Owner.com cutover waits on sign-off + hardware.

**Containment extract (plan baseline ~2026-08-08 → 2026-08-11):**

| Phase | State |
|-------|--------|
| A1 MenuRepository | **DONE** |
| A2 ConfigRepository | **DONE** |
| A3 OrderRepository + façade | **DONE** |
| A4 Inventory + Labor repos + call sites | **DONE** |
| B1–B2 MenuPricing + CustomizationController | **Mostly DONE** |
| B3–B4 Thin modal composition root | **Partial** — file still large |
| C BrandingFacade | **Open** |
| D Convergence / local user.dart | **Open** |
| A5 Other god-service contexts | **Optional / open** |

Full progress write-up: `docs/architecture/containment-progress-2026-08-11.md`

**Operator next:** Soft parallel. Optional next extract branch: `feat/customization-modal-composition-root` (finish Phase B). Hardware when devices arrive.

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
```

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Menu / Config / Order / Inventory / Labor repos | `packages/shared_core/lib/src/core/repositories/` |
| MenuPricing | `packages/shared_core/.../domain/menu_pricing.dart` |
| CustomizationController | `mobile_app/lib/widgets/customization/customization_controller.dart` |
| Customization modal (still large) | `mobile_app/lib/widgets/customization/customization_modal.dart` |
| Inventory ledger (impl) | `packages/shared_core/.../services/inventory_ledger.dart` |
| Labor service (impl) | `packages/shared_core/.../services/labor_firestore_service.dart` |

---

## 3. Locks

- Human is merge gate; no invented schema
- Extract = rewire only; zero intentional behavior change
- Soft parallel ≠ hard Owner.com cutover
- A5 / dual-tree removal / Phase E not required for hardware cutover

---

**Bottom line:** A1–A4 + customization controller/pricing done. Remaining large extract wins: thin modal, optional Order call sites, BrandingFacade. Ops: soft parallel until hardware + sign-off.
