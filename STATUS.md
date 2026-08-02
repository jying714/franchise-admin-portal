# STATUS.md — Live Project Snapshot

**Last Updated**: August 1, 2026 (~22:40 CDT — `customer_web` scaffold + customer-website-v1 slice; implementation not started)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `main`  
**Main**: MVP slices + thin POS pilot + 2026-08-01 cleanup; **customer website epic opened** (scaffold only)

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Thin POS software pilot: COMPLETE on `main` (2026-08-01).**  
**Post-pilot cleanup: COMPLETE** (mobile / web / POS order-detail workspace).  

**Active epic: Customer website (`customer_web`)** — hard release gate partner.  
- Top-level Flutter **web** app folder created; `flutter create --platforms=web` expected locally.  
- Feature folder scaffold via `scripts/scaffold_customer_web.ps1` (placeholders, no logic).  
- Authority: `docs/slices/customer-website-v1.md`.  
- **Product implementation not started** (no shared_core wire, no routes, no Hosting target yet).

**Still not hard-release complete:** customer website product, Stripe Terminal, real printers, staff bootstrap polish.  

**Plan authority (POS):** `docs/plans/pos-app-v1-development-plan.md` · `docs/slices/pos-app-v1.md`.  
**Plan authority (website):** `docs/slices/customer-website-v1.md`.  
Pure kitchen-only app (Decision 13) remains **superseded**.

| Area | State |
|------|--------|
| HQ onboarding + Design & Branding | **Done** |
| Platform Owner MVP | **Done** |
| Admin ops v1 | **Done** |
| Menu modifier M1–M5 + wings/calzone | **Done** |
| Mobile Design Tokens v1 (T1–T9) | **Done** |
| Developer Dashboard v1 | **Done** |
| Customer franchise context v1 | **COMPLETE** |
| Stripe checkout v1 (Connect) | **COMPLETE** |
| Mobile + web residual polish | **COMPLETE** |
| **Thin POS (`pos_app`) software pilot** | **COMPLETE on `main`** |
| **POS order-detail workspace** | **COMPLETE on `main`** |
| Kitchen-only app | **Superseded** |
| **Customer website (`customer_web`)** | **Scaffold only** — next implementation epic |

### Completed (locked) — POS software pilot + cleanup

See prior sections: pilot smoke PASS; order-detail void/comp/add/print/line refund; mobile reduced cards; `MenuProfile.sub`; HQ/Admin menu search/sort. Feature branches deleted after merge to `main`.

### Active focus

| Priority | Work | Notes |
|----------|------|--------|
| **1** | **Customer website** | `customer_web` + `docs/slices/customer-website-v1.md`; Decision 11/12 parity; `source: 'web'` |
| **2** | Staff bootstrap docs (R8) | PIN seed, claims, dart-defines runbook |
| **3** | Stripe Terminal / real printers (R3/R4) | When hardware available |
| **4** | Optional POS ticket discounts | Beyond payment-time discount |
| **5** | Staff/driver UI, 86, large-order | Phases 8–9 |

**Hard release gate:** Thin POS (**software done**) + **customer website** + polished mobile + web management.

### Customer website — structure locks (intent)

- **One** Flutter web app at repo root `customer_web/` (not inside `web-app` admin).  
- Franchise-scoped session; primary entry `/f/{slug}` (host TBD, e.g. `order.franchisehq.io`).  
- Signed-out browse; auth for cart/checkout; Connect pay; `store_ops` hours; no second menu tree.  
- HQ publishes `storefrontUrl` + QR on onboarding success (later).  
- Scaffold script: `scripts/scaffold_customer_web.ps1`.

### Residual list (updated 2026-08-01 late)

| ID | Item | Status |
|----|------|--------|
| R1–R2 | Tax + hours | **Done** |
| R3–R4 | Terminal / printers | **Open** |
| R5–R6 | Offline / settings | **Done** |
| R7 | Customer website MVP | **Open** — scaffold started; product build next |
| R8 | Staff bootstrap docs | **Open** |
| R9 | Software smoke | **Done** |
| R10 | Order-detail workspace | **Done** |

**Firestore path (locked):** `franchises/{franchiseId}/config/store_ops`  

**Decision locks:** 11 / 12 / 14 — franchise bind, dual Stripe, thin POS, manager void/refund, order `source`, no second menu tree.  
**Order lines:** `lineStatus` + `effectiveLineTotal`.  
**Windows Firebase CMake:** prefer **Android** for POS smoke.

---

**Update this file after significant sessions.**
