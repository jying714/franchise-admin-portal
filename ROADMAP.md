# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 3, 2026 (~00:45 CDT)  
**Current focus**: Parallel **guest shell Wave 1** + **MVP-Ops** (inventory → staff/labor) for Owner.com hard cutover  
**Active branch**: **`main`**

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.  
Doughboys path: soft parallel → fix → hard swap when ops gates met.

---

## Completed (high level)

- HQ, Admin, menu M1–M5, mobile tokens, Stripe Connect, POS software pilot  
- customer_web order + customize parity  
- HQ Restaurant settings  
- Docs: storefront Wave 1/2, MVP-Ops inventory + staff/labor  

---

## Active / next

| Epic | Status |
|------|--------|
| Storefront shell Wave 1 | **Locked — next guest** |
| Inventory v1 | **Locked plan — cutover gate** |
| Staff/labor v1 (schedule, clock, hours, print) | **Locked plan — cutover gate, greenfield** |
| Home composition engine Wave 2 | **Deferred** |
| Promos / push / loyalty / upsells | **Growth — after soft stability** |
| POS hardware / iOS | **Waiting on devices** |
| Custom domains | **Open** |
| CF Node 22 | Before ~2026-10-30 |

---

## Release model (Doughboys)

| Stage | Criteria |
|-------|----------|
| **Soft** | POS parallel with Owner.com; order path live; inventory/labor may be partial |
| **Hard swap** | Inventory v1 + staff/labor v1 (incl. clock + hours + print) + stable POS |
| **Growth** | Notifications, loyalty, upsells, home studio |

---

## Success criteria

- Guests order on brand-capable web/mobile  
- Counter runs FranchiseHQ POS as primary after burn-in  
- Managers track **stock at zero** and **who worked** without Owner.com  

## How to use

Agents: STATUS + HANDOFF + `docs/plans/mvp-ops-*.md` + storefront plans.
