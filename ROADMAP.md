# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 3, 2026 (~00:25 CDT)  
**Current focus**: customer_web **Storefront shell Wave 1** (nested UX + widgetized home)  
**Active branch**: **`main`** · next feature: `feat/customer-web-storefront-shell-v1`

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.  
Public storefront: order-capable **and** brandable homepage via a **composition engine** (web first; mobile later).

---

## Completed (high level)

- HQ onboarding, branding, Platform Owner, Admin ops, menu M1–M5
- Mobile Design Tokens; Developer Dashboard
- Customer franchise context (11); Stripe Connect (12); thin POS software (14)
- HQ Restaurant settings v1
- customer_web MVP + **parity core** (customize, cart, checkout delivery)

---

## Active / next

| Epic | Status |
|------|--------|
| customer_web parity core | **Done on main** |
| **Storefront shell Wave 1** (shell, nested flow, section home) | **Locked — next** |
| **Home composition engine Wave 2** (HQ studio, widget CRUD) | **Deferred (docs locked)** |
| Composition on **mobile** home | **Post-MVP** (shared schema, mobile renderer) |
| Homepage **templates** | **Post-MVP** |
| Promos / directory / loyalty | **Open** |
| Custom domains | **Open** (optional) |
| POS Terminal / printers · iOS port | **Waiting on hardware / Mac** |
| CF Node 22 | Before ~2026-10-30 |

---

## Customer website milestones

| Milestone | Status |
|-----------|--------|
| Order path + customize parity on main | **Reached** |
| Persistent shell + in-panel menu→checkout | **Next (Wave 1)** |
| Widgetized marketing home | **Next (Wave 1)** |
| HQ add/remove/reorder + live preview | **Deferred (Wave 2)** |
| Templates + mobile composition | **Post-MVP** |
| Custom domains | **Open** |

---

## Success criteria

- Order + customize + pay on web and mobile; POS software baseline  
- Storefront feels like a **restaurant site** (Wave 1), not a thin admin skin  
- Owners later compose home from a **safe widget catalog** (Wave 2) without breaking platform quality  

## How to use

Agents: STATUS + HANDOFF + plan docs under `docs/plans/`.
