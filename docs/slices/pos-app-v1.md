# Slice: POS App v1 (Thin Counter Station)

**Status**: Software pilot on `main` + print/drawer live + **station UX on `feat/pre-hardware-hq-polish`** (2026-08-21)  
**Authority**: Decision **14** · STATUS · HANDOFF · this file · **`docs/plans/pos-app-v1-development-plan.md`**

---

## Product locks

Thin `pos_app`; pay carry-out at pickup; order `source`; manager void/refund; no second menu tree.

**store_ops:** `franchises/{id}/config/store_ops` — `taxRate`, `deliveryFee`, hours. Delivery **range** (distance or drive time) is the next shared setting — do not invent keys until the live doc is quoted.

---

## Station UX (2026-08-20/21)

| Area | Path / rule |
|------|----------------|
| Profile builder | `pos_app/lib/features/customization/pos_customization_sheet.dart` |
| Pizza | L/R + Dbl; sauce split = one whole or opposite halves |
| Calzone / sub / dinner | Dbl only; dinner also covers `menuProfile: standard` with extras |
| Salad | Optional add-ons then dressings; free/extra from item |
| Wings | Half 1/2 + dipping cups; free cups by size |
| Ticket / print | WHOLE / LEFT / RIGHT / HALF; `optionLabels`; skip raw `wing_sauce` |
| Cash | Tender → drawer → change; status stays open; **Close out (tip)** writes `cashTip` |
| Card | Optional `cardTip` then complete |
| EOD | `pos_app/lib/features/reports/end_of_day_screen.dart` — manager/owner/admin |
| Idle | `session_timeout_overlay.dart` + `lockForRepin` — **timer smoke FAIL** |

Firestore extras on close (merge-only, not required `Order` fields): `cashTip`, `cardTip`, `closedByStaffId`, `closedByStaffName`, `paymentMethod`, `tableId`.

---

## Acceptance (added)

- [x] Star TSP100 StarGraphic print + DK drawer
- [x] Profile-accurate POS builders
- [x] Cash tip close-out + EOD rollup
- [ ] Idle overlay timer verified
- [ ] HQ idle + grace seconds
- [ ] Delivery range gate (3 clients)
- [ ] Stripe Terminal hardware
- [ ] HQ printer-by-category

---

## Hardware (2026-08-18)

TSP143 `192.168.1.21` · StarGraphic only (not raw 9100) · vendored `pos_app/vendor/flutter_star_prnt_plus` · `--dart-define=POS_PRINTER_HOST`.
