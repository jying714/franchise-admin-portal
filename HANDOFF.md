# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 2, 2026 (~22:15 CDT — parity core on main)  
**Active branch**: **`main`**  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io (Hosting `admin`)  
**Storefront**: https://franchise-storefront.web.app (Hosting `storefront`)

Prefer **STATUS.md + this handoff + `docs/slices/*`** over agent memory.

---

## 1. Where we are

**main** includes:

- HQ, Admin, menu M1–M5, mobile, Stripe Connect, POS pilot  
- HQ Restaurant settings v1 (merged)  
- customer_web MVP path **plus** parity core from `feat/customer-web-parity-v1` (**merged & branch deleted**)

### customer_web parity core (done)

- Full pizza customize (included remove, double, portion, cheeses/sauces rules, structural groups)  
- Wings: two halves (Plain or sauce) + dip cups free/paid by size  
- Shared cart/checkout line summary (`line_customization_summary.dart`)  
- Checkout pickup/delivery + structured `deliveryAddress` + `customerPhone`  
- Edit cart line: replace via `cartItemKey` (set on every `addToCart`)

| Item | State |
|------|--------|
| Customize pizza + wings + cart + checkout delivery | **On main** |
| Marketing shell (D0) | **Open** |
| Promos / directory / loyalty / custom domains | **Open** |

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Detail / customize | `customer_web/lib/features/menu/menu_item_detail_screen.dart` |
| Customize widgets | `customer_web/lib/features/menu/widgets/` |
| Cart + summary helper | `customer_web/lib/features/cart/` |
| Checkout | `customer_web/lib/features/checkout/checkout_screen.dart` |
| Order model | `packages/shared_core/lib/src/core/models/order.dart` |
| addToCart / cartItemKey | `packages/shared_core/lib/src/core/services/firestore_service_impl.dart` |
| HQ Restaurant settings | `web-app/lib/admin/hq_owner/screens/restaurant_settings_*` |
| Plan | `docs/plans/customer-web-parity-brand-storefront-v1.md` |
| Slice | `docs/slices/customer-website-v1.md` |

### Local storefront

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
cd customer_web
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
# then open http://localhost:PORT/#/f/doughboyspizzeria
```

---

## 3. Locks

- One storefront Hosting site; `/f/{franchiseId}` bind  
- `source: 'web'`; no second menu tree  
- `deliveryType` lowercase `pickup` | `delivery`; `deliveryAddress` = shared `Address` map  
- Every cart line needs `cartItemKey` for edit/replace  
- `--pwa-strategy=none` for storefront builds  
- Do not commit `pos_app/**/generated_*` noise  

---

## 4. Next coding focus

**D0 — Brand shell & marketing pages** consuming `franchises/{id}/config/storefront` (hero, story, contact).  
Then promos / store_ops delivery fee / directory.

---

**Bottom line:** Storefront **order + customize parity core is on main**. Marketing chrome and remaining P1/P2 epics are next.
