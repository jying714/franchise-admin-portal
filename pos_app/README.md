# pos_app

Franchise **counter / station POS** (Flutter).

| | |
|---|---|
| **Authority** | `docs/slices/pos-app-v1.md` · Decision 14 · STATUS / HANDOFF |
| **Shared domain** | `packages/shared_core` |

**Do not** implement a separate kitchen-only binary (Decision 14).

---

## Run (Android)

```powershell
cd C:\projects\franchise-admin-portal\pos_app
flutter run -d <deviceId> `
  --dart-define=STATION_FRANCHISE_ID=doughboyspizzeria `
  --dart-define=STATION_AUTH_EMAIL=pos-station@doughboys.local `
  --dart-define=STATION_AUTH_PASSWORD=<station-password> `
  --dart-define=POS_PRINTER_HOST=192.168.1.21
```

---

## Station UX (polish branch)

- Customize via `PosCustomizationSheet` (menuProfile).
- Cash: tender → change → leave open → **Close out (tip)**.
- Card: optional tip → complete.
- EOD: Station home (owner/manager/admin).
- Idle: `SessionTimeoutOverlay` after `lockForRepin` (**timer not verified**).

Print: StarGraphic via vendored `vendor/flutter_star_prnt_plus`. Do not commit `vendor/**/.gradle/`.

**Last updated:** August 21, 2026
