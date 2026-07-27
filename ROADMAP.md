# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: July 27, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + SSD)  
**Current focus**: Menu modifier system rebuild + Admin ops fixes (on `main`)

## Vision
Build a scalable, multi-tenant white-label Flutter platform that allows any restaurant/franchise to launch a fully branded ordering system (web + mobile) rapidly and cost-effectively.

---

## Completed (high level)

- Core ordering flow; shared_core + FranchiseProvider unification
- Phase 0 agent infra (Docker/Ollama/Orchestrator)
- Phase 1 franchise-scoped config + HQ Design & Branding + HQ onboarding host migration
- HQ foundation residual (orphan gate); Platform Owner MVP
- `feat/onboarding-4step` merged to **`main`** (July 27, 2026); Hosting deploy live

---

## Active epics (July 27, 2026)

### A. Menu modifier system rebuild (primary product architecture)
**Authority**: `docs/slices/menu-modifier-system-rebuild-v1.md`, Decision 10  
**Why**: Dual customization trees + mobile category heuristics will not support multi-type restaurants or clean Doughboys live MVP testing. **Full rebuild**, not patch-only.

Workstreams M1–M5: schema → migration → unified editors → mobile renderer → cutover.

### B. Admin dashboard ops fixes (narrow)
**Authority**: `docs/slices/admin-dashboard-ops-fixes-v1.md`  
**Why**: Smoke (July 27) found broken categories/promos/orders/franchise refresh and stub KPI. Explicitly **excludes** modifier redesign.

### C. Later
- Developer dashboard inventory
- Cloud Functions Node 22 before ~2026-10-30
- Post-MVP: Cash Flow / Multi-brand HQ cards; full Staff/Chat wiring; Inventory SKU link

---

## Phase map (original planning — status sense)

| Phase | Theme | Sense check |
|-------|--------|-------------|
| 0 | Agent infra & docs | Effectively complete |
| 1 | Config scoping & branding | Core delivered; ongoing polish |
| 2 | Hybrid location + dashboards | Partial; Platform/HQ advanced; Admin ops in flight |
| 3 | Mobile multi-tenant / dynamic UI | **Tied to menu modifier rebuild** |
| 4–5 | Monetization, onboarding polish, release | Stripe/plans exist in places; not closed |

---

## Success criteria for polished MVP (updated)

- Hybrid single/multi-location workable
- **Menu modifiers**: one schema; pizza profile for Doughboys; standard profile for other types
- Design management via HQ with live preview
- Admin day-2 ops trustworthy (categories, orders, promos)
- Strong human review on schema and payments

## Risk register (additions)

- Menu dual-tree / heuristic debt if rebuild is deferred
- Firestore menu migration mistakes on live Doughboys data
- Agent scope creep mixing Admin ops fixes with modifier rebuild

## How to use

- Agents: load STATUS + SCOPE_CARD + relevant slice; stay in slice scope
- Human merge gate remains mandatory for schema and cutover
