# HANDOFF.md

**As of:** Friday, August 21, 2026  
**Active branch:** `feat/pre-hardware-hq-polish`  
**Soft-release:** `main`

---

## How to start the next chat

| Priority | Path |
|----------|------|
| 1 | `STATUS.md` |
| 2 | `HANDOFF.md` |
| 3 | `docs/slices/pos-app-v1.md` |
| 4 | `docs/DECISIONS.md` (Decision **15**) |
| 5 | `docs/slices/catalog-health-v1.md` |

**Repo:** https://github.com/jying714/franchise-admin-portal  
**Local:** `C:\\projects\\franchise-admin-portal`  
**Firebase:** `doughboyspizzeria-2b3d2`

```powershell
cd C:\\projects\\franchise-admin-portal
git fetch origin
git checkout feat/pre-hardware-hq-polish
git pull origin feat/pre-hardware-hq-polish
```

Prefer a **new chat** — this POS UX thread is long.

---

## Resume here

1. **Idle timer not functional** — `PinSessionProvider` idle → `lockForRepin` → `SessionTimeoutOverlay` → `lock()`. `PosApp` wraps `Listener` `onPointerDown` → `touch()`. Smoke: overlay did not behave. Debug timer arm / `requiresRepin` / Listener swallowing. Do **not** add `pin_idle_lock_screen.dart`.
2. Then HQ idle minutes + grace seconds (existing `pinSessionTimeoutMinutes` first; do not invent store_ops keys until traced).
3. Delivery range v1: HQ mode = distance **or** drive time; same `store_ops` for POS / mobile / customer_web.

---

## Shipped on this branch (POS UX 2026-08-20/21)

- Profile builders in `pos_customization_sheet.dart` (pizza / calzone / salad / wings / sub / dinner+standard extras).
- L/R **pizza only**; Dbl pizza/calzone/sub/dinner.
- Kitchen/receipt/ticket side grouping + `wingHalves`.
- Dine-in guest optional; return to categories after Add; tap line to re-edit with `initial`.
- Floor map: seated → actions including Modify ticket + Add items.
- Cash: tender dialog, change dialog, **leave open** until **Close out (tip)** (`cashTip`, `closedByStaffName`).
- Card: optional `cardTip` at pay; completes immediately.
- EOD (owner/manager/admin): expandable cash/card/overall by source; tips by staff → order ids.
- `source: pos` already on create.

**Do not add** `paymentMethod` / `tableId` to `Order` unless a dedicated model slice — read the order document.

---

## Hardware (unchanged)

TSP143 `192.168.1.21` StarGraphic + DK drawer **PASS**. Stripe reader on site. One printer for MVP roles.

---

## Operating rules

- Human is merge gate; agents proposal-only  
- Prefer real paths; no invented schema fields  
- Quote source for surgical edits  

**Bottom line:** POS can build profile items, take cash with tip close-out, and roll EOD. **Next chat: idle timer**, then delivery range.
