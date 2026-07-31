# STATUS.md — Live Project Snapshot

**Last Updated**: July 30, 2026 (~21:10 CDT — pos_app scaffold + tree PASS; development plan Phases 0–14 locked)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/pos-app-v1`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10, customer franchise context v1, stripe-checkout-v1, mobile+web residual polish; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Active implementation:** Decision **14** — Thin POS Station App (`pos_app`).  
**Scaffold:** `flutter create pos_app` + user feature tree — **PASS**.  
**Next:** Phase 1 shared_core domain foundation → Phase 2 PIN session shell.  
**Plan authority:** `docs/plans/pos-app-v1-development-plan.md` (Phases 0–14).  
Pure kitchen-only app (Decision 13) remains **superseded**.

| Area | State |
|------|--------|
| HQ onboarding + Design & Branding | **Done** |
| Platform Owner MVP | **Done** |
| Admin ops v1 | **Done** |
| Menu modifier M1–M5 + wings/calzone | **Done** |
| Mobile Design Tokens v1 (T1–T9) | **Done** |
| Developer Dashboard v1 | **Done** |
| Customer franchise context v1 | **COMPLETE on `main`** |
| Stripe checkout v1 (Connect) | **COMPLETE on `main`** |
| Mobile + web residual polish | **COMPLETE on `main`** |
| **Thin POS (`pos_app`)** | **Active** — scaffold PASS; Phase 1 next |
| Kitchen-only app | **Superseded** |
| Customer website | **Not started** (hard release gate) |

### Completed (locked)

- [x] Decisions 7–12 delivered on `main` as previously recorded
- [x] Decision 14 product lock (July 30)
- [x] Mobile + web residual polish merged
- [x] **pos_app Flutter scaffold + full user directory tree** (July 30)
- [x] **POS development plan Phases 0–14** documented

### Active focus — release MVP

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Thin POS** — follow development plan Phase 1 → 14 | `docs/plans/pos-app-v1-development-plan.md` · `docs/slices/pos-app-v1.md` · Decision 14 |
| **2** | Customer website | TBD slice |
| **3** | Pilot polish | After POS MVP |

**Hard release gate:** Thin POS + customer website + polished mobile + web management.

**Pilot hardware:** Android tablet at counter; Ethernet ESC-POS; cash drawer; card-present reader.

### POS phase tracker (summary)

| Phase | Name | Status |
|-------|------|--------|
| 0 | Repo + docs + scaffold | **PASS** |
| 1 | shared_core domain foundation | **Next** |
| 2 | PIN session + franchise lock + permissions | Open |
| 3 | Home + open-order board | Open |
| 4 | Carry-out order entry + modifiers | Open |
| 5 | Payments card + cash + drawer | Open |
| 6 | Dine-in tables + open ticket | Open |
| 7 | Delivery + driver assign | Open |
| 8 | Staff / driver / waitress records | Open |
| 9 | Large order + 86 + allergens | Open |
| 10 | Printing pipeline | Open |
| 11 | Incoming online orders | Open |
| 12 | Settings panel | Open |
| 13 | Offline honesty | Open |
| 14 | Pilot QA + acceptance | Open |

### Decision locks (do not regress)

Retain Decision 11 / 12 / 14 locks from prior STATUS (franchise bind, Stripe dual accounts, station = thin POS not kitchen-only, manager-only void/refund, order source field, ColorScheme / DesignTokens rules).

### Explicit post-MVP / deferred

Unchanged: guest cart, live delivery tracking, full time-clock, complex inventory, iOS primary pilot, survey scheduled push, CF Node 22 before ~2026-10-30, mobile T8 auth residual.

**Ground truth:** one FranchiseProvider; no DesignTokens widget color invention; no pure kitchen binary; no second menu modifier tree in POS.

---

**Update this file after significant sessions.**
