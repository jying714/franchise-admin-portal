# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 30, 2026 (~23:55 CDT — POS Phases 0–4 + cash close-out smoke PASS)  
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

**Active branch `feat/pos-app-v1`:**

| Item | State |
|------|--------|
| Decision 14 product lock | Done |
| Development plan Phases 0–14 | Documented |
| Phase 0 scaffold | **PASS** |
| Phase 1 shared_core domain + rules + PosFirestoreService | **PASS** |
| Phase 2 PIN / bind / Auth claims | **PASS** (Android smoke) |
| Phase 3 home + open board + action dialog | **PASS** |
| Phase 4 carry-out + modifiers + send | **PASS** |
| Phase 5 cash take-payment (pickup) | **PASS** partial |
| Phase 5 card / drawer / splits / discount / re-PIN | Open |
| Phases 6–14 | Open |

**Superseded:** `kitchen-ops-v1` pure kitchen binary — do not implement.

**Hard release gate:** Thin POS + customer website + polished mobile + web.

---

## 2. What was built (paths)

### shared_core

| Artifact | Path |
|----------|------|
| Order.source | `packages/shared_core/lib/src/core/models/order.dart` (+ ScheduledOrder forward) |
| OrderStatus | `packages/shared_core/lib/src/core/constants/order_status.dart` |
| Staff PIN/pay | `staff.dart` — `pinHash`, `hourlyPay`, `posEnabled`, `franchiseId` |
| Driver / Waitress | `driver.dart`, `waitress.dart` |
| PosSettings | `pos_settings.dart` |
| PosTableLayout | `pos_table_layout.dart` |
| PrintJob | `print_job.dart` |
| PosFirestoreService | `packages/shared_core/lib/src/core/services/pos_firestore_service.dart` |

### pos_app

| Surface | Path |
|---------|------|
| Bootstrap / Auth / bind | `lib/app/bootstrap.dart`, `main.dart` |
| Shell | `lib/app/pos_app.dart`, `theme.dart` |
| PIN session | `lib/providers/pin_session_provider.dart` |
| Permissions | `lib/core/constants/pos_permissions.dart`, `permission_gate.dart` |
| PIN hash | `lib/core/utils/pin_hash.dart` (`v1:salt:sha256`) |
| Unlock | `lib/features/session/pin_unlock_screen.dart` |
| Home | `lib/features/home/station_home_screen.dart`, `order_type_tile.dart` |
| Open orders + dialog | `lib/features/orders/open_orders_screen.dart` |
| Carry-out entry | `lib/features/ordering/order_entry_screen.dart` |
| Modifiers | `lib/features/ordering/pos_modifier_dialog.dart` (Decision 10 field names) |
| Cash payment | `lib/features/payments/payment_screen.dart` |
| Firebase options | `lib/firebase_options.dart` (FlutterFire; do not commit secrets/) |

### Rules

Live rules in repo `firestore.rules` must stay aligned with Console. Key POS pieces:

- `isPosStation(franchiseId)` → `request.auth.token.stationFranchise == franchiseId`
- `franchises/{id}/orders/{orderId}` read/write for HQ / franchise owner / pos station
- `franchises/{id}/staff/{staffId}` get for posEnabled + signed-in (lab) / owners
- `config/{docId}`, drivers, waitresses, print_jobs — franchise owner (and related)

**Do not deploy an outdated divergent `firestore.rules` over live Console without diffing.**

### Station run (smoke)

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter run -d R3GYC00Q3YN `
  --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria `
  --dart-define=STATION_AUTH_EMAIL=... `
  --dart-define=STATION_AUTH_PASSWORD=...
```

Staff test doc example: `franchises/doughboyspizzeria/staff/test1` with `posEnabled: true`, `pinHash` from `PinHash.hashPin`, permissions list.

Claims one-off: Admin `setCustomUserClaims` with `stationFranchise`, `defaultFranchise`, `franchiseIds`. Force new token (`getIdToken(true)` / clear app data) after setting claims.

---

## 3. POS development order (remaining)

Full plan: **`docs/plans/pos-app-v1-development-plan.md`**.

| Phase | Status |
|-------|--------|
| 0–4 | **Done (smoke)** |
| 5 | Cash close-out done; card, drawer, splits, discount, forced re-PIN **open** |
| 6 | Dine-in table map |
| 7 | Delivery + driver |
| 8 | Staff/driver/waitress **UI** (models exist) |
| 9–14 | Large order, 86, print, online intake, settings UI, offline, pilot |

**Carry-out payment timing (product):** pay at **pickup** via open-order **Take payment**, not at send.

**Next single step (suggested):** Phase 5.3 card-present interface **or** Phase 7 delivery customer capture — human chooses.

---

## 4. Locks (do not regress)

- Station = **`pos_app` only** — not a kitchen-only app  
- shared_core owns models; POS owns tablet UX + hardware adapters  
- No second menu modifier schema (use `effectiveModifierGroups`)  
- No silent default tenant; franchise must be bound  
- Manager-only void/refund/86/approve/settings + forced re-PIN (re-PIN UI still partial)  
- Order `source` on every order  
- Offline = cash only (not implemented yet)  
- Windows POS Firebase build may fail on CMake 4.x — prefer Android for smoke  

---

## 5. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (Decision **14**)  
- `docs/slices/pos-app-v1.md`  
- **`docs/plans/pos-app-v1-development-plan.md`**  
- `docs/slices/stripe-checkout-v1.md` (COMPLETE)  
- `docs/slices/customer-franchise-context-v1.md` (COMPLETE)  
- `docs/slices/kitchen-ops-v1.md` (superseded)

---

**Bottom line:** Carry-out station loop works end-to-end on Android with PIN, modifiers, kitchen send, board actions, and cash close-out. Continue Phase 5 remainder or Phase 6/7 per product priority. Do not invent a kitchen-only app.
