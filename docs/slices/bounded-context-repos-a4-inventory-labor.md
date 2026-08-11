# Slice: Bounded-context repos A4 — Inventory + Labor formalization

**Status:** COMPLETE on `feat/bounded-context-repos-a4-inventory-labor` (2026-08-11)  
**Authority for:** Phase A4 of god-object containment  
**Parent:** `docs/slices/bounded-context-repos-v1.md`

---

## 1. Goal (zero behavior change)

Formalize inventory + labor behind repositories and migrate call sites.

| Existing implementation | Repository |
|-------------------------|------------|
| `inventory_ledger.dart` | `InventoryRepository` / `InventoryFirestoreRepository` |
| `labor_firestore_service.dart` | `LaborRepository` / `LaborFirestoreRepository` |

---

## 2. Done

| Step | State |
|------|--------|
| A4.1 Inventory abstract + delegate | DONE |
| A4.2 Labor abstract + delegate | DONE |
| A4.4 Inventory call sites | DONE — customer_web + mobile checkout; POS order entry, order detail, payment |
| A4.5 Labor call sites | DONE — POS `pin_unlock_screen`; Admin schedule + hours summary |
| Barrel exports | DONE |

**Call sites:** UI uses repositories only. `InventoryLedger` / `LaborFirestoreService` remain as implementation used by the adapters.

---

## 3. Non-goals (unchanged)

- New inventory or clock product features
- POS print / hardware
- Schema changes

---

## 4. Smoke after merge

- Inventory 86 → block sell-through; restock restores
- POS clock in/out + shift window
- Admin schedule load/save; hours range

---

**Last updated:** 2026-08-11
