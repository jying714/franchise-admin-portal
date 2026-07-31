# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: July 30, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + SSD)  
**Current focus**: Thin POS Station App (`pos_app`) — Decision 14  
**Active branch**: `feat/pos-app-v1`  
**Plan**: `docs/plans/pos-app-v1-development-plan.md`

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
- **pos_app scaffold + feature directory tree (Phase 0 PASS)**

---

## Active epic — Thin POS (Decision 14)

**Authority**: `docs/slices/pos-app-v1.md`, `docs/plans/pos-app-v1-development-plan.md`

| Milestone | Phases | Target |
|-----------|--------|--------|
| pos-m1-shell | 1–2 | Domain + PIN session |
| pos-m2-carryout-pay | 3–5 | Board + carry-out + payments |
| pos-m3-dine-in | 6 | Tables + open ticket |
| pos-m4-delivery-staff | 7–8 | Delivery + staff records |
| pos-m5-ops-print | 9–11 | 86, large order, print, online intake |
| pos-m6-mvp | 12–14 | Settings, offline, pilot QA |

**Now:** Phase 1 (shared_core foundation).

---

## After POS polished MVP

- Customer website (hard release gate)
- Pilot polish on production hardware
- CF Node 22 before ~2026-10-30
- Post-MVP: guest cart, live delivery tracking, complex inventory, etc.

---

## Phase map (status sense)

| Phase | Theme | Sense check |
|-------|--------|-------------|
| 0–1 | Infra, config, branding | Delivered |
| 2–3 | Dashboards, mobile multi-tenant | Delivered |
| 4 | Stripe | Delivered |
| 5 | Station + website + pilot | **POS in progress** |

---

## Success criteria (polished MVP product)

- Hybrid location + menu profiles + HQ branding
- Customer bind + auth-gated cart + Connect card path
- Residual mobile/web polish landed
- **Thin POS at counter** (card + cash + drawer + tables + print) per plan acceptance
- **Customer website** at MVP quality
- Human merge gate on schema and payments

## How to use

- Agents: load STATUS + plan + slice; stay in current phase  
- Human merge gate mandatory for schema, payments, POS cutover  
