# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 29, 2026 (Decisions 11–12 — customer multi-franchise + Stripe Connect)

This file records major architectural and design decisions for the Doughboys Pizzeria Franchise Platform.

## Decision Log

### 1. Hybrid Single/Multi-Location Support
**Date**: July 2026  
**Status**: Approved  
**Decision**: Implement hybrid mode where single-location users see simplified UI but retain full management power. Multi-location users see franchise-level tools. Seamless upgrade path.  
**Rationale**: Matches predominant customer base (single owners) while future-proofing for franchises.  
**Impact**: Affects UI, providers, Firestore queries, and dashboards.  
**Note (July 29):** Decision 1 is primarily **ops/HQ** hybrid location tooling. **Customer** multi-tenant selection is Decision **11** (session-scoped franchiseId, directory + links).

### 2. Unified Config System in shared_core + Firestore
**Date**: July 2026  
**Status**: Approved  
**Decision**: Consolidate all config files into `shared_core` as the single source of truth. Franchise-scoped and dynamic via Firestore (`franchises/{franchiseId}/config/*`).  
**Rationale**: Eliminates duplication between web and mobile. Enables self-service branding and white-labeling.  
**Reference**: `/docs/architecture/firestore-per-franchise-config.md`

### 3. Design & Branding Management
**Date**: July 2026  
**Status**: Approved (refined by Decision 8)  
**Decision**: Dedicated page in HQ Owner dashboard with live preview. Franchise-scoped in Firestore.  
**See also**: Decision 8 for v1 / v1.1 delivery.

### 4. Mobile App Dynamic UI
**Date**: July 2026  
**Status**: Approved (executed via Decision 10)  
**Decision**: Config-driven UI based on restaurant type / menu profiles, configs, and FeatureGate. One published binary.  
**Impact**: Menu modifier rebuild complete on `main` (M1–M5 + wings/calzone).

### 5. Multi-Agent Development Approach
**Date**: July 2026  
**Status**: Approved  
**Decision**: Docker + local LLMs on MINISFORUM AI X1 Pro-470 for specialized agents with strict human review.

### 6. Dashboard Roles
**Date**: July 2026  
**Status**: Approved  
**Decision**: Four dashboards (Platform Owner, HQ Owner, Admin/Staff, Developer) with clear separation and role switching.  
**Reference**: `docs/DASHBOARDS.md`.

### 7. Onboarding Home = HQ Owner Dashboard (not Admin)
**Date**: July 24–25, 2026  
**Status**: **Implemented**  
**Decision**: Franchise/menu onboarding belongs on the **HQ Owner** dashboard. Admin is day-2 ops.  
**Progress path:** `franchises/{id}/onboarding_progress/progress`

### 8. HQ Design & Branding v1 / v1.1
**Date**: July 24–25, 2026  
**Status**: **Complete**  
**Decision**: Live Branding Preview; Save merges branding keys to franchise + `config/ui_config`. HQ seeds only for mobile tokens (Decision via mobile-design-tokens-v1).

### 9. Admin Menu vs HQ Menu Items (surface split)
**Date**: July 27–28, 2026  
**Status**: **Approved + implemented**  
**Decision**: HQ Menu Items = guided onboarding; Admin Menu = day-2 ops; **one** schema after Decision 10.

### 10. Menu Modifier System — Full Rebuild
**Date**: July 27–28, 2026  
**Status**: **Complete on `main`** (M1–M5 + wings/calzone W0–W7 + W2)  
**Decision**: Canonical `menuProfile` + `modifierGroups`; no dual production trees; Cook/Cut/Crust label-only; wings pool + calzone profile.  
**Reference**: `docs/slices/menu-modifier-system-rebuild-v1.md`, `docs/slices/hq-wings-calzone-v1.md`.

### 11. Customer App — Hybrid Multi-Tenant Binary & Franchise Context
**Date**: July 29, 2026  
**Status**: **Approved — implementation not started**  
**Decision**:

1. **Binary model:** Hybrid multi-tenant customer app — **one published binary**, many franchise tenants. Soft/platform store listing OK. **Each session has exactly one active `franchiseId`.** Branding, menu, cart, hours, and order payments resolve from that id.
2. **Not** pure white-label (separate binary per restaurant) and **not** a cross-tenant marketplace cart.
3. **Acquisition (A + B):**
   - **Primary:** QR / SMS / App Links / Universal Links (`fhq://f/{id}`, `https://franchisehq.io/f/{id}`).
   - **Secondary but required foundation:** public **directory** (listed franchises; name + city search). No geo/map required in v1.
4. **Single bind pipeline:** deep link, QR, directory tap, recents, and switcher all call the same bind path (`setFranchiseId` + branding reload + menu scope).
5. **Cold start:** deep link wins for that launch; else last selected / recents; else directory / choose-restaurant empty state. Do not rely on a silent permanent hard-coded single franchise as the only path.
6. **Signed-out browse:** directory/QR/link, menu, customize, and **cart** allowed without auth. **Checkout / pay requires sign-in.** Favorites, order history, loyalty require sign-in.
7. **Cart on franchise switch:** if cart non-empty → confirm → **clear cart and switch**. Never merge line items across franchiseIds.
8. **Signed-in switcher UI:** current · recents · my locations (`franchiseIds`) · find (directory) · scan QR.
9. **Pilot:** every pilot customer may receive QR/SMS; directory still ships so cold start and **real + mock** dual-tenant QA work without a link.

**Rationale:** Stack already franchise-scopes data; pilots are link-heavy but App Store opens and second-tenant testing need discovery; session-scoped tenant matches Connect checkout.  
**Impact:** Mobile shell, FranchiseProvider cold-start, new directory surface, cart policy, deep link hardening.  
**Reference:** `docs/slices/customer-franchise-context-v1.md`, `STATUS.md`.

### 12. Payments — Platform Stripe + Connect per Franchise
**Date**: July 29, 2026  
**Status**: **Approved — implementation not started**  
**Decision**:

1. **Two money paths:**
   - **Platform Stripe account:** charges **HQ / franchisees** for **SaaS** (subscriptions, platform invoices, plan billing).
   - **Stripe Connect connected account per franchise:** **customer food orders** settle to the franchise; platform takes an **application fee** (destination-style / Connect charge pattern).
2. **Do not** adopt long-term “platform merchant of record for all food orders” as the architecture (Option B rejected for scale).
3. **Option C pilot path:** implement **Connect-shaped** checkout from day one; use **test mode** for mock + real until Connect is complete; **live** charges only when franchise `paymentsEnabled` (Connect ready). If not ready, checkout fails honestly.
4. Franchise fields (conceptual): `stripeConnectedAccountId`, Connect status, `paymentsEnabled`. HQ exposes Connect onboarding + status honesty.
5. SaaS Billing and order GMV remain **separate** products in Stripe terms.

**Rationale:** Independent restaurants must receive order funds; platform still monetizes SaaS + take-rate; matches multi-tenant customer binary (Decision 11).  
**Impact:** Cloud Functions / webhooks, checkout mobile, HQ Connect UI, Platform Owner billing stays on platform account.  
**Reference:** `docs/slices/stripe-checkout-v1.md`, `STATUS.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Review before major refactors.

**Last Updated**: July 29, 2026
