# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 5, 2026 (~22:50 CDT)  
**Active branch**: **`main`** (Modern template may live on `feat/customer-web-template-modern-v1` until merge)  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*`** over agent memory.

---

## 1. Where we are

**main:** Order path + storefront shell Wave 1 + inventory v1 + staff/labor v1 + station claims + POS clock gates.

**Modern template:** Full landing (hero, Featured strip, category menu parity, cart/checkout, footer) + HQ `templateId` picker. Resolver: `StorefrontLanding` → default vs `ModernStorefrontHome`.

**Operator:** Soft parallel / burn-in is the next operational step. Cutover gates implemented.

| Plan | State |
|------|--------|
| `docs/plans/mvp-ops-inventory-v1.md` | **COMPLETE** |
| `docs/plans/mvp-ops-staff-labor-v1.md` | **COMPLETE** |
| `docs/plans/customer-web-storefront-shell-v1.md` | **COMPLETE** |
| `docs/plans/customer-web-template-modern-v1.md` | **COMPLETE** |
| `docs/plans/home-page-composition-engine-v1.md` | Deferred |

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Template resolver | `customer_web/lib/features/storefront/storefront_landing.dart` |
| Modern landing | `customer_web/lib/features/storefront/templates/modern/modern_storefront_home.dart` |
| Default home / shell | `features/home/storefront_home_screen.dart` · `widgets/storefront_shell.dart` |
| HQ Website / templateId | `web-app/lib/admin/hq_owner/screens/website_settings_panel.dart` |
| Inventory | `MenuItem.isSellable` · InventoryLedger |
| Labor | `labor_firestore_service.dart` · Admin `staff/` · POS `pin_unlock_screen.dart` |
| PinHash | `packages/shared_core/.../pin_hash.dart` |

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
```

---

## 3. Locks

- Hard Owner.com cutover ≠ soft parallel  
- Inventory: opt-in qty; zero blocks sell-through  
- Labor: Admin schedule + POS clock + hours/timesheet  
- Unlock requires open punch; off-shift clock-in needs manager PIN  
- `isPosStation` uses `stationFranchise` claim only  
- Modern is optional via `templateId`; default layout unchanged  
- Growth after soft stability  

---

## 4. Next focus

1. Merge Modern feature branch if still open.  
2. Manager burn-in checklist.  
3. Soft parallel → hard cutover on sign-off.  
4. No Wave 2 / loyalty until soft is stable.

---

**Bottom line:** Ops gates + Modern template shipped. MVP path = burn-in → soft parallel → hard Owner.com off.
