# Slice: POS App v1 (Thin Counter Station)

**Status**: **Software pilot COMPLETE on `main`** (2026-08-01 smoke PASS)  
**Branch**: merged via `feat/pos-app-v1` → `main`; feature branch deleted  
**Authority**: Decision **14** · STATUS · HANDOFF · this file · **`docs/plans/pos-app-v1-development-plan.md`**  
**Depends on**: Decision 12 **COMPLETE**; franchise-scoped orders; shared_core menu/modifier system  
**Pilot device**: Android tablet / S25; PaymentSheet interim for card  
**Supersedes**: Pure kitchen-only framing of Decision 13 / `kitchen-ops-v1.md`

---

## 1. Problem

Counter station must create dine-in / carry-out / delivery, take cash + card, print, surface online tickets — not a kitchen-only binary.

---

## 2. Product locks

Unchanged Decision 14 summary: thin `pos_app`; pay carry-out at pickup; order `source`; manager void/refund; no second menu tree; offline cash-only honesty.

**store_ops (locked path):** `franchises/{id}/config/store_ops` — `taxRate` + per-weekday `hours`.

---

## 3. Phase status

| Phase | Status |
|-------|--------|
| 0–7 ops + 5 software money | **PASS** |
| 8 Staff UI | Open |
| 9 Large/86 | Open |
| 10 Print mock | **PASS** |
| 11 Online intake MVP | **PASS** |
| 12 Station settings read-only | **PASS** |
| 13 Offline honesty | **PASS** |
| 14 Software pilot smoke | **PASS** 2026-08-01 |

---

## 4. Acceptance

- [x] Carry-out / dine-in / delivery ops baselines
- [x] Cash / split / card PaymentSheet
- [x] Pre-tax discount stack; tax from store_ops
- [x] Closed board + cash refund
- [x] Mock kitchen + receipt
- [x] Mobile in-hours → kitchen + auto ticket; closed day blocks
- [x] HQ Tax & hours editor + Quick Link
- [x] Station settings AppBar entry
- [x] Offline banner + card blocked
- [x] Software pilot smoke PASS
- [ ] Stripe Terminal hardware
- [ ] Real ESC-POS printers
- [ ] Staff/driver manager UI
- [ ] 86 / large-order flows

---

## 5. Residual

| ID | Item | Status |
|----|------|--------|
| R1–R2 | Tax + hours | **Done** |
| R3–R4 | Terminal / printers | Open |
| R5–R6 | Offline / settings | **Done** |
| R7 | Customer website | Separate epic |
| R8 | Staff bootstrap docs | Open |
| R9 | Software smoke | **Done** |

---

## 6. Bottom line

**Thin counter POS software pilot is complete on main.** Remaining POS work is hardware, staff ops UI, and 86/large-order — not core money/intake. Product hard release still requires **customer website**.
