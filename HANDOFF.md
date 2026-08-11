# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 11, 2026 (~10:35 CDT)  
**Active branch**: **`main`** (ops); extract A3: **`feat/bounded-context-repos-a3-orders`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*` + `docs/slices/*` + app READMEs** over agent memory.

---

## 1. Where we are

**main:** soft-release order path, Modern storefront, inventory + staff/labor, promos v1, portal users HQ, POS delivery COD. Burn-in checklist **GREEN** 2026-08-10.

**Extract:**

| Phase | Branch / state |
|-------|----------------|
| A1 MenuRepository | Done |
| A2 ConfigRepository | Done |
| A3 OrderRepository | **DONE** on `feat/bounded-context-repos-a3-orders` — merge to main |
| A4 Inventory + Labor formalize | **NEXT** — `docs/slices/bounded-context-repos-a4-inventory-labor.md` |
| Customization B1–B2.2.3 | Complete on main |

**Operator next:** Soft parallel with Owner.com; merge A3; start A4 on `feat/bounded-context-repos-a4-inventory-labor`. Hardware pilot when devices arrive. Hard Owner.com cutover after sign-off + hardware.

```powershell
cd C:\projects\franchise-admin-portal
git checkout feat/bounded-context-repos-a3-orders
git pull origin feat/bounded-context-repos-a3-orders
```

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| OrderRepository | `packages/shared_core/.../repositories/order_repository.dart` |
| OrderFirestoreRepository | `packages/shared_core/.../repositories/order_firestore_repository.dart` |
| Inventory ledger (A4 wrap) | `packages/shared_core/.../services/inventory_ledger.dart` |
| Labor service (A4 wrap) | `packages/shared_core/.../services/labor_firestore_service.dart` |
| CustomizationController | `mobile_app/lib/widgets/customization/customization_controller.dart` |
| A4 authority | `docs/slices/bounded-context-repos-a4-inventory-labor.md` |

---

## 3. Locks

- Human is merge gate; no invented schema
- A4 formalizes existing services — do not reimplement inventory/labor
- Soft parallel ≠ hard Owner.com cutover
- Zero behavior change on repository extracts

---

**Bottom line:** Burn-in green. Merge A3 OrderRepository, then A4 inventory/labor formalize. Soft parallel until hardware + sign-off for hard cutover.
