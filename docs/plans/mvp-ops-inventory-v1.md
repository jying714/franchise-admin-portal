# MVP-Ops Inventory v1 — Owner.com cutover gate

**Status:** **COMPLETE** (2026-08-04) — merged to **main**  
**Authority:** STATUS · HANDOFF · Doughboys operator requirement · this plan  
**Scope:** Franchise-scoped quantity tracking when inventory is enabled; 86 at zero across channels

---

## 1. Problem

Managers will not run the restaurant solely on FranchiseHQ without knowing **what is left** and **not selling zero**. Soft parallel with Owner.com can tolerate gaps; **permanent cutover cannot**.

---

## 2. Product minimum (v1) — delivered

| Rule | Behavior |
|------|----------|
| Opt-in tracking | `inventoryTracked` on menu items |
| Quantity | `stockCount` (and related HQ fields) |
| Zero tracked item | Not sellable via `MenuItem.isSellable` / `isInventoryBlocked` |
| Channels | customer_web, mobile, POS list filters respect sellability |
| Sales | `InventoryLedger.applySaleDecrement` on paid success |
| Voids / refunds | `InventoryLedger.applySaleRestore` on void/refund paths |

**Non-goals v1 (still out):** vendor POs, multi-warehouse, recipe yield math, ingredient-required 86 graph, barcode receiving.

---

## 3. Locks (held)

| ID | Lock |
|----|------|
| I1 | Franchise-scoped on-hand |
| I2 | Untracked entities never block sales |
| I3 | Tracked at 0 → not sellable on order channels |
| I4 | Decrement once per sold unit (order flags / ledger) |
| I5 | HQ can enable flag + edit qty |

---

## 4. Acceptance

- [x] Enabled menu item at 0 not orderable on web, mobile, POS  
- [ ] Enabled ingredient at 0 86s dependent items — **deferred** (item-level v1 only)  
- [x] Successful sale decrements  
- [x] Void/refund restores per policy  
- [x] HQ can fix counts without code change  

---

**Cutover:** Inventory v1 gate **satisfied** for item-level tracking. Ingredient-graph 86 remains a future enhancement if managers require it.
