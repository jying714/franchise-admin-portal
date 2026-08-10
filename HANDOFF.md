# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 10, 2026 (~12:35 CDT)  
**Active branch**: **`main`** (ops); extract: **`feat/bounded-context-repos-v1`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*` + `docs/slices/*` + app READMEs** over agent memory.

---

## 1. Where we are

**main** includes:

- Full order path (customer_web, mobile, POS software pilot)
- Storefront shell Wave 1 + **Modern template** + polish
- Inventory v1 + Staff/labor v1 + station claims + POS clock gates
- **Portal users on HQ** (invite accept, pending/revoke, post-login gate)
- **Station staff permission editor** (role defaults + extras; roster subtitle grants)
- **POS delivery**: Accept & deliver → in route → Returned → Close out (cash)
- **Promos v1**: shared pricing engine, Admin Codes/Banners, templates, daypart, mobile+web apply, banner→checkout pending code

| Plan / surface | State |
|----------------|--------|
| `docs/plans/mvp-ops-inventory-v1.md` | **COMPLETE** |
| `docs/plans/mvp-ops-staff-labor-v1.md` | **COMPLETE** |
| `docs/plans/customer-web-storefront-shell-v1.md` | **COMPLETE** |
| `docs/plans/customer-web-template-modern-v1.md` | **COMPLETE** (+ polish) |
| Portal staff invite + HQ host | **COMPLETE** (email needs SendGrid credits) |
| POS delivery close-out product rule | **COMPLETE** |
| `docs/slices/promo-system-v1.md` | **COMPLETE** (v1 product; residuals listed in slice) |
| `docs/plans/home-page-composition-engine-v1.md` | Deferred |

**Extract branch (`feat/bounded-context-repos-v1`):** MenuRepository A1 + customization B1–B2.2.1 (smoke green 2026-08-10). Merge when ready. Cheeses/pizza-sauce controller move deferred. Authority: `docs/slices/bounded-context-repos-v1.md`, `docs/slices/customization-modal-decompose-v1.md`.

**Operator next:** Manager burn-in → soft parallel → hard Owner.com off on sign-off.

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
# extract work:
git checkout feat/bounded-context-repos-v1
git pull origin feat/bounded-context-repos-v1
```

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Template resolver | `customer_web/lib/features/storefront/storefront_landing.dart` |
| Modern landing | `customer_web/.../templates/modern/modern_storefront_home.dart` |
| Shell + cart sheet | `customer_web/lib/widgets/storefront_shell.dart` |
| HQ Website | `web-app/.../website_settings_panel.dart` |
| HQ Portal users | `web-app/lib/admin/staff/staff_access_screen.dart` · HQ Quick Link |
| Invite accept | `web-app/lib/admin/auth/invite_accept_screen.dart` · `main.dart` FutureBuilder gate |
| Station staff roster | `web-app/lib/admin/staff/pos_staff_roster_screen.dart` |
| Admin section registry | `web-app/lib/core/section_registry.dart` |
| POS open board / delivery | `pos_app/lib/features/orders/open_orders_screen.dart` |
| POS unlock / clock | `pos_app/lib/features/session/pin_unlock_screen.dart` |
| Labor service | `packages/shared_core/.../labor_firestore_service.dart` |
| Claims sync | `functions/.../userClaims.ts` (`syncClaimsOnUserRoleChange`) |
| Portal invite email CF | `sendPortalStaffInviteEmail` (SendGrid credits required) |
| **Promo model** | `packages/shared_core/lib/src/core/models/promo.dart` |
| **Promo engine** | `packages/shared_core/lib/src/core/services/promo_pricing.dart` |
| **Admin promos** | `web-app/lib/admin/promo/promo_management_screen.dart` (+ form, templates, banners) |
| **Mobile promo apply** | `mobile_app/lib/features/ordering/checkout_screen.dart` |
| **Banner → code** | `mobile_app/lib/widgets/banner/banner_action_handler.dart` |
| **Pending code** | `FranchiseProvider.pendingPromoCode` / `setPendingPromoCode` / `clearPendingPromoCode` |
| **Web checkout promo** | `customer_web/lib/features/checkout/checkout_screen.dart` |
| **MenuPricing / selection** | `packages/shared_core/.../domain/menu_pricing.dart`, `menu_customization_selection.dart` |
| **MenuRepository** | `packages/shared_core/.../repositories/menu_repository.dart`, `menu_firestore_repository.dart` |
| **CustomizationController** | `mobile_app/lib/widgets/customization/customization_controller.dart` |

---

## 3. Locks

- Hard Owner.com cutover ≠ soft parallel  
- Inventory: opt-in qty; zero blocks sell-through  
- Unlock requires open punch; off-shift needs manager PIN  
- `isPosStation` = `stationFranchise` claim only  
- Modern optional via `templateId`; default layout unchanged  
- **Portal users** = HQ-owned; **Station staff** = Admin Staff Management  
- Delivery close-out **cash-only** unless `manager_override`  
- **Promos**: Codes = pricing rules; Banners = marketing that may *promote* a code — do not merge models  
- **PromoPricing** is the single apply path for mobile + customer_web (no hardcoded codes)  
- Growth after soft stability  

---

## 4. READMEs

| Path | Covers |
|------|--------|
| `README.md` | Monorepo overview |
| `customer_web/README.md` | Storefront templates, shell, run, **checkout promo** |
| `pos_app/README.md` | Station POS, claims, clock, **delivery close-out**, run defines |
| `packages/shared_core/README.md` | Shared domain, **Promo + PromoPricing** |
| `web-app/README.md` | Admin / HQ portal, **Portal users**, Staff Management, **Promos** |
| `mobile_app/README.md` | Customer mobile, **promo checkout + banner handoff** |
| `docs/DASHBOARDS.md` | Dashboard IA |
| `docs/slices/promo-system-v1.md` | Promo product authority |
| `docs/slices/bounded-context-repos-v1.md` | MenuRepository / god-service extract |
| `docs/slices/customization-modal-decompose-v1.md` | MenuPricing + CustomizationController |

---

**Bottom line:** Ops gates + Modern + portal users HQ + station perms + delivery COD + **promos v1** on main. Extract branch has MenuRepository A1 + customization pricing/controller (smoke green). Next = burn-in / soft parallel; merge extract when ready; hardware & iOS when available.
