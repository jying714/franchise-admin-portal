# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 2, 2026 (~09:15 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + SSD)  
**Current focus**: Customer website vertical slice complete on feature branch; merge + residuals  
**Active branch**: `feat/customer-website-v1`  
**Plan**: `docs/plans/pos-app-v1-development-plan.md` (POS pilot complete) · `docs/slices/customer-website-v1.md`

## Vision

Build a scalable, multi-tenant white-label Flutter platform that allows any restaurant/franchise to launch a fully branded ordering system (web + mobile + counter station) rapidly and cost-effectively.

---

## Completed (high level)

- Core ordering; shared_core; HQ onboarding + Design & Branding
- Menu modifier rebuild M1–M5 + wings/calzone
- Mobile Design Tokens v1; Developer Dashboard v1
- Customer franchise context v1 (Decision 11)
- Stripe checkout v1 Connect path (Decision 12)
- Mobile + web residual design-tokens polish
- **Thin POS software pilot (Decision 14)** — on `main` 2026-08-01
- **Customer website vertical slice** — bind, menu, auth, cart, Connect pay, Hosting, HQ QR — `feat/customer-website-v1` 2026-08-02

---

## Active / next epics

| Epic | Status |
|------|--------|
| Thin POS software pilot | **COMPLETE on main** |
| Customer website vertical slice | **PASS on feat/customer-website-v1** (merge when gated) |
| Customer website residuals | Phase 4b cart modifiers; optional custom domains |
| Stripe Terminal / real printers | Open (hardware) |
| Staff/driver UI, 86, large-order | Open |
| CF Node 22 | Before ~2026-10-30 |

---

## POS milestones

| Milestone | Status |
|-----------|--------|
| pos-m1-shell | **Reached** |
| pos-m2-carryout-pay | **Reached** (software) |
| pos-m3-dine-in | **Reached** (ops) |
| pos-m4-delivery-staff | **Partial** (delivery ops; staff UI open) |
| pos-m5-ops-print | **Partial** (mock print + online intake; 86 open) |
| pos-m6-mvp software residual | **Reached** (settings + offline + store_ops + smoke) |

---

## Customer website milestones

| Milestone | Status |
|-----------|--------|
| Scaffold + shared_core + Firebase | **Reached** |
| `/f/{id}` bind + branding + menu | **Reached** |
| Auth + cart + Connect checkout | **Reached** |
| Hosting `storefront` + path/QR bind | **Reached** |
| HQ copy / open / QR card | **Reached** |
| Merge to main | **Open** (human gate) |
| Phase 4b modifiers on cart line | **Open** |
| Custom domains | **Open** (optional) |

---

## Success criteria (polished product hard release)

- Hybrid location + menu profiles + HQ branding
- Customer bind + auth-gated cart + Connect card path
- **Thin POS at counter** — software pilot **done**; Terminal/print hardware optional residual
- **Customer website** at MVP quality — **vertical slice done**; merge + residuals to close hard release
- Human merge gate on schema and payments

## How to use

- Agents: load STATUS + plan + slice; do not invent kitchen-only app  
- Human merge gate mandatory for schema, payments, website cutover  
