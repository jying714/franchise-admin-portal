# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: July 30, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + SSD)  
**Current focus**: Thin POS Station App (`pos_app`) — Decision 14

## Vision
Build a scalable, multi-tenant white-label Flutter platform that allows any restaurant/franchise to launch a fully branded ordering system (web + mobile + counter station) rapidly and cost-effectively.

---

## Completed (high level)

- Core ordering flow; shared_core + FranchiseProvider unification
- Phase 0 agent infra (Docker/Ollama/Orchestrator)
- Phase 1 franchise-scoped config + HQ Design & Branding + HQ onboarding host migration
- HQ foundation residual; Platform Owner MVP; Admin ops v1
- Menu modifier system rebuild M1–M5 + wings/calzone — `main`
- Mobile Design Tokens v1 (T1–T9) — `main`
- Developer Dashboard v1 — `main`
- Customer franchise context v1 (Decision 11) — `main`
- Stripe checkout v1 Connect path (Decision 12) — `main`
- Mobile + web residual design-tokens polish — `main` (July 30, 2026)

---

## Active epic (July 30, 2026)

### Thin POS Station App (`pos_app`) — primary
**Authority**: `docs/slices/pos-app-v1.md`, Decision 14  
**Branch**: `feat/pos-app-v1`  
**Why**: Counter station is required for a market-viable product; pure kitchen-only app is superseded.

Workstreams P1–P13: shell/PIN → staff records → table map → order entry → payments → 86/allergens → print → online intake → settings → offline → pilot smoke.

### Later (release gate + post)

- Customer website (hard release gate alongside thin POS)
- Pilot polish on Android tablet + printers + drawer + card-present
- Cloud Functions Node 22 before ~2026-10-30
- Post-MVP: Cash Flow / Multi-brand full product; guest cart; live delivery tracking; complex inventory

---

## Phase map (status sense)

| Phase | Theme | Sense check |
|-------|--------|-------------|
| 0 | Agent infra & docs | Complete |
| 1 | Config scoping & branding | Delivered |
| 2 | Hybrid location + dashboards | Core delivered |
| 3 | Mobile multi-tenant / dynamic UI | Delivered (Decision 11 + tokens) |
| 4 | Monetization (Stripe) | Card path delivered (Decision 12) |
| 5 | Station + website + pilot release | **In progress — POS first** |

---

## Success criteria for polished MVP (updated)

- Hybrid single/multi-location workable
- Menu modifiers: one schema; pizza/wings/calzone profiles
- Design management via HQ with live preview
- Admin day-2 ops trustworthy
- Customer bind + signed-out browse + auth-gated cart/checkout
- Card checkout via Connect (test mode proven)
- Customer mobile + web management residual polish landed
- **Thin POS at counter** (card + cash + drawer + tables + print)
- **Customer website** at MVP quality
- Strong human review on schema and payments

## Risk register

- POS scope creep beyond Decision 14 locks
- Printer / drawer hardware variance at pilot
- Customer website deferred too late relative to release gate
- Agent inventing kitchen-only binary or new DesignTokens fields

## How to use

- Agents: load STATUS + SCOPE_CARD + relevant slice; stay in slice scope
- Human merge gate remains mandatory for schema, payments, and POS cutover
