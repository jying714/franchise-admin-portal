# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 4, 2026 (~23:30 CDT — inventory + labor COMPLETE)  
**Active branch**: **`main`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*`** over agent memory.

---

## 1. Where we are

**main:** Order path + storefront shell Wave 1 + inventory v1 + staff/labor v1 + POS software pilot.

**Operator (Doughboys):** Soft parallel POS vs Owner.com is the **next** operational step. **Hard swap** gates (inventory + labor) are **implemented** — remaining work is burn-in, claims hardening, and hardware.

| Plan | Role | State |
|------|------|--------|
| `docs/plans/mvp-ops-inventory-v1.md` | Qty when enabled; 0 = 86 all channels | **COMPLETE** |
| `docs/plans/mvp-ops-staff-labor-v1.md` | Schedule, print, clock, hours | **COMPLETE** |
| `docs/plans/customer-web-storefront-shell-v1.md` | Guest shell | **COMPLETE** |
| `docs/plans/home-page-composition-engine-v1.md` | HQ home studio | Deferred |

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Storefront shell / home | `customer_web/lib/widgets/storefront_shell.dart` · `features/home/storefront_home_screen.dart` |
| Customize / cart / checkout | `customer_web/lib/features/menu|cart|checkout/` |
| Inventory ledger | `packages/shared_core/.../inventory_ledger.dart` · `MenuItem.isSellable` |
| Labor models/service | `shift.dart` · `time_entry.dart` · `labor_firestore_service.dart` · `pin_hash.dart` |
| Admin staff | `web-app/lib/admin/staff/` (roster, schedule, hours) |
| POS clock | `pos_app/lib/features/session/pin_unlock_screen.dart` |
| POS | `pos_app/` |
| HQ settings | `web-app/lib/admin/hq_owner/` |

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
```

---

## 3. Locks

- Hard Owner.com cutover ≠ soft parallel  
- Inventory: opt-in qty only; zero blocks sell-through (`isSellable`)  
- Labor: Admin schedule + POS clock + hours/timesheet print shipped  
- Station Auth: prefer `stationFranchise` claim; email smoke gate is temporary  
- Storefront Wave 2 studio deferred  
- Growth (loyalty, push, upsells) after soft stability  

---

## 4. Next coding / ops focus

1. **Push/deploy** production rules + web hosting if not already.  
2. **Station claims** — set `stationFranchise` on station user; drop email clause from `isPosStation`.  
3. **Manager burn-in** — 86 item, clock week, print schedule/timesheet, full guest order.  
4. **Hardware** when devices arrive.  
5. **Growth** only after soft stability.

---

**Bottom line:** Guest shell + inventory + labor are on **main**. MVP path = soft parallel burn-in → hard Owner.com off when manager signs off.
