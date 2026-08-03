# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 3, 2026 (~00:45 CDT — MVP-Ops cutover gates)  
**Active branch**: **`main`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*`** over agent memory.

---

## 1. Where we are

**main:** Order path + customize parity + HQ settings + POS software pilot.

**Operator (Doughboys):** Soft parallel POS vs Owner.com is OK; **hard swap** needs **inventory v1** + **staff/labor v1** (schedule, print, **clock in/out**, **hours summary**).

| Plan | Role |
|------|------|
| `docs/plans/mvp-ops-inventory-v1.md` | Qty when enabled; 0 = 86 all channels |
| `docs/plans/mvp-ops-staff-labor-v1.md` | Greenfield labor; clock + hours mandatory |
| `docs/plans/customer-web-storefront-shell-v1.md` | Guest shell (parallel track) |
| `docs/plans/home-page-composition-engine-v1.md` | Deferred HQ home studio |

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Storefront home / shell today | `customer_web/lib/features/home/` · `widgets/branding_shell.dart` |
| Customize / cart / checkout | `customer_web/lib/features/menu|cart|checkout/` |
| POS | `pos_app/` |
| HQ settings | `web-app/lib/admin/hq_owner/` |

```powershell
cd C:\projects\franchise-admin-portal
git pull origin main
```

---

## 3. Locks

- Hard Owner.com cutover ≠ soft parallel  
- Inventory: opt-in qty only; zero blocks sell-through  
- Labor: schedule + print + clock + hours summary in v1; not full payroll  
- Storefront Wave 2 studio deferred  
- Growth (loyalty, push, upsells) after ops soft stability  

---

## 4. Next coding focus

Parallel OK: **Wave 1 shell** (guest) and/or **Inventory INV.*** (ops). Labor after inventory baseline unless manager prioritizes schedule first.

---

**Bottom line:** Guest parity is on main. Cutover gated on **inventory + staff/labor** plans. Shell is next guest UX; hardware still incoming.
