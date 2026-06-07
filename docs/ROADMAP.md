# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: June 06, 2026  
**Current Phase**: P2.5 Web-App Cleanup Sprint — **COMPLETE**

---

## Vision
Build a scalable, multi-tenant white-label Flutter platform that allows any restaurant/franchise to launch a fully branded ordering system (web + mobile) rapidly and cost-effectively, significantly undercutting competitors through AI-accelerated development and shared architecture.

---

## Completed Phases

### P1 – Core Ordering Flow Stabilization (Completed May 2026)
- Shared core migration and model consolidation
- End-to-end customer ordering flow (menu → customization → cart → checkout)
- Franchise scoping foundations

### P2 – White-Label & Scalability (Completed June 2026)
- Dynamic theming and branding system
- QR code scanner + deep linking
- Multi-tenant Firebase hardening

### P2.5 – Web-App Cleanup Sprint (May 30 – June 06, 2026) — **COMPLETE**
- Persistent login spinner and auth handoff resolved
- Provider synchronization (`AdminUserProvider` + `FranchiseProvider`)
- Large-scale surgical cleanup of widgets, type issues, and overflows
- `hq_owner` dashboard fully functional with correct franchise resolution
- Firestore security rules refined

---

## Current & Upcoming Phases

### P3 – Advanced Features & Production Readiness (June – July 2026)
**Target Completion**: Mid-July 2026

#### Core Deliverables
- Real payment gateway integration + webhooks (Stripe)
- Full white-label onboarding flow for new franchises
- Advanced analytics dashboard
- Subscription & billing management (invoices, payouts, dunning)
- Multi-location support
- Scheduled orders
- Staff management & permissions system
- Comprehensive test suite + CI/CD pipeline
- Firebase security rules final hardening
- App Store & Play Store readiness (icons, screenshots, privacy policy, etc.)

#### Success Criteria
- Zero permission-denied errors on dashboard cards
- Production build passes on Samsung S25 and Chrome
- Successful end-to-end test of new franchise onboarding

---

### P4 – Scale & Marketplace (Q3 2026)
- Public marketplace for franchise owners to discover and subscribe
- Automated onboarding wizard with AI assistance
- Advanced loyalty & marketing tools
- Mobile app publishing automation
- Performance monitoring & crash analytics

### P5 – Enterprise & Expansion (Q4 2026+)
- Multi-brand support
- Internationalization & multi-currency
- White-label mobile app publishing service
- Partner integrations (POS systems, delivery services)
- SaaS subscription tiers and usage-based billing

---

## Long-Term Vision (2027+)
- Become the leading white-label platform for independent restaurants and small-to-medium franchise chains
- Expand beyond food service into other verticals
- Open-source selected non-sensitive components
- Build a thriving ecosystem of templates and extensions

---

## How to Use This Roadmap
- Check this file regularly for current priorities.
- All new work should align with the active phase.
- Major milestones will be updated in `comprehensive-project-analysis.md`.

---

**This document is the official public roadmap and should be referenced in all planning discussions.**

*Maintained by Grok Project Manager*