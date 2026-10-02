# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: October 1, 2026  
**Current focus**: Ordering customization normalize → merge polish to main  
**Active branch**: **`feat/pre-hardware-hq-polish`** · soft-release **`main`**

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.

## Not in this roadmap (post-MVP or non-product)

- **WeekTally** (`/tally` → Cloud Run `weektally`) — personal finance, not franchiseHQ
- **iOS**
- **Printer-by-category** (one TSP143 is the MVP printer)
- **Loyalty**
- **Custom domains**
- **Home composition Wave 2** — HQ homepage widget studio. Wave 1 shell is complete. See `docs/plans/home-page-composition-engine-v1.md`.

---

## Completed (high level)

- HQ, Admin, menu M1–M5, mobile tokens, Stripe Connect, POS software pilot
- customer_web + Modern storefront (Wave 1)
- Inventory v1 + Staff/labor v1
- Salad profile + HQ editor polish (2026-08-15 on main)
- POS StarGraphic print + DK drawer (2026-08-18)
- POS profile builders, cash tip close-out, EOD (2026-08-21 on polish branch)

---

## Active / next

| Epic | Status |
|------|--------|
| Ordering customization normalize | **Open** — `docs/slices/ordering-customization-normalize-v1.md` |
| Merge polish → main | **Open** — delivery callable not on main |
| Delivery range on mobile + POS | **Open** — web + HQ store_ops on polish |
| Catalog health phase C | **Open** |
| CF Node 22 | Before ~2026-10-30 |
| Stripe Terminal | Scheduled; not required unless reader must take counter cards |
| WeekTally / iOS / printer-by-category / loyalty / domains / Wave 2 | **Out of MVP** |

---

## Release model (Doughboys)

| Stage | Criteria |
|-------|----------|
| **Soft** | POS parallel; inventory + labor live |
| **Hard swap** | Manager accepts day-to-day ops; ordering customization matches across mobile, web, POS |
| **Growth** | Notifications, loyalty, upsells, Wave 2 studio, iOS |

## How to use

Agents: STATUS + HANDOFF + `docs/slices/ordering-customization-normalize-v1.md`. Ignore `/tally`.
