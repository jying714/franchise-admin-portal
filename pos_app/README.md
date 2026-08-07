# pos_app

Franchise **counter / station POS** (Flutter) — thin station client for order board, carry-out, payments, and staff clock-in. Not a full back-office; Admin/HQ own schedule, roster, and reporting.

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
| **pos_app** | Counter: PIN session, tickets, pay, clock |
| `web-app` | Admin schedule, station staff roster, hours/timesheets, menu ops |
| `customer_web` / `mobile_app` | Guest ordering |
| `packages/shared_core` | `PosFirestoreService`, `LaborFirestoreService`, `PinHash`, orders, menu, inventory |

**Do not** implement a separate kitchen-only binary. Kitchen-oriented flows are absorbed into this thin POS (Decision 14).

---

## Features (software pilot on main)

### Station identity
- Dart-defines: `STATION_FRANCHISE_ID`, `STATION_AUTH_EMAIL`, `STATION_AUTH_PASSWORD`
- Firebase Auth user for the device + custom claim **`stationFranchise`** (set via Admin script / ops)
- Bootstrap refreshes ID token and logs claim for diagnostics
- Firestore rules: `isPosStation(franchiseId)` → claim match only (email smoke gate removed)

### Staff session
- PIN unlock against `franchises/{id}/staff` (`pinHash` via shared `PinHash`)
- **Clock-in required** before unlock/console use
- On-schedule clock-in; **off-schedule** requires manager PIN override
- Clock-out allowed even if shift was deleted mid-punch
- Schedule reads prefer **server** source so Admin edits apply without full app restart

### Orders & payments
- Order board / detail workspace (void, comp, partial, print hooks as implemented)
- Carry-out modifiers; payment screen (cash / card / split as configured)
- Inventory: tracked items use `isSellable`; paid sale decrements; void/refund restore (shared ledger)

### Not in this app
- Week schedule editor (Admin **Schedule**)
- Staff roster + PIN assignment (Admin **Station staff**)
- Hours summary / timesheet print (Admin **Hours**)
- Full HQ financials / onboarding

---

## Key paths

```text
pos_app/lib/
  app/bootstrap.dart                 # station auth + claim refresh
  features/session/pin_unlock_screen.dart
  features/orders/                   # board, detail dialog
  features/ordering/                 # cart-like station flows
  providers/pin_session_provider.dart
  services/                          # print, card-present stubs as present
```

Shared:

```text
packages/shared_core/lib/src/core/services/pos_firestore_service.dart
packages/shared_core/lib/src/core/services/labor_firestore_service.dart
packages/shared_core/lib/src/core/utils/pin_hash.dart
packages/shared_core/lib/src/core/models/shift.dart
packages/shared_core/lib/src/core/models/time_entry.dart
```

Admin labor UI: `web-app/lib/admin/staff/`.

---

## Run (Android recommended)

Windows desktop Firebase CMake often fails — prefer an Android device/emulator for smoke.

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter pub get

flutter run -d <deviceId> `
  --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria `
  --dart-define=STATION_AUTH_EMAIL=pos-station@doughboys.local `
  --dart-define=STATION_AUTH_PASSWORD=<station-password>
```

Secrets/station passwords: keep out of git (local defines or ignored secrets files only).

### Station claim (ops)

After creating the station Auth user, set custom claim `stationFranchise` to the franchise id (project script e.g. `scripts/set-station-claim.mjs` with application credentials). Confirm logs:

```text
[POS] station claims stationFranchise=<id>
```

Without the claim, staff list / time entries reads fail closed under hardened rules.

---

## Firestore surfaces (station)

| Path | Use |
|------|-----|
| `franchises/{id}/staff/{staffId}` | Roster, `pinHash`, role, status |
| `franchises/{id}/shifts/…` | Schedule windows |
| `franchises/{id}/time_entries/…` | Open/closed punches |
| `franchises/{id}/orders/…` | Active tickets |
| `franchises/{id}/menu_items/…` | Catalog + inventory fields |

Rules must allow station claim list/get on staff and time_entries for the bound franchise.

---

## Labor contract (POS side)

1. Match PIN → active staff.  
2. If open time entry → allow unlock.  
3. Else clock-in: prefer current shift (± grace); else manager override.  
4. Clock-out closes open entry; does not require shift still to exist.  

Admin owns who is on the roster and the week grid; POS only executes clock + session.

---

## Inventory at the counter

- Tracked items with `stockCount <= 0` are not sellable (`isSellable`).  
- Successful paid paths decrement via shared inventory ledger.  
- Voids/refunds restore where implemented.  
- HQ/Admin set counts; POS does not replace inventory management UI.

---

## Related docs

| Doc | Topic |
|-----|--------|
| `STATUS.md` / `HANDOFF.md` | Live status |
| `docs/slices/pos-app-v1.md` | Product slice |
| `docs/plans/pos-app-v1-development-plan.md` | Phased plan (if present) |
| `docs/plans/mvp-ops-staff-labor-v1.md` | Labor gate |
| `docs/plans/mvp-ops-inventory-v1.md` | Inventory gate |
| `firestore.rules` | `isPosStation` |

---

## Agent / contributor notes

- Prefer Android smoke over Windows desktop for Firebase.  
- Never weaken station rules back to email-only gates.  
- PIN hashing must use **shared** `PinHash` (avoid ambiguous duplicate imports).  
- Proposal-only agents: no auto write to staff PINs or claims.  
- Human merge gate for rules, claims scripts, and payment paths.
