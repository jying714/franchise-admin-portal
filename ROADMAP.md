# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 4, 2026 (~23:30 CDT)  
**Current focus**: **MVP soft release / burn-in** — cutover gates implemented; harden claims + manager validation  
**Active branch**: **`main`**

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.  
Doughboys path: soft parallel → burn-in → hard swap when manager accepts ops.

---

## Completed (high level)

- HQ, Admin, menu M1–M5, mobile tokens, Stripe Connect, POS software pilot  
- customer_web order + customize parity + **storefront shell Wave 1**  
- HQ Restaurant settings (contact structured address, website hero/logo upload)  
- **Inventory v1** — shared `isSellable`, channel 86, paid decrement, void/refund restore  
- **Staff/labor v1** — Admin roster/PIN, schedule+print, POS clock, hours+timesheet print  

---

## Active / next

| Epic | Status |
|------|--------|
| Storefront shell Wave 1 | **COMPLETE** |
| Inventory v1 | **COMPLETE** |
| Staff/labor v1 | **COMPLETE** |
| MVP soft release / burn-in | **Active** |
| Station `stationFranchise` claims | **Residual hardening** |
| Home composition engine Wave 2 | **Deferred** |
| Promos / push / loyalty / upsells | **Growth — after soft stability** |
| POS hardware / iOS | **Waiting on devices** |
| Custom domains | **Open** |
| CF Node 22 | Before ~2026-10-30 |

---

## Release model (Doughboys)

| Stage | Criteria |
|-------|----------|
| **Soft** | POS parallel with Owner.com; order path live; inventory + labor **available** for burn-in |
| **Hard swap** | Manager accepts inventory + labor day-to-day; stable POS; claims/rules production-clean |
| **Growth** | Notifications, loyalty, upsells, home studio |

---

## Success criteria

- Guests order on brand-capable web/mobile  
- Counter runs FranchiseHQ POS as primary after burn-in  
- Managers track **stock at zero** and **who worked** without Owner.com  

## How to use

Agents: STATUS + HANDOFF + closed `docs/plans/mvp-ops-*.md` + storefront Wave 1 plan.
