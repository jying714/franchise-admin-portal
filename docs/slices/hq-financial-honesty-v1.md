# Slice: HQ Financial Honesty v1 (KPI card)

**Status:** **COMPLETE** — implemented and smoke-passed July 26, 2026  
**Branch:** `feat/onboarding-4step`  
**Authority:** This file + STATUS.md  
**Depends on:** HQ polish-v1 COMPLETE; single FranchiseProvider; franchise-scoped HQ dashboard  
**Owner surface:** Owner HQ dashboard — **Financial KPIs** card only  
**Agent policy:** Surgical. No new DesignTokens/BrandingConfig fields. No new screens. No Cloud Functions in this slice. Prefer AdminFirestoreService for admin financial reads (do not “fix” mobile FirestoreServiceImpl stubs as product truth). No dual invoice workbenches. Do not expand Platform billing / Payouts shells in this slice.

---

## 1. Product intent

Make the **Financial KPIs** card on Owner HQ **honest and complete for MVP**:

- Real reads from Firestore for all four metrics.
- No stub zeros presented as if computed.
- All UX stays **inside the card** (no new route / detail screen).
- Domain is **HQ / franchise ↔ platform**, not diner AR workbench.

**Success:** HQ owner on a franchise sees Revenue, Outstanding, Last Payout, and Avg. Order from real data (or true empty: $0 / — after a real query), with loading/error/retry working, and values refresh on franchise switch without leaving the dashboard.

---

## 2. Locked product decisions (July 26, 2026)

| Topic | Decision |
|-------|----------|
| **Outstanding (A)** | Sum of **unpaid / open / partial / overdue platform invoices** for the **current franchise**. Platform → franchise SaaS bills (`franchises/{id}/platform_invoices`), **not** customer/store tickets. |
| **Analytics period (C)** | Prefer summaries with **totalRevenue > 0**, then newest `updatedAt` / `createdAt`; fall back to period id. |
| **Scope** | In-card only; four existing tiles; no new screens. |
| **Service path** | Web HQ uses **AdminFirestoreService** overrides of `getFranchiseAnalyticsSummary` / `getOutstandingInvoices` / `getLastPayout`. Lightweight stubs unchanged for mobile. |
| **Display** | All metrics **2 decimal places**; tiles `Expanded` (no row overflow). |
| **Franchise switch** | `ValueKey(franchiseId)` + `didUpdateWidget` + `FranchiseProvider` listen reload. |

### Metric definitions (v1)

| Tile | Source of truth |
|------|-----------------|
| **Revenue** | Selected analytics summary → `totalRevenue` |
| **Outstanding** | Sum of platform invoice `amount` where status ∈ unpaid / partial / overdue / open |
| **Last Payout** | Latest `franchises/{id}/payouts` by date → `amount` / `netAmount` |
| **Avg. Order** | Same analytics summary → `averageOrderValue` |

---

## 3. Workstreams

### W1 — Admin service real KPI reads — **DONE**

- `getFranchiseAnalyticsSummary` — `franchises/{id}/analytics_summaries`, prefer revenue > 0 then newest.
- `getOutstandingInvoices` — sum unpaid-class platform invoices via `getPlatformInvoicesForFranchisee`.
- `getLastPayout` — latest franchise-scoped payout map.

### W2 — KPI card admin path + franchise switch — **DONE**

- 2-decimal display; Expanded tiles (no overflow).
- Reload on franchiseId change (key + didUpdateWidget + provider).

### W3 — Slice close — **DONE**

---

## 4. Explicit out of scope

- New HQ routes / invoice or payout list screens  
- Cloud Functions for live order aggregation  
- Cash Flow Forecast card  
- Platform billing card / Payouts card product work  
- Changing DesignTokens / BrandingConfig  
- Mobile app financial KPI UI  

---

## 5. Acceptance checklist

- [x] KPI card does **not** use lightweight stub returns for the three metrics  
- [x] Revenue + Avg. Order come from analytics summary for current franchise  
- [x] Outstanding = sum of unpaid-class **platform invoices** for current franchise  
- [x] Last Payout = latest payout for franchise or honest empty after query  
- [x] Franchise switch reloads KPIs without leaving dashboard  
- [x] Loading / error / retry still work  
- [x] No new screen; card remains the only surface  
- [x] Platform billing + Payouts shells unchanged  
- [x] 2-decimal display; no RenderFlex overflow  

---

## 6. Smoke (passed July 26, 2026)

- Seeded `test` (and doughboys as needed): Revenue 1248.75, Outstanding 164.50, Last Payout 487.25, Avg 46.25  
- doughboys analytics path selects real summary docs  
- Franchise switch updates KPIs in place  

---

## 7. Key files

- `web-app/lib/core/services/admin_firestore_service.dart` — three KPI overrides  
- `web-app/lib/widgets/financials/franchise_financial_kpi_card.dart` — display + reload  
- `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` — `ValueKey` on KPI card  
- Seed helper (local): `scripts/seed_hq_financial_kpi_test.js`  

---

**Last updated:** July 26, 2026 — slice **COMPLETE**  
**Next:** New product slice only when ready.
