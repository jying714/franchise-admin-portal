# Thin POS (`pos_app`) — Development Plan (Phases 0–14 → polished MVP)

**Status**: Software pilot **COMPLETE on main** (2026-08-01)  
**Branch**: `main` (feature `feat/pos-app-v1` merged and deleted)  
**Authority**: Decision **14** · `docs/slices/pos-app-v1.md` · STATUS · HANDOFF · this file  
**Last Updated**: August 1, 2026 (~12:40 CDT)

**Progress:** Phases 0–7 ops, 5 software money, 10 mock print, 11 online MVP, 12 settings, 13 offline, 14 software smoke — **PASS**.  
**Open:** Phase 8 staff UI, 9 large/86; Terminal/real print hardware; customer website (product gate).

---

## Guiding rules (do not skip)

1. Schema before UI under human review.  
2. Session before money.  
3. Ticket before tenders.  
4. Online path before offline.  
5. Hardware last; mock early.  
6. No second menu tree.  
7. No kitchen-only binary.  
8. Carry-out pays at pickup.  
9. Online in-hours → kitchen; store_ops for tax/hours.

---

## Phase summary

| Phase | Status |
|-------|--------|
| 0–4 | **PASS** |
| 5 Payments software | **PASS** (Terminal open) |
| 6 Dine-in ops | **PASS** |
| 7 Delivery ops | **PASS** |
| 8 Staff UI | **OPEN** |
| 9 Large/86 | **OPEN** |
| 10 Print mock | **PASS** |
| 11 Online intake | **PASS** |
| 12 Settings | **PASS** (station read-only) |
| 13 Offline | **PASS** |
| 14 Software pilot QA | **PASS** 2026-08-01 |

### store_ops

Path: `franchises/{id}/config/store_ops`  
HQ: `StoreOpsScreen` + Owner HQ Quick Link **Tax & hours**.  
Consumers: mobile checkout tax + open gate; POS order entry + payment tax; station settings display.

---

## Milestone tags

| Tag | Status |
|-----|--------|
| pos-m1 … pos-m3 | **Reached** |
| pos-m4 delivery-staff | **Partial** |
| pos-m5 ops-print | **Partial** |
| pos-m6 software residual | **Reached** |

---

## Next (product, not this plan’s core)

1. **Customer website** (hard release)  
2. Staff bootstrap docs  
3. Terminal / printers when hardware lands  
4. Phases 8–9 staff UI / 86 / large order  

Do not regress carry-out pickup payment or online in-hours kitchen path.
