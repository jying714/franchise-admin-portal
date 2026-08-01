# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 1, 2026 (~09:40 CDT)  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + SSD)  
**Current focus**: Thin POS Station App (`pos_app`) — Decision 14 residual → polished MVP  
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
- **POS Phases 0–4** shell, board, carry-out
- **POS Phase 5 pilot money** — tax/discount stack, cash/split, card PaymentSheet
- **POS closed board + refund skeleton**
- **POS print mocks** (kitchen + receipt)
- **POS dine-in / delivery ops** (baseline)
- **Online intake MVP** — mobile in-hours → kitchen + station auto ticket; outside-hours block

---

## Active epic — Thin POS (Decision 14)

**Authority**: `docs/slices/pos-app-v1.md`, `docs/plans/pos-app-v1-development-plan.md`, STATUS residual list

| Milestone | Phases | Target | Status |
|-----------|--------|--------|--------|
| pos-m1-shell | 1–2 | Domain + PIN session | **Reached** |
| pos-m2-carryout-pay | 3–5 | Board + carry-out + payments | **Reached (pilot software)** — Terminal optional residual |
| pos-m3-dine-in | 6 | Tables + open ticket | **Reached (ops)** — polish residual |
| pos-m4-delivery-staff | 7–8 | Delivery + staff records UI | **Partial** — delivery ops yes; staff UI open |
| pos-m5-ops-print | 9–11 | 86, large order, print, online intake | **Partial** — mock print + online intake yes; 86/large open |
| pos-m6-mvp | 12–14 | Settings UI, offline, pilot QA | **Open** |

**Now:** residual config (tax, hours), settings, offline, then website / hardware.

---

## After POS polished MVP

- Customer website (hard release gate)
- Pilot polish on production hardware (Terminal, ESC-POS)
- CF Node 22 before ~2026-10-30
- Post-MVP: scheduled orders, guest cart, live delivery tracking, complex inventory, etc.

---

## Phase map (status sense)

| Phase | Theme | Sense check |
|-------|--------|-------------|
| 0–1 | Infra, config, branding | Delivered |
| 2–3 | Dashboards, mobile multi-tenant | Delivered |
| 4 | Stripe Connect customer path | Delivered |
| 5 | Station + website + pilot | **POS pilot strong; website not started; config residual** |

---

## Success criteria (polished MVP product)

- Hybrid location + menu profiles + HQ branding
- Customer bind + auth-gated cart + Connect card path
- Residual mobile/web polish landed
- **Thin POS at counter** — money + mock/real print + online intake per residual list
- **Customer website** at MVP quality
- Human merge gate on schema and payments

## How to use

- Agents: load STATUS + plan + slice; stay in residual list  
- Human merge gate mandatory for schema, payments, POS cutover  
