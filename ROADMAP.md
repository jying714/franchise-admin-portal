# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 6, 2026 (~20:40 CDT)  
**Current focus**: **Manager burn-in / soft release**  
**Active branch**: **`main`**

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.

---

## Completed (high level)

- HQ, Admin, menu M1–M5, mobile tokens, Stripe Connect, POS software pilot  
- customer_web order parity + storefront shell Wave 1  
- **Modern storefront template** + **polish** (side-sheet cart, branded menu/cart, story band, HQ picker/uploads)  
- HQ contact structured address; website hero + story photo upload  
- **Inventory v1** — isSellable, channel 86, paid decrement, void restore  
- **Staff/labor v1** — roster/PIN, schedule+print, POS clock, hours+timesheet  
- **Station claims** — `stationFranchise`; clock-in gates + manager override  

---

## Active / next

| Epic | Status |
|------|--------|
| Soft release / burn-in | **Active** |
| Storefront shell + Modern | **COMPLETE** |
| Inventory v1 | **COMPLETE** |
| Staff/labor v1 | **COMPLETE** |
| Home composition Wave 2 | **Deferred** |
| Promos / push / loyalty | **Growth — after soft stability** |
| POS hardware / iOS | **Waiting on devices** |
| Custom domains | **Open** |
| CF Node 22 | Before ~2026-10-30 |

---

## Release model (Doughboys)

| Stage | Criteria |
|-------|----------|
| **Soft** | POS parallel; inventory + labor live; optional Modern storefront |
| **Hard swap** | Manager accepts day-to-day ops; stable parallel |
| **Growth** | Notifications, loyalty, upsells, home studio |

---

## Success criteria

- Guests order on brand-capable web/mobile  
- Counter runs FranchiseHQ POS as primary after burn-in  
- Managers track stock and labor without Owner.com  

## How to use

Agents: STATUS + HANDOFF + closed `docs/plans/*` + app READMEs.
