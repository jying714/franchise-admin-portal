# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: October 1, 2026  
**Current focus**: Ordering customization normalize on polish, then merge  
**Active branch**: **`main`** (soft-release) · work **`feat/pre-hardware-hq-polish`**

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.

## Not in this roadmap

- **WeekTally** (`/tally` → Cloud Run `weektally`) — personal finance, not franchiseHQ
- **iOS**
- **Printer-by-category**
- **Loyalty**
- **Custom domains**
- **Home composition Wave 2** — HQ homepage widget studio. Wave 1 shell is complete. See `docs/plans/home-page-composition-engine-v1.md`.

---

## Completed (high level)

- HQ, Admin, menu M1–M5, mobile tokens, Stripe Connect, POS software pilot
- customer_web order parity + storefront shell Wave 1
- **Modern storefront template** + polish
- HQ contact structured address; website hero + story photo upload
- **Inventory v1** — isSellable, channel 86, paid decrement, void restore
- **Staff/labor v1** — roster/PIN, schedule+print, POS clock, hours+timesheet
- **Station claims** — `stationFranchise`; clock-in gates + manager override

---

## Active / next

| Epic | Status |
|------|--------|
| Ordering customization normalize | **Open** — `docs/slices/ordering-customization-normalize-v1.md` |
| Merge polish → main | **Open** |
| Inventory v1 / Staff/labor v1 / Wave 1 shell | **COMPLETE** |
| Home composition Wave 2 | **Post-MVP** |
| Loyalty / custom domains / iOS / printer-by-category | **Post-MVP** |
| CF Node 22 | Before ~2026-10-30 |
| WeekTally | **Out of scope** |

---

## Release model (Doughboys)

| Stage | Criteria |
|-------|----------|
| **Soft** | POS parallel; inventory + labor live; optional Modern storefront |
| **Hard swap** | Manager accepts day-to-day ops; customization matches on mobile, web, and POS |
| **Growth** | Notifications, loyalty, upsells, Wave 2 studio, iOS |

---

## Success criteria

- Guests order on brand-capable web/mobile
- Counter runs FranchiseHQ POS as primary after burn-in
- Managers track stock and labor without Owner.com
- The same menu item customizes and prints the same way on mobile, customer web, and POS

## How to use

Agents: STATUS + HANDOFF + `docs/slices/ordering-customization-normalize-v1.md`. Ignore `/tally`.
