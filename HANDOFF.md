# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 1, 2026 (~12:40 CDT — POS software pilot on `main`; website next)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `main`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/plans/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5 + wings/calzone, mobile design tokens, developer dashboard, customer franchise context (11), Stripe checkout (12), mobile+web residual polish, **thin POS software pilot (14)**.

**POS software pilot (merged 2026-08-01):** money truth, PaymentSheet card, closed board/refund, mock print, online intake, HQ `store_ops`, station settings, offline honesty — smoke **PASS**. Feature branch `feat/pos-app-v1` **deleted** after merge.

**Next:** Customer **website** (hard release gate) and/or hardware (Terminal, printers). Staff UI / 86 / large-order remain open.

| Item | State |
|------|--------|
| Thin POS software pilot | **COMPLETE on main** |
| HQ Tax & hours (`config/store_ops`) | **Done** |
| Mobile/POS consumers of store_ops | **Done** |
| Offline banner + card block | **Done** |
| Station settings (AppBar) | **Done** |
| Stripe Terminal / real print | **Open** |
| Customer website | **Not started** |

**Hard release gate:** Thin POS (software **done**) + customer website + polished mobile + web.

---

## 2. High-signal paths

| Surface | Path |
|---------|------|
| HQ Tax & hours | `web-app/lib/admin/hq_owner/screens/store_ops_screen.dart` |
| HQ Quick Link | `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` |
| store_ops doc | `franchises/{id}/config/store_ops` |
| POS payment | `pos_app/lib/features/payments/payment_screen.dart` |
| POS order entry | `pos_app/lib/features/ordering/order_entry_screen.dart` |
| POS home / offline / settings entry | `pos_app/lib/features/home/station_home_screen.dart` |
| Station settings | `pos_app/lib/features/settings/station_settings_screen.dart` |
| Card collect | `pos_app/lib/services/card_present_service.dart` |
| Print mocks | `pos_app/lib/services/print_service.dart` |
| Mobile checkout | `mobile_app/lib/features/ordering/checkout_screen.dart` |

### Station run

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter run -d <deviceId> --dart-define=STRIPE_PK=pk_test_... --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria --dart-define=STATION_AUTH_EMAIL=... --dart-define=STATION_AUTH_PASSWORD=...
```

Card test: `4242 4242 4242 4242`. Franchise needs `paymentsEnabled: true`.

---

## 3. Residual (post software pilot)

| ID | Residual | Status |
|----|----------|--------|
| R1–R2 | Tax + hours config | **Done** |
| R3 | Terminal | Open |
| R4 | Real printers | Open |
| R5–R6 | Offline + settings | **Done** |
| R7 | **Customer website** | **Open — next epic** |
| R8 | Staff bootstrap docs | Open |
| R9 | Software smoke | **Done** |

---

## 4. Locks (do not regress)

- Station = `pos_app` only  
- Carry-out pays at pickup  
- store_ops path for tax/hours  
- Mobile in-hours → kitchen; closed day blocks place  
- Offline: no card; banner honesty  
- No second menu modifier tree; no kitchen-only binary  

---

## 5. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (Decision **14**)  
- `docs/slices/pos-app-v1.md`  
- `docs/plans/pos-app-v1-development-plan.md`  
- `docs/slices/stripe-checkout-v1.md`  
- `docs/architecture/firestore-per-franchise-config.md`

---

**Bottom line:** Thin POS **software pilot is on main**. Next build epic is **customer website** (or hardware when available). Do not reopen kitchen-only app scope.
