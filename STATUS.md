# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — polish-v1 COMPLETE; **hq-financial-honesty-v1 OPEN**)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 – Core Config Scoping & Dynamic Branding + HQ surfaces**

### Completed (recent)

- [x] Menu Items v1; live HQ branding on franchise switch; branding notify + picker guard
- [x] **Single** web `FranchiseProvider` at app root
- [x] Design & Branding screen v1/v1.1
- [x] **Polish W1–W6 COMPLETE** — see `docs/slices/hq-onboarding-hq-polish-v1.md`

### Active slice: `docs/slices/hq-financial-honesty-v1.md`

**Status:** OPEN — decisions locked.

| Topic | Decision |
|-------|----------|
| Outstanding | Sum unpaid/open **platform invoices** for current franchise (A) |
| Analytics | **Latest available** summary doc for franchise (C) |
| Scope | Financial KPIs card only; in-card; no new screens; AdminFirestoreService path |

**Next implementation order:** W1 Admin service real reads → W2 KPI card wiring + franchise reload → smoke → STATUS complete.

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); lightweight `FirestoreServiceImpl` KPI methods are stubs — HQ must not treat them as product.

**Known residual (non-blocking for this slice):** franchise-switch progress lag; Liberty `ingredientId` type noise; device re-smoke of `mobile_ordering`; Cash Flow / Platform billing / Payouts product cards still separate.

---

**Update this file after significant sessions.**
