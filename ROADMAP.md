# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 18, 2026  
**Current focus**: **Catalog health v1 + POS ticket layout polish**  
**Active branch**: **`feat/pre-hardware-hq-polish`** · soft-release **`main`**

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
- **Salad profile** + HQ editor polish (2026-08-15 on main)
- **POS StarGraphic print + DK drawer** on lab TSP143 (2026-08-18)

---

## Active / next

| Epic | Status |
|------|--------|
| Soft release / burn-in | **Active** |
| Salad profile + HQ editor polish | **COMPLETE on main** (2026-08-15) |
| Catalog health v1 (Decision 15) | **Active** on `feat/pre-hardware-hq-polish` |
| POS print/drawer (TSP100 StarGraphic) | **DONE** 2026-08-18 |
| Storefront shell + Modern | **COMPLETE** |
| Inventory v1 | **COMPLETE** |
| Staff/labor v1 | **COMPLETE** |
| Home composition Wave 2 | **Deferred** |
| Promos / push / loyalty | **Growth — after soft stability** |
| POS hardware (lab TSP143) | **Print + drawer live**; Doughboys multi-printer at install |
| iOS port | **Delayed** (parallel when started) |
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
- Owners self-serve catalog integrity (Catalog health) with zero support for common fixes

## How to use

Agents: STATUS + HANDOFF + Decision 15 + `docs/slices/catalog-health-v1.md` + closed `docs/plans/*` + app READMEs.
