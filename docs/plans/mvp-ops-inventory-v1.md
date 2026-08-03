# MVP-Ops Inventory v1 — Owner.com cutover gate

**Status:** **Locked for planning** (2026-08-03) — required before **hard** swap off Owner.com  
**Authority:** STATUS · HANDOFF · Doughboys operator requirement · this plan  
**Scope:** Franchise-scoped quantity tracking when inventory is enabled; 86 at zero across channels

---

## 1. Problem

Managers will not run the restaurant solely on FranchiseHQ without knowing **what is left** and **not selling zero**. Soft parallel with Owner.com can tolerate gaps; **permanent cutover cannot**.

Existing code has partial models/stubs; **end-to-end ledger + channel 86 is not done**.

---

## 2. Product minimum (v1)

| Rule | Behavior |
|------|----------|
| Opt-in tracking | Only entities with **inventory enabled** |
| Trackable entities | **Menu items** and/or **ingredients** (both supported) |
| Quantity | Numeric on-hand count per franchise entity |
| Zero menu item | **Disable / hide** that item on web, mobile, POS |
| Zero ingredient | **86 menu items** that **require** that ingredient (included / recipe-required — not every optional add-on unless flagged required) |
| Adjustments | HQ (and optionally POS) manual set / receive / waste / recount |
| Sales | Decrement on a **single defined** success moment (recommend: paid / tender complete) |
| Voids / refunds | Restore quantity when line is voided/refunded per policy |

**Non-goals v1:** vendor POs, multi-warehouse, recipe yield math, theoretical vs actual variance reports, barcode receiving.

---

## 3. Locks

| ID | Lock |
|----|------|
| I1 | One **franchise-scoped** on-hand source of truth |
| I2 | Untracked entities never block sales |
| I3 | Tracked at 0 → not sellable on **all** order channels |
| I4 | Decrement once per sold unit (no double-count web+POS) |
| I5 | HQ can enable flag + edit qty without deploy |
| I6 | POS can 86 / adjust if product allows; must not diverge ledger |

---

## 4. Platform matrix

| Surface | v1 responsibility |
|---------|-------------------|
| **HQ / Admin** | Enable inventory, set qty, adjustments, list low/zero |
| **Shared core / CF** | Read/write ledger; optional atomic decrement |
| **POS** | Respect 86; post usage on tender; void restore |
| **customer_web** | Hide/disable zero items (and options if required ingredient) |
| **mobile_app** | Same as web |

---

## 5. Work breakdown (high level)

| # | Task |
|---|------|
| INV.1 | Confirm/extend schema: `inventoryEnabled`, `onHand` (item and/or ingredient) |
| INV.2 | HQ UI: toggle + qty + adjust reasons |
| INV.3 | Service: getOnHand, adjust, tryDecrement, restore |
| INV.4 | Hook order paid / POS tender → decrement |
| INV.5 | Hook void/refund → restore |
| INV.6 | Menu queries filter or mark unavailable at 0 |
| INV.7 | Smoke: item→0→hidden all channels; adjust back→visible |

---

## 6. Acceptance

- [ ] Enabled menu item at 0 not orderable on web, mobile, POS  
- [ ] Enabled ingredient at 0 86s dependent items  
- [ ] Successful sale decrements exactly once  
- [ ] Void/refund restores per policy  
- [ ] HQ can fix counts without code change  

---

**Cutover:** Inventory v1 is a **hard Owner.com swap gate** (with staff/labor plan).
