# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: July 19, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + 1TB SSD)
**Current Phase**: Preparing for P3 – Advanced Features & Production Readiness

## Vision
Build a scalable, multi-tenant white-label Flutter platform that allows any restaurant/franchise to launch a fully branded ordering system (web + mobile) rapidly and cost-effectively. Use AI-accelerated development and shared architecture to undercut competitors.

---

## Completed Phases

**P1 – Core Ordering Flow Stabilization** (Completed May 2026)  
**P2 – White-Label & Scalability** (Completed June 2026)  
**P2.5 – Web-App Cleanup Sprint** (Completed June 06, 2026)

### Key Achievements
- Auth handoff and persistent spinner resolved
- FranchiseProvider + shared_core unification complete
- Large-scale cleanup of duplicated code, models, and UI issues
- `hq_owner` dashboard functional with correct franchise resolution
- Core ordering flow stable on Samsung S25

---

## Current & Upcoming Phases

### Phase 0: Infrastructure & Documentation (2–4 days, upon hardware arrival)
**Goals**: New MINISFORUM AI X1 Pro-470 ready, agents configured, docs current.

**Tasks**:
- Set up Docker multi-agent environment + Ollama
- Expand all core docs (ARCHITECTURE.md, DASHBOARDS.md, MOBILE_DYNAMIC.md, etc.)
- Create agent prompt files and docker-compose
- Git workflow with AI commit notes

### Phase 1: Core Config Scoping & Dynamic Branding (4–6 days)
**Goals**: Fully franchise-scoped and dynamic configs.

**Key Deliverables**:
- Design tokens, app_config, branding_config, feature_config, ui_config in shared_core
- Runtime theming/branding system
- Design & Branding page in HQ Owner dashboard (with live preview)

### Phase 2: Hybrid Single/Multi-Location + Dashboards (6–8 days)
**Goals**: Full hybrid support.

**Key Deliverables**:
- Automatic UI simplification for single-location
- Location switching on mobile and web
- Primary/secondary location rules
- Role-based dashboard navigation

### Phase 3: Mobile Multi-Tenant Polish & Roles (5–7 days)
**Goals**: Fully dynamic mobile app.

**Key Deliverables**:
- Remove pizzeria hardcoding → config-driven UI for any restaurant type
- Deep linking, invite flows, offline support
- Granular staff roles and invitations
- iOS testing on iPhone 15

### Phase 4: Monetization, Analytics & Polish (5–7 days)
**Goals**: Revenue-ready.

**Key Deliverables**:
- Stripe integration + tiered plans (Starter, Starter Advanced, Growth)
- Analytics dashboards + CSV/PDF exports
- Feature gating
- Error management in Developer dashboard

### Phase 5: Assisted Onboarding, POS Prep, Legal & Release (4–6 days)
**Goals**: Launch-ready.

**Key Deliverables**:
- AI-assisted onboarding flows
- Printer/terminal abstractions for future POS
- Basic ToS/Privacy Policy
- Final testing and App Store readiness

---

## Post-MVP Phases (High-Level)
**P4 – Scale & Marketplace** (Q3 2026)  
**P5 – Enterprise & Expansion** (Q4 2026+)

## Success Criteria for Polished MVP
- Hybrid single/multi-location works seamlessly
- Mobile UI fully dynamic across restaurant types
- Design management via HQ Owner dashboard with live preview
- Stripe payments and feature gating functional
- Clean, well-documented architecture with human-readable code

## How to Use This Roadmap
- Reference this file for current priorities
- All work aligns with the active phase
- Major updates will be reflected here and in `comprehensive-project-analysis.md`