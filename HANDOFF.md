# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 1, 2026 (~22:40 CDT — customer_web scaffold; website epic next)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `main`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web (Admin/HQ)**: franchisehq.io (Deploy Web on push to `main` only)  
**Customer site host**: TBD (intent: separate from Admin shell, e.g. `order.franchisehq.io`)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/plans/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5, mobile tokens, developer dashboard, customer franchise context (11), Stripe Connect (12), POS software pilot + order-detail workspace (14), 2026-08-01 mobile/web/POS cleanup.

**Next epic: Customer website**
- Path: **`customer_web/`** — top-level Flutter **web** app (sibling to `mobile_app` / `pos_app` / `web-app`)
- Slice: **`docs/slices/customer-website-v1.md`**
- Scaffold script: **`scripts/scaffold_customer_web.ps1`** (empty feature files only)
- **Implementation not started** — wire `shared_core`, `/f/{slug}` bind, menu, auth, checkout, Hosting target still open

| Item | State |
|------|--------|
| Thin POS software pilot | **COMPLETE on main** |
| POS order-detail workspace | **COMPLETE on main** |
| Customer website | **Scaffold only** — next build |
| Stripe Terminal / real print | **Open** |

**Hard release gate:** Thin POS (software **done**) + **customer website** + polished mobile + web.

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| **Customer website app** | `customer_web/` |
| **Customer website slice** | `docs/slices/customer-website-v1.md` |
| Scaffold script | `scripts/scaffold_customer_web.ps1` |
| HQ Tax & hours | `web-app/lib/admin/hq_owner/screens/store_ops_screen.dart` |
| POS order detail | `pos_app/lib/features/orders/widgets/order_detail_dialog.dart` |
| POS line ops | `pos_app/lib/features/orders/order_line_ops.dart` |
| shared_core orders / lineStatus | `packages/shared_core/lib/src/core/models/order.dart` |
| MenuProfile.sub | `packages/shared_core/lib/src/core/models/menu_profile_templates.dart` |
| Mobile checkout (parity reference) | `mobile_app/lib/features/ordering/checkout_screen.dart` |

### Customer website local (when implementing)

```powershell
cd C:\projects\franchise-admin-portal\customer_web
flutter create --platforms=web --project-name customer_web .   # if not already
powershell -ExecutionPolicy Bypass -File ..\scripts\scaffold_customer_web.ps1
# then: path dependency on packages/shared_core in pubspec.yaml
flutter run -d chrome
```

### Station run (POS)

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter run -d <deviceId> --dart-define=STRIPE_PK=pk_test_... --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria --dart-define=STATION_AUTH_EMAIL=... --dart-define=STATION_AUTH_PASSWORD=...
```

---

## 3. Residual

| ID | Residual | Status |
|----|----------|--------|
| R7 | **Customer website** | Scaffold started; product build **next** |
| R3–R4 | Terminal / printers | Open |
| R8 | Staff bootstrap docs | Open |
| R10 | Order-detail workspace | **Done** |

---

## 4. Locks (do not regress)

- Station = `pos_app` only  
- Customer storefront = **`customer_web`**, not Admin `web-app` routes  
- One website app; franchise bind via URL slug/path; no per-franchise Hosting project for MVP  
- Decision 11 rules: browse signed-out; cart/checkout authed; clear cart on franchise switch  
- Orders from site: `source: 'web'`  
- No second menu modifier tree  
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

**Bottom line:** POS pilot + order workspace are on **main**. **Build `customer_web` next** (hard release). Do not put customer ordering inside the Admin shell.
