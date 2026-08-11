# Slice: Bounded-context repositories v1

**Status:** A1–A3 in progress / complete on extract branches; A3 Order DONE on `feat/bounded-context-repos-a3-orders`  
**Authority for:** Phase A of the god-object containment plan  
**Related:** `docs/slices/customization-modal-decompose-v1.md`, `docs/slices/bounded-context-repos-a4-inventory-labor.md`, `STATUS.md`, `HANDOFF.md`

---

## Goal (zero behavior change)

Extract bounded repositories behind `FirestoreService` façades. No schema changes. Soft-release order path stays green.

---

## Phases

| Phase | Work | State |
|-------|------|--------|
| **A1** | MenuRepository + façade | DONE |
| **A2** | ConfigRepository + façade | DONE (toggles + franchise info + business hours) |
| **A3** | OrderRepository + façade | **DONE on `feat/bounded-context-repos-a3-orders`** — cart + core order methods |
| **A4** | Inventory + Labor formalize | **DONE on `feat/bounded-context-repos-a4-inventory-labor`** — thin repos over `InventoryLedger` + `LaborFirestoreService` |
| **A5** | Remaining contexts as needed | Later |

---

## A3 (Order) — complete 2026-08-11

- `OrderRepository` abstract (signatures mirror `FirestoreService`)
- `OrderFirestoreRepository` (bodies from `FirestoreServiceImpl`)
- Façade forwards on `FirestoreServiceImpl` for: getCart, updateCart, addToCart, removeFromCart, getCartItemCountStream, clearCart, addOrder, getOrdersForUser, updateOrderStatus, refundOrder, getAllOrdersStream, getOrders

Scheduled-order methods remain on the service until a later slice if needed.

---

## A4 (Inventory + Labor) — next

**Do not reimplement.** Wrap:

- `inventory_ledger.dart` → InventoryRepository
- `labor_firestore_service.dart` → LaborRepository

Authority detail: `docs/slices/bounded-context-repos-a4-inventory-labor.md`

---

## Façade rules (non-negotiable)

1. `FirestoreService` keeps existing method signatures for at least one release after extract.
2. Impl becomes thin forwards.
3. No invented Firestore paths or domain fields.
4. Prefer read paths first, write second; smoke soft-release after each PR.

---

**Last updated:** 2026-08-11
