# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 2, 2026 (~09:15 CDT — customer_web live vertical slice + HQ QR)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/customer-website-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web (Admin/HQ)**: franchisehq.io (Hosting target `admin`)  
**Live storefront**: https://franchise-storefront.web.app (Hosting target `storefront`)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/plans/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5, mobile tokens, developer dashboard, customer franchise context (11), Stripe Connect (12), POS software pilot + order-detail workspace (14), 2026-08-01 mobile/web/POS cleanup.

**On `feat/customer-website-v1` (2026-08-02): Customer website vertical slice PASS**

| Item | State |
|------|--------|
| Thin POS software pilot | **COMPLETE on main** |
| POS order-detail workspace | **COMPLETE on main** |
| Customer website product path | **PASS** — bind → menu → auth → cart → Connect pay → POS sees `source: 'web'` |
| Storefront Hosting | **Live** — `franchise-storefront.web.app` |
| HQ publish UX | **Copy / Open / QR** on Owner HQ dashboard |
| Stripe Terminal / real print | **Open** |

**Hard release gate:** Thin POS (software **done**) + customer website (vertical slice **done on feature branch**) + polished mobile + web. Merge when human approves.

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| **Customer website app** | `customer_web/` |
| **Customer website slice** | `docs/slices/customer-website-v1.md` |
| Router / bind | `customer_web/lib/core/router.dart`, `franchise_bind.dart` |
| Checkout | `customer_web/lib/features/checkout/checkout_screen.dart` |
| HQ storefront card | `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` (`StorefrontLinkCard`) |
| Hosting config | `firebase.json` (targets `admin` + `storefront`), `.firebaserc` |
| Storefront CI | `.github/workflows/deploy-storefront.yml` |
| Mobile checkout (parity) | `mobile_app/lib/features/ordering/checkout_screen.dart` |

### Customer website local

```powershell
cd C:\projects\franchise-admin-portal\customer_web
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...

# Production-like build (no PWA SW cache traps)
flutter build web --release --pwa-strategy=none --dart-define=STRIPE_PK=pk_test_...
cd ..
firebase deploy --only hosting:storefront
```

**Public link:** `https://franchise-storefront.web.app/f/{franchiseId}`  
Path cold-load uses `index.html` hash bootstrap + landing/GoRouter bind so mobile QR works.

### Station run (POS)

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter run -d <deviceId> --dart-define=STRIPE_PK=pk_test_... --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria --dart-define=STATION_AUTH_EMAIL=... --dart-define=STATION_AUTH_PASSWORD=...
```

---

## 3. Residual

| ID | Residual | Status |
|----|----------|--------|
| R7 | **Customer website** | Vertical slice **PASS**; merge + Phase 4b (modifier customizations on cart line) + optional custom domains |
| R3–R4 | Terminal / printers | Open |
| R8 | Staff bootstrap docs | Open |
| R10 | Order-detail workspace | **Done** |

---

## 4. Locks (do not regress)

- Station = `pos_app` only  
- Customer storefront = **`customer_web`**, not Admin `web-app` routes  
- **One** storefront Hosting site; franchises share it; bind via `/f/{franchiseId}`  
- Decision 11: browse signed-out; cart/checkout authed; clear cart on franchise switch  
- Orders from site: `source: 'web'`  
- No second menu modifier tree  
- Stripe publishable key only via `--dart-define` / CI secret `STRIPE_PK_TEST`  
- Prefer `--pwa-strategy=none` for storefront deploys  
- POS line void/comp via `lineStatus` + stream detail dialog  

---

## 5. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (11, 12, **14**)  
- `docs/slices/customer-website-v1.md`  
- `docs/slices/pos-app-v1.md`  
- `docs/slices/customer-franchise-context-v1.md`  
- `docs/slices/stripe-checkout-v1.md`  

---

**Bottom line:** POS pilot is on **main**. Customer website **orders end-to-end on Hosting** on `feat/customer-website-v1`. Merge when ready; keep Admin and storefront as separate Hosting targets.
