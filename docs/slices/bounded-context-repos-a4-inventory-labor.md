# Slice: Bounded-context repos A4 — Inventory + Labor formalization

**Status:** NEXT on `feat/bounded-context-repos-a4-inventory-labor`  
**Authority for:** Phase A4 of god-object containment  
**Depends on:** A1 Menu, A2 Config, A3 Order (merge A3 to main first)  
**Parent:** `docs/slices/bounded-context-repos-v1.md`

---

## 1. Goal (zero behavior change)

Formalize existing focused services as bounded repositories — **do not reimplement**:

| Existing | Promote / wrap as |
|----------|-------------------|
| `packages/shared_core/lib/src/core/services/inventory_ledger.dart` | `InventoryRepository` + thin Firestore adapter if needed |
| `packages/shared_core/lib/src/core/services/labor_firestore_service.dart` | `LaborRepository` (or alias) |

Empty stub files `inventory_repository.dart` / `labor_repository.dart` (if present) must be **replaced** with real interfaces matching live method names — not left blank.

---

## 2. Non-goals

- New inventory or clock product features
- POS print / hardware
- Schema changes
- Call-site big-bang migration (façade first)

---

## 3. Steps

1. Quote real public APIs on `InventoryLedger` / `LaborFirestoreService`.
2. Define `InventoryRepository` / `LaborRepository` abstracts that match those APIs.
3. Implement or typedef concrete classes that delegate to existing services.
4. Optional: façade any overlapping methods still on `FirestoreServiceImpl`.
5. Smoke: inventory 86 + POS clock (same as burn-in checks).

---

## 4. Locks

- Human is merge gate.
- Soft-release order path stays green.
- No new fields on domain models for this phase.

**Last updated:** 2026-08-11
