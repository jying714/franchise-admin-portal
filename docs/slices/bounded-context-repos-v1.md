# Slice: Bounded-context repositories v1

**Status:** **A1–A4 COMPLETE** on main (2026-08-11)  
**Authority for:** Phase A of the god-object containment plan  
**Related:** `docs/slices/customization-modal-decompose-v1.md`, `docs/slices/bounded-context-repos-a4-inventory-labor.md`, `docs/architecture/containment-progress-2026-08-11.md`, `STATUS.md`, `HANDOFF.md`

---

## Goal (zero behavior change)

Extract bounded repositories behind `FirestoreService` façades. No schema changes. Soft-release order path stays green.

---

## Phases

| Phase | Work | State |
|-------|------|--------|
| **A1** | MenuRepository + façade | **DONE** |
| **A2** | ConfigRepository + façade | **DONE** (toggles + franchise info + business hours) |
| **A3** | OrderRepository + façade | **DONE** — cart + core order methods |
| **A4** | Inventory + Labor | **DONE** — repos + call-site migration (checkout, POS, Admin, PIN clock) |
| **A5** | Remaining contexts (billing, audit, …) | **Optional / not started** |

### Call-site depth

| Context | Façade on FirestoreServiceImpl | UI/call sites on repo |
|---------|--------------------------------|------------------------|
| Menu / Config | Yes | Partial (many still use FirestoreService) |
| Order | Yes | Partial |
| Inventory | N/A (ledger adapter) | **Yes** |
| Labor | N/A (service adapter) | **Yes** |

---

## Façade rules (non-negotiable)

1. `FirestoreService` keeps existing method signatures for at least one release after extract.
2. Impl becomes thin forwards where extracted.
3. No invented Firestore paths or domain fields.
4. Prefer read paths first, write second; smoke soft-release after each PR.

---

## Remaining (not blocking hardware)

- Optional Order/Menu/Config call-site migration off god service (same depth as A4)
- A5 other contexts
- Deprecate forwarded methods only after all call sites migrated

**Last updated:** 2026-08-11
