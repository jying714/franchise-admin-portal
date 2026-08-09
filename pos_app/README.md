# pos_app

Franchise **counter / station POS** (Flutter) — thin station client for order board, carry-out, **delivery**, payments, and staff clock-in. Not a full back-office; Admin/HQ own schedule, roster, and reporting.

| | |
|---|---|
| **App** | Station POS (Android pilot primary) |
| **Authority** | `docs/slices/pos-app-v1.md` · Decision 14 · STATUS / HANDOFF |
| **Shared domain** | `packages/shared_core` |
| **Firebase** | Same project as platform; **station custom claims** required |

---

## Role in the monorepo

| App | Role |
|-----|------|
| **pos_app** | Counter: PIN session, tickets, pay, clock, delivery close-out |
| `web-app` | Admin schedule, **station staff roster + permissions**, hours; HQ portal users |
| `customer_web` / `mobile_app` | Guest ordering |
| `packages/shared_core` | `PosFirestoreService`, `LaborFirestoreService`, `PinHash`, orders, menu, inventory |

**Do not** implement a separate kitchen-only binary (Decision 14).

---

## Features (software pilot on main)

### Station identity
- Dart-defines: `STATION_FRANCHISE_ID`, `STATION_AUTH_EMAIL`, `STATION_AUTH_PASSWORD`
- Custom claim **`stationFranchise`**; rules `isPosStation(franchiseId)`

### Staff session
- PIN unlock against `franchises/{id}/staff` (`pinHash`, **permissions** array)
- Clock-in required; off-shift manager override
- Driver role: open board locked to **Delivery** filter

### Orders & payments
- Open board + detail workspace (void, comp, add, print hooks)
- Carry-out / dine-in / delivery entry
- Payment: cash / card / split (as permitted)

### Delivery close-out (product rule)

```text
Accept & deliver     → status out_for_delivery (in route)
Returned (unpaid)    → pending_till
Close out (cash)     → delivered (cash only)
Returned (paid)      → delivered
Card on delivery     → requires manager_override (not driver)
```

Implementation: `lib/features/orders/open_orders_screen.dart` · `OrderStatus` · `DriverAssignSheet`.

Driver staff need `view_orders` + `take_payment` + `open_drawer` for COD close-out (set on **Admin → Station staff**).

### Inventory
- Tracked items: `isSellable`; paid decrement / void restore via shared ledger

### Not in this app
- Week schedule editor, roster editor, hours print (Admin)
- Portal user invites (HQ)
- Hardware Terminal / real ESC-POS (when devices arrive)

---

## Key paths

```text
pos_app/lib/
  app/bootstrap.dart
  features/session/pin_unlock_screen.dart
  features/orders/open_orders_screen.dart    # delivery lifecycle actions
  features/orders/widgets/order_detail_dialog.dart
  features/delivery/driver_assign_sheet.dart
  features/payments/payment_screen.dart
  features/ordering/
  providers/pin_session_provider.dart
  core/constants/pos_permissions.dart
```

Admin labor UI: `web-app/lib/admin/staff/`.

---

## Run (Android recommended)

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter pub get

flutter run -d <deviceId> `
  --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria `
  --dart-define=STATION_AUTH_EMAIL=pos-station@doughboys.local `
  --dart-define=STATION_AUTH_PASSWORD=<station-password>
```

### Station claim (ops)

Set custom claim `stationFranchise` on the station Auth user. Confirm:

```text
[POS] station claims stationFranchise=<id>
```

---

## Firestore surfaces (station)

| Path | Use |
|------|-----|
| `franchises/{id}/staff/{staffId}` | Roster, pinHash, role, **permissions**, status |
| `franchises/{id}/shifts/…` | Schedule |
| `franchises/{id}/time_entries/…` | Punches |
| `franchises/{id}/orders/…` | Tickets (`out_for_delivery`, `pending_till`, …) |
| `franchises/{id}/menu_items/…` | Catalog + inventory |

---

## Related docs

| Doc | Topic |
|-----|--------|
| `STATUS.md` / `HANDOFF.md` | Live status |
| `docs/slices/pos-app-v1.md` | Product slice |
| `docs/plans/mvp-ops-staff-labor-v1.md` | Labor gate |
| `docs/plans/mvp-ops-inventory-v1.md` | Inventory gate |
| `firestore.rules` | `isPosStation` |

---

## Agent / contributor notes

- Prefer Android smoke over Windows desktop for Firebase.  
- Never weaken station rules to email-only gates.  
- PIN hashing: shared `PinHash` only.  
- Human merge gate for rules, claims, and payment paths.  

**Last updated:** August 8, 2026
