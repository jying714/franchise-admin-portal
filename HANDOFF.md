# HANDOFF.md — Agent Context & Project Status

**Last Updated**: August 1, 2026 (~09:40 CDT — POS pilot path smoke PASS; docs residual listed)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/pos-app-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/plans/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5 + wings/calzone, mobile design tokens, developer dashboard, customer franchise context (11), Stripe checkout (12), mobile+web residual polish.

**Active branch `feat/pos-app-v1` — pilot baseline (2026-08-01):**

| Item | State |
|------|--------|
| Decision 14 product lock | Done |
| Phases 0–4 (shell, board, carry-out) | **PASS** |
| Phase 5 tax + discount pre-tax stack | **PASS** |
| Phase 5 cash / split / live amount due | **PASS** |
| Phase 5 card (PaymentSheet + Connect PI) | **PASS** (software; Terminal open) |
| Closed orders + date/type filters | **PASS** |
| Refund skeleton (cash full, re-PIN) | **PASS** |
| Print mocks (kitchen + customer receipt) | **PASS** |
| Dine-in / delivery ops surfaces | **PASS** (ops-level) |
| Online intake: mobile in-hours → kitchen + auto ticket | **PASS** |
| Outside-hours mobile block | **PASS** (hardcoded hours) |
| HQ tax / store hours config | **Open** |
| Terminal / real printers / offline / settings UI | **Open** |
| Customer website | **Not started** |

**Superseded:** pure kitchen-only binary — do not implement.

**Hard release gate:** Thin POS + customer website + polished mobile + web.

**Rough sense:** thin POS pilot ~75–80%; full hard-release gate (incl. website) ~50%.

---

## 2. What was built (paths)

### shared_core

| Artifact | Path |
|----------|------|
| Order.source | `packages/shared_core/lib/src/core/models/order.dart` |
| OrderStatus | `packages/shared_core/lib/src/core/constants/order_status.dart` |
| Staff PIN/pay | `staff.dart` |
| Driver / Waitress | `driver.dart`, `waitress.dart` |
| PosSettings / layout / PrintJob | models under shared_core |
| PosFirestoreService | `pos_firestore_service.dart` |

### pos_app (high-signal)

| Surface | Path |
|---------|------|
| Bootstrap + Stripe PK | `lib/app/bootstrap.dart` |
| PIN session / permissions | `lib/providers/pin_session_provider.dart`, `pos_permissions.dart` |
| Home + Closed tile | `lib/features/home/station_home_screen.dart` |
| Open board + auto ticket + Send to kitchen | `lib/features/orders/open_orders_screen.dart` |
| Closed board + refund | `lib/features/orders/closed_orders_screen.dart` |
| Order entry + tax helpers + kitchen mock | `lib/features/ordering/order_entry_screen.dart` |
| Payment (cash/split/card) | `lib/features/payments/payment_screen.dart` |
| Card collect (PI + PaymentSheet / mock fallback) | `lib/services/card_present_service.dart` |
| Print mocks | `lib/services/print_service.dart` |
| Android Stripe shell | `MainActivity` = `FlutterFragmentActivity`; themes AppCompat/MaterialComponents (values + values-night) |

### mobile_app

| Surface | Path |
|---------|------|
| Checkout in-hours → `sent_to_kitchen` | `lib/features/ordering/checkout_screen.dart` |
| Outside-hours block | same file (`_storeOpenNow`, 11–21 provisional) |
| Stripe PaymentSheet (existing) | checkout + `STRIPE_PK` |

### Station run

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter run -d <deviceId> --dart-define=STRIPE_PK=pk_test_... --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria --dart-define=STATION_AUTH_EMAIL=... --dart-define=STATION_AUTH_PASSWORD=...
```

Use a **single line** for dart-defines in PowerShell (or space before each line-continuation backtick). Wrong continuation glues flags and drops `STATION_FRANCHISE_ID`.

Card test: `4242 4242 4242 4242`. Franchise needs `paymentsEnabled: true` + Connect for real PI.

---

## 3. Residual list (do not invent “MVP complete” without this)

| ID | Residual | Status |
|----|----------|--------|
| R1 | Franchise **tax rate** config (replace provisional 0.0925) | Open |
| R2 | Franchise **store hours** config (replace mobile hardcode) | Open |
| R3 | Stripe **Terminal** / physical reader | Open (PaymentSheet interim OK for software pilot) |
| R4 | Real **printers** | Open (mock OK with setting) |
| R5 | **Offline** honesty | Open |
| R6 | Station **settings** UI | Open |
| R7 | **Customer website** | Not started |
| R8 | Staff bootstrap documented | Partial |
| R9 | Phase 14 pilot smoke script sign-off | Open |

**Post-MVP:** scheduled orders; card refund reverse; partial refunds; guest cart; live delivery map; full time-clock.

---

## 4. Locks (do not regress)

- Station = **`pos_app` only**  
- Carry-out **pays at pickup**  
- shared_core models; no second modifier tree  
- No silent default tenant  
- Manager void/refund + re-PIN  
- Order `source` on every order  
- Mobile in-hours → kitchen; outside hours block (until scheduled exists)  
- Prefer Android for station smoke  

---

## 5. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (Decision **14**)  
- `docs/slices/pos-app-v1.md`  
- `docs/plans/pos-app-v1-development-plan.md`  
- `docs/slices/stripe-checkout-v1.md`  
- `docs/slices/customer-franchise-context-v1.md`  
- `docs/slices/kitchen-ops-v1.md` (superseded)

---

## 6. Next product steps (suggested order)

1. HQ **tax** + **store hours** config (kill hardcodes)  
2. Station settings stub  
3. Offline honesty  
4. Customer website slice  
5. Terminal / real print when hardware lands  
6. Phase 14 acceptance checklist  

**Bottom line:** Counter pilot loop works: PIN → order types → kitchen send → cash/split/card pay → closed board/refund; mobile in-hours hits kitchen with auto ticket. Remaining work is **config, packaging, offline, website, hardware** — not more order-type chrome.
