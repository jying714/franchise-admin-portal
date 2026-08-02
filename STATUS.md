# STATUS.md — Live Project Snapshot

**Last Updated**: August 2, 2026 (~09:15 CDT — customer_web vertical slice live + HQ storefront QR)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/customer-website-v1`  
**Main**: POS pilot + cleanup; customer website epic **in progress on feature branch** (merge when human gates)

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Thin POS software pilot: COMPLETE on `main` (2026-08-01).**  
**Post-pilot cleanup: COMPLETE** (mobile / web / POS order-detail workspace).  

**Active epic: Customer website (`customer_web`) — vertical slice PASS on Hosting.**  
- Top-level Flutter **web** app at `customer_web/` with `shared_core`, Firebase, Stripe web.  
- Path bind `/f/{franchiseId}` → branding + menu; signed-out browse; Google/email auth; cart; Connect checkout; `source: 'web'`.  
- Hosting site **`franchise-storefront`** → https://franchise-storefront.web.app  
- Dual Hosting targets: `admin` (web-app / franchisehq.io) + `storefront` (customer_web).  
- HQ Owner card: copy / open / QR for `https://franchise-storefront.web.app/f/{franchiseId}`.  
- Authority: `docs/slices/customer-website-v1.md`.

**Still not hard-release complete:** merge customer_web to `main` + residual polish (modifier line customizations, custom domains, Terminal/printers, staff bootstrap).  

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
| **Customer website (`customer_web`)** | **Vertical slice PASS** on `feat/customer-website-v1` + Hosting |

### Customer website — done on this branch (2026-08-02)

| Capability | State |
|------------|--------|
| Firebase + MultiProvider + FranchiseProvider | **Done** |
| `/f/{franchiseId}` bind + menu browse | **Done** |
| Live branding shell | **Done** |
| Item detail + modifier groups (label/min/max/upcharge) | **Done** |
| Google + email auth | **Done** |
| Cart + remove | **Done** |
| Checkout: store_ops tax/hours, CardField, `createOrderPaymentIntent`, `source: 'web'` | **Done** |
| Order confirmation screen | **Done** |
| Hosting target `storefront` → franchise-storefront.web.app | **Done** |
| Path→hash bootstrap + GoRouter/landing mobile bind | **Done** |
| HQ Storefront link card (copy / open / QR) | **Done** |
| Build flag | `--pwa-strategy=none` recommended for storefront deploys |

**Public URL pattern:** `https://franchise-storefront.web.app/f/{franchiseId}`  
**Example:** `https://franchise-storefront.web.app/f/doughboyspizzeria`  

**Auth domains:** add `franchise-storefront.web.app` (+ `.firebaseapp.com`) under Firebase Authentication → Authorized domains.

**Stripe web:** `flutter_stripe` + `flutter_stripe_web`; `STRIPE_PK` via `--dart-define` (never commit keys). Workflow secret name: `STRIPE_PK_TEST`.

### Active focus

| Priority | Work | Notes |
|----------|------|--------|
| **1** | **Merge gate + residuals** | Human review → merge `feat/customer-website-v1` when ready; Phase 4b modifier customizations into cart line |
| **2** | Optional custom domains | One Hosting site; CNAME + hostname→franchise map (deferred schema) |
| **3** | Staff bootstrap docs (R8) | PIN seed, claims, dart-defines runbook |
| **4** | Stripe Terminal / real printers (R3/R4) | When hardware available |
| **5** | Staff/driver UI, 86, large-order | Phases 8–9 |

**Hard release gate:** Thin POS (**software done**) + **customer website** (vertical slice done on feature branch) + polished mobile + web management.

### Residual list (updated 2026-08-02)

| ID | Item | Status |
|----|------|--------|
| R1–R2 | Tax + hours | **Done** |
| R3–R4 | Terminal / printers | **Open** |
| R5–R6 | Offline / settings | **Done** |
| R7 | Customer website MVP | **Vertical slice PASS** — merge + 4b/custom domain residual |
| R8 | Staff bootstrap docs | **Open** |
| R9 | Software smoke | **Done** |
| R10 | Order-detail workspace | **Done** |

**Firestore path (locked):** `franchises/{franchiseId}/config/store_ops`  

**Decision locks:** 11 / 12 / 14 — franchise bind, dual Stripe, thin POS, manager void/refund, order `source`, no second menu tree.  
**Order lines:** `lineStatus` + `effectiveLineTotal`.  
**Windows Firebase CMake:** prefer **Android** for POS smoke.

---

**Update this file after significant sessions.**
