# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 2, 2026 (~10:50 CDT — customer_web 4b + chrome)  
**Active branch**: `feat/customer-website-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io (Hosting `admin`)  
**Storefront**: https://franchise-storefront.web.app (Hosting `storefront`)

Prefer **STATUS.md + this handoff + `docs/slices/*`** over agent memory.

---

## 1. Where we are

**main:** HQ, Admin, menu M1–M5, mobile, Stripe Connect, POS pilot + order-detail.

**feat/customer-website-v1:** Customer website **order path complete** including:

- Path bind + Hosting + HQ QR  
- Phase **4b** unit price: size base + option upcharges **or** size `toppingPrice`  
- Cart customizations display + qty steppers  
- Shell: single cart icon, sign-in / sign-out, **My orders**  

| Item | State |
|------|--------|
| Customer website product path | **PASS** |
| Merge to main | **Open** (human gate) |
| Custom domains | **Open** (optional) |

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Detail / 4b pricing | `customer_web/lib/features/menu/menu_item_detail_screen.dart` |
| Cart | `customer_web/lib/features/cart/cart_screen.dart` |
| Shell | `customer_web/lib/widgets/branding_shell.dart` |
| Order history | `customer_web/lib/features/orders/order_history_screen.dart` |
| HQ QR card | `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` |
| Slice | `docs/slices/customer-website-v1.md` |

### Local storefront

```powershell
cd C:\projects\franchise-admin-portal\customer_web
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
# then open http://localhost:PORT/#/f/doughboyspizzeria
```

**Antipasta pricing example:** Small base 8.45 + N × toppingPrice 0.85; Large 9.99 + N × 1.15.

---

## 3. Locks

- One storefront Hosting site; `/f/{franchiseId}` bind  
- `source: 'web'`; no second menu tree  
- `--pwa-strategy=none` for storefront builds  
- Do not commit `pos_app/**/generated_*` noise from unrelated platform builds  

---

**Bottom line:** Storefront is feature-complete for MVP order + account chrome. **Merge when gated.**
