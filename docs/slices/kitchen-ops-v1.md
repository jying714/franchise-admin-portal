# Slice: Kitchen Ops v1

**Status**: **Locked** (product approved July 29, 2026 — implementation open)  
**Branch**: TBD (`feat/kitchen-ops-v1` when work starts)  
**Authority**: Decision **13** · STATUS · HANDOFF · this file  
**Depends on**: Franchise-scoped orders; Stripe card path (Decision 12) for `paid` feed; Admin feature-toggle patterns  
**Pilot device**: **Android** kitchen tablet; Flutter multi-platform codebase retained

---

## 1. Problem

MVP is **not** a full POS. Kitchen still needs:

- Safe order board for **cooks** (no full Admin blast radius)
- **Automatic** ticket printing to the right station printer(s)
- Optional **cash on pickup** without confusing prepaid vs unpaid food
- Manager visibility when the tablet or printer fails

---

## 2. Product locks

### Thin Kitchen Flutter app

| In | Out |
|----|-----|
| Franchise-locked live orders | Menu / promo / user admin |
| Forward status (accept / in progress / ready / complete — exact enum at implement) | Free franchise switching on device |
| Reprint | Design & Branding, Stripe Connect setup |
| Connectivity / printer health signal | Cook-initiated void/refund |

**Void / cancel / refund:** **manager-only** (PIN, manager role session, or Admin on manager device — implementation choice).

### Admin feature cards (franchise-scoped)

| Toggle | Behavior |
|--------|----------|
| **Cash on pickup** (master) | Customer may choose cash at checkout; board/ticket show PAY CASH |
| **Require accept before cash print** (sub; only if master on) | OFF (default): print cash on **submit**. ON: print after cook **Accept** |
| Other feature cards (e.g. Inventory) | Independent; same Admin feature area |

### Print rules

| Pay path | When to auto-print |
|----------|---------------------|
| Card (Connect) | On **`paid`** |
| Cash, sub-toggle OFF | On **submit** |
| Cash, sub-toggle ON | On cook **Accept** |

- **Multi-printer:** `categoryId` → printer id(s); multiple categories per printer; default printer for unmapped.
- Prefer **Ethernet ESC-POS**; print idempotent per order/station (`printedAt` / print job records).
- Local LAN print path (agent and/or tablet SDK) — cloud does not open sockets to in-store printers through NAT.

### Manager alerts

- Heartbeat from kitchen station / print path.
- On offline or print failure → **push + SMS** to franchise assigned manager user(s).

### Hardware pilot

- **Android tablet** at make line (DoorDash-like).
- Printer beside tablet; Ethernet ESC-POS preferred.
- iOS kitchen station **post-pilot** unless explicitly scheduled.

---

## 3. Workstreams

| ID | Deliverable | Status |
|----|-------------|--------|
| **K0** | Docs lock (this file + Decision 13) | **Done** |
| **K1** | Admin feature toggles: cashOnPickup + cashPrintOnAcceptOnly | Open |
| **K2** | Franchise printer config + category routing | Open |
| **K3** | Thin Kitchen app shell: auth, franchise lock, order stream UI | Open |
| **K4** | Status actions (cook) + manager-only void/cancel/refund gates | Open |
| **K5** | Auto-print pipeline + idempotency (paid / cash rules) | Open |
| **K6** | Heartbeat + manager push/SMS on failure | Open |
| **K7** | Customer checkout: cash option when flag on; PAY CASH honesty | Open |
| **K8** | Android pilot smoke (real + test orders) | Open |
| **K9** | Acceptance + STATUS close | Open |

---

## 4. Acceptance (implementation)

- [ ] Cooks cannot reach full Admin features from Kitchen app
- [ ] Manager can void/cancel/refund; cook cannot
- [ ] Cash toggle off → no cash option in customer checkout
- [ ] Cash toggle on → cash path + clear PAY CASH on board/ticket
- [ ] Sub-toggle changes cash print timing (submit vs accept)
- [ ] Card paid → auto-print
- [ ] Multi-printer category routing + default fallback
- [ ] Reprint does not create unbounded duplicates without control
- [ ] Manager notified on tablet offline / print error
- [ ] Android tablet pilot path documented

---

## 5. Out of scope

- Full POS, cash drawer, card-present terminal suite  
- Geo, guest pay, marketplace logistics  
- Replacing Decision 11/12  
- iOS kitchen kiosk certification  

---

## 6. Sequencing note

Prefer **Stripe card paid orders** feeding the board for happy-path QA; cash flags can land with checkout. Kitchen UI may develop against seeded/test orders in parallel.

---

## 7. Bottom line

**Thin Kitchen Flutter app** for cooks; **Admin toggles** for cash and cash-print policy; **multi-printer by category**; **auto-print** with clear card vs cash rules; **manager-only** destructive money actions; **Android** pilot tablet with multi-platform code retained.
