# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 21, 2026  
**Current focus**: Idle-timer fix → delivery range v1 → merge polish branch  
**Active branch**: **`feat/pre-hardware-hq-polish`** · soft-release **`main`**

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.

---

## Completed (high level)

- HQ, Admin, menu M1–M5, mobile tokens, Stripe Connect, POS software pilot  
- customer_web + Modern storefront  
- Inventory v1 + Staff/labor v1  
- Salad profile + HQ editor polish (2026-08-15 on main)  
- POS StarGraphic print + DK drawer (2026-08-18)  
- POS profile builders, cash tip close-out, EOD (2026-08-21 on polish branch)

---

## Active / next

| Epic | Status |
|------|--------|
| Soft release / burn-in | **Active** |
| Catalog health v1 (Decision 15) | **Active** on polish branch |
| POS print/drawer (TSP100) | **DONE** 2026-08-18 |
| POS station UX (builders / tips / EOD) | **On branch** — idle timer **open** |
| Delivery range (distance or drive time) | **Next** — shared `store_ops` |
| Stripe Terminal | Scheduled |
| iOS port | **Delayed** |
| CF Node 22 | Before ~2026-10-30 |

---

## Release model (Doughboys)

| Stage | Criteria |
|-------|----------|
| **Soft** | POS parallel; inventory + labor live |
| **Hard swap** | Manager accepts day-to-day ops |
| **Growth** | Notifications, loyalty, upsells |

## How to use

Agents: STATUS + HANDOFF + Decision 15 + `docs/slices/pos-app-v1.md` + `docs/slices/catalog-health-v1.md`.
