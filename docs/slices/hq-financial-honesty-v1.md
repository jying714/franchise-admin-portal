# Slice: HQ Financial Honesty v1 (KPI card)

**Status:** OPEN — decisions locked July 26, 2026  
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

**Success:** HQ owner on a franchise sees Revenue, Outstanding, Last Payout, and Avg. Order from real data (or true empty: $0 / — after a real query), with loading/error/retry working.

---

## 2. Locked product decisions (July 26, 2026)

| Topic | Decision |
|-------|----------|
| **Outstanding (A)** | Sum of **unpaid / open platform invoices** for the **current franchise**. Platform → franchise SaaS bills (`platform_invoices`), **not** customer/store tickets. |
| **Analytics period (C)** | Use the **latest available** analytics summary document for that franchise (not forced to calendar-month-only). |
| **Scope** | In-card only; four existing tiles; no new screens. |
| **Service path** | Web HQ must use **AdminFirestoreService** (or equivalent web admin impl) for these reads. Lightweight `FirestoreServiceImpl` stubs must not be the production path for this card. |
| **Empty data** | After a real query: show **$0** or **—** with normal tile chrome — not “coming soon” labels on the KPI card. |

### Metric definitions (v1)

| Tile | Source of truth |
|------|-----------------|
| **Revenue** | Latest `analytics_summaries` (or equivalent) doc for franchise → `totalRevenue` (or mapped field). Currency from doc when present. |
| **Outstanding** | Sum of amounts on platform invoices for this franchise where status ∈ unpaid/open/overdue (exact status strings must match existing docs / model). |
| **Last Payout** | Most recent payout for franchise by date → amount (+ date in tooltip if available). Empty query → — / $0. |
| **Avg. Order** | Same latest analytics summary → `averageOrderValue` (or mapped field). |

---

## 3. Ground truth (do not regress)

| Fact | Detail |
|------|--------|
| Card | `web-app/lib/widgets/financials/franchise_financial_kpi_card.dart` |
| Today’s calls | `getFranchiseAnalyticsSummary`, `getOutstandingInvoices`, `getLastPayout` on injected `FirestoreService` |
| Lightweight stubs | `FirestoreServiceImpl` returns `{}` / `0.0` / `{}` for those three — **not** product behavior |
| Dump data | Franchise analytics under `franchises/{id}/analytics_summaries` (e.g. period docs with `totalRevenue`, `averageOrderValue`) |
| Platform invoices | Top-level `platform_invoices` (franchise association field must be verified in model/docs — e.g. `franchiseeId` / `franchiseId`) |
| Architecture | Admin-only financial methods belong on **AdminFirestoreService**; mobile tier stays lightweight |
| Polish-v1 | Platform billing + Payouts dashboard cards remain separate in-dev shells; **out of scope** here |

---

## 4. Workstreams

### W1 — Admin service: real KPI reads — **OPEN**

Implement (or complete) on **AdminFirestoreService**:

1. **Latest analytics summary** for `franchiseId`  
   - Query `franchises/{franchiseId}/analytics_summaries` (confirm collection name against live schema).  
   - Choose **latest** by period id / `updatedAt` / document id convention already used in dump.  
   - Return map consumed by the card (`totalRevenue`, `averageOrderValue`, `currency`, …).

2. **Outstanding**  
   - Query `platform_invoices` for this franchise.  
   - Filter unpaid/open/overdue statuses (align with `PlatformInvoice` model).  
   - Sum amounts (respect cents vs dollars if model stores minor units).

3. **Last payout**  
   - Query franchise payouts ordered by date desc, limit 1.  
   - Return `{ amount, date, ... }` or empty map if none.

Keep method names stable if the card already depends on them; change **implementation + injection**, not invent parallel APIs without need.

### W2 — KPI card: admin path + franchise switch — **OPEN**

- Resolve `AdminFirestoreService` (or web admin firestore) in the card instead of lightweight stubs.  
- Reload KPIs when `franchiseId` changes (didUpdateWidget / key by franchiseId).  
- Preserve role gate (`hq_owner` / `developer` / `finance_manager`).  
- Keep loading shimmer, error + retry.  
- Format currency consistently; empty = $0 or — after successful query.

### W3 — Slice close — **OPEN**

- Smoke on `test` (and second franchise if available).  
- STATUS.md + this file → COMPLETE.  
- No STATUS claim until reads verified against real docs.

---

## 5. Explicit out of scope

- New HQ routes / invoice or payout list screens  
- Cloud Functions for live order aggregation  
- Cash Flow Forecast card  
- Platform billing card / Payouts card product work  
- Changing DesignTokens / BrandingConfig  
- Mobile app financial KPI UI  
- Filling empty Firestore with fake seed data as a substitute for correct queries (seed only if human explicitly asks for demo data)

---

## 6. Implementation order

1. **W1** AdminFirestoreService real implementations for the three reads (quote existing method signatures; verify collection + field names from real models/docs).  
2. **W2** Point `FranchiseFinancialKpiCard` at admin service; franchiseId change reload.  
3. **Smoke** on live/emulator data.  
4. **W3** STATUS + slice COMPLETE.

---

## 7. Acceptance checklist

- [ ] KPI card does **not** use lightweight stub returns for the three metrics  
- [ ] Revenue + Avg. Order come from **latest** analytics summary for current franchise  
- [ ] Outstanding = sum of unpaid/open **platform invoices** for current franchise  
- [ ] Last Payout = latest payout for franchise or honest empty after query  
- [ ] Franchise switch reloads KPIs for the new id  
- [ ] Loading / error / retry still work  
- [ ] No new screen; card remains the only surface  
- [ ] Platform billing + Payouts shells unchanged  

---

## 8. Smoke

1. HQ as `hq_owner` on franchise with analytics_summaries → Revenue and AOV non-stub.  
2. Same franchise with open platform invoices → Outstanding matches manual sum.  
3. Franchise with a payout → Last Payout amount/date; franchise with none → empty tile not crash.  
4. Switch franchise → values change (or correctly empty).  
5. Force error (optional) → error chrome + Retry recovers.

---

## 9. Key files (expected)

- `web-app/lib/widgets/financials/franchise_financial_kpi_card.dart`  
- Admin firestore service (path under `web-app/lib/...` — confirm exact file before edit)  
- `packages/shared_core/...` only if abstract signatures must stay in sync (prefer no API churn)  
- Models: `PlatformInvoice`, analytics summary types if already defined  

---

**Last updated:** July 26, 2026 — slice opened (A+C locked)  
**Next:** W1 AdminFirestoreService real KPI reads; then W2 card wiring.
