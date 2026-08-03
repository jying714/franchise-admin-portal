# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 3, 2026 (~00:25 CDT — shell Wave 1 + composition engine locked)  
**Active branch**: **`main`**  
**Next feature branch (when coding)**: `feat/customer-web-storefront-shell-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Admin/HQ**: franchisehq.io · **Storefront**: https://franchise-storefront.web.app

Prefer **STATUS.md + this handoff + `docs/plans/*` + `docs/slices/*`** over agent memory.

---

## 1. Where we are

**main:** HQ, Admin, menu M1–M5, mobile, Stripe, POS software pilot, HQ Restaurant settings, customer_web **order + customize parity**.

**Locked (docs only, not yet coded):**

| Wave | Plan | Intent |
|------|------|--------|
| **1** | `docs/plans/customer-web-storefront-shell-v1.md` | Persistent storefront chrome; nested menu→checkout; section-shaped home |
| **2** | `docs/plans/home-page-composition-engine-v1.md` | HQ add/remove/reorder widgets; live preview; draft/publish; templates later; mobile later |

**Do not start Wave 2 HQ studio until Wave 1 public home is widgetized and acceptable.**

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| Home (today) | `customer_web/lib/features/home/storefront_home_screen.dart` |
| Shell (today) | `customer_web/lib/widgets/branding_shell.dart` |
| Router | `customer_web/lib/core/router.dart` (only `/` + `/f/:id` → home; menu is `Navigator.push`) |
| Customize | `customer_web/lib/features/menu/menu_item_detail_screen.dart` + `widgets/` |
| Cart / checkout | `customer_web/lib/features/cart/` · `checkout/checkout_screen.dart` |
| HQ Website tab | Restaurant settings → Website panel (content fields today; studio = Wave 2) |

### Local storefront

```powershell
cd C:\projects\franchise-admin-portal
git checkout main
git pull origin main
cd customer_web
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
# http://localhost:PORT/#/f/doughboyspizzeria
```

---

## 3. Locks

- Order path: `source: 'web'`; `cartItemKey` on every add; delivery Address schema  
- Wave 1: **in-shell** navigation; home built as **named section widgets**  
- Wave 2: **closed widget catalog** only — no arbitrary HTML/JS  
- Mobile composition: **post-MVP**, same schema idea, **not** identical web layout  
- Templates: post-MVP  
- POS hardware / iOS: blocked on physical devices  

---

## 4. Next coding focus

1. Implement **Wave 1** per `docs/plans/customer-web-storefront-shell-v1.md`.  
2. Keep customize/cart/checkout behavior; change **where** they mount (shell body).  
3. Wave 2 only after human accepts Wave 1 home + shell.

---

**Bottom line:** Parity core is on main. Next code is **storefront shell + nested UX + widgetized home**. HQ design studio and mobile home engine are **documented and deferred**.
