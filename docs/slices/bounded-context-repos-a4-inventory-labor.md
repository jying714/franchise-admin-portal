# Slice: Bounded-context repos A4 — Inventory + Labor formalization

**Status:** A4.1–A4.2 COMPLETE on `feat/bounded-context-repos-a4-inventory-labor` (2026-08-11)
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

1. ~~Quote real public APIs~~ **DONE**
2. ~~Define abstracts~~ **DONE** — `inventory_repository.dart`, `labor_repository.dart`
3. ~~Concrete delegates~~ **DONE** — `InventoryFirestoreRepository` → `InventoryLedger`; `LaborFirestoreRepository` → `LaborFirestoreService`
4. Optional call-site injection — **deferred** (direct service/ledger calls remain valid)
5. Smoke: inventory 86 + POS clock after merge

**Barrel:** both pairs exported from `shared_core.dart`.

---

## 4. Locks

- Human is merge gate.
- Soft-release order path stays green.
- No new fields on domain models for this phase.

**Last updated:** 2026-08-11
