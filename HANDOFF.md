# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 12, 2026  
**Active branch**: **`feat/customization-modal-composition-root`** (B3 done; B4 partial; merge pending smoke) · soft-release remains **`main`**  
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
| B1–B2 MenuPricing + CustomizationController | **DONE** |
| B3 Dual-write removal | **DONE** on composition-root branch |
| B4 Thin modal | **Partial** — init dual maps / PizzaSauceSelection / sauceSplit / SauceSelectorGroup maps removed; portions/radio/wings still local; file still large; **smoke before merge** |
| C BrandingFacade | **Open** |
| D Convergence / local user.dart | **Open** |
| A5 Other god-service contexts | **Optional / open** |

Full progress write-up: `docs/architecture/containment-progress-2026-08-11.md`


**After**
```markdown
**Operator next:** Soft parallel. On composition-root branch: **device smoke** (pizza/calzone/salad/dinner) → merge to `main` when green. Optional further B4 (portions/radio/wings) after smoke. Hardware when devices arrive.

```powershell
cd C:\projects\franchise-admin-portal
git checkout feat/customization-modal-composition-root
git pull origin feat/customization-modal-composition-root
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

**Bottom line:** A1–A4 + B1–B3 done on composition-root branch; B4 partial. Next: smoke → merge. Remaining extract wins after that: optional portions/radio/wings, Order call sites, BrandingFacade. Ops: soft parallel until hardware + sign-off.