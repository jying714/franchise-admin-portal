# Handoff: HQ Owner financial + billing session

**Date:** Sunday, July 26, 2026 (~5:30 PM CDT)  
**Branch:** `feat/onboarding-4step`  
**Repo:** https://github.com/jying714/franchise-admin-portal  
**Local path:** `C:\projects\franchise-admin-portal`

Prefer **STATUS.md + this handoff + slice docs under `docs/slices/`** over agent memory.

---

## 1. Session outcomes (this conversation arc)

### Closed product slices

| Slice | Status | Authority |
|-------|--------|-----------|
| `hq-onboarding-hq-polish-v1` | COMPLETE (earlier same day) | `docs/slices/hq-onboarding-hq-polish-v1.md` |
| `hq-financial-honesty-v1` | COMPLETE | `docs/slices/hq-financial-honesty-v1.md` |
| `hq-platform-billing-v1` | COMPLETE | `docs/slices/hq-platform-billing-v1.md` |

### Card-only work (no formal slice file)

- **AlertsCard** UI honesty: stateful level filter, Retry, strip dead See all → `+N more`, dashboard `ValueKey('hq-alerts-$franchiseId')`. Producers and AlertListScreen **not** built.

### Explicit post-MVP defer (human decision July 26)

- **Cash Flow Forecast** HQ card — long-term in-dev; low MVP value  
- **Multi-Brand Overview** HQ card — long-term in-dev; single-franchise MVP  
- Pivot next product attention to **Platform Owner / Admin dashboard**, not more HQ residual shells

---

## 2. HQ Financial Honesty v1 — granular

**Problem:** KPI card showed stub zeros from lightweight `FirestoreServiceImpl`.

**Solution path:** Override three methods on **`AdminFirestoreService`** only (web injects Admin as `FirestoreService`). Do not “fix” mobile stubs.

| Method | Behavior |
|--------|----------|
| `getFranchiseAnalyticsSummary` | Read `franchises/{id}/analytics_summaries`; prefer docs with `totalRevenue > 0`, then newest `updatedAt`/`createdAt` |
| `getOutstandingInvoices` | Sum `getPlatformInvoicesForFranchisee` amounts where status ∈ unpaid / partial / overdue / open |
| `getLastPayout` | Latest `franchises/{id}/payouts` by date; map `amount` / `netAmount` |

**KPI card (`franchise_financial_kpi_card.dart`):**

- Display **2 decimal places** (not integer rounding)
- Tiles wrapped in `Expanded` (no RenderFlex overflow)
- Reload on franchise switch: `ValueKey('hq-kpi-$franchiseId')` + `didUpdateWidget` + FranchiseProvider listen in `didChangeDependencies`

**Seed (local script, not necessarily in repo):** `scripts/seed_hq_financial_kpi_test.js` — franchise-scoped analytics_summaries, platform_invoices, payouts under `franchises/{id}/…`. Expected on `test` after seed: Revenue 1248.75, Outstanding 164.50, Last Payout 487.25, Avg 46.25.

**Smoke:** Passed on seeded franchises; switch updates without leaving dashboard.

---

## 3. HQ Platform Billing v1 — granular

**Problem:** Platform billing card was “In development” shell.

**Solution:** Stateful `PlatformBillingCard(franchiseId:)` in `owner_hq_dashboard_screen.dart`:

- Load via `getPlatformInvoicesForFranchisee`
- Sort newest first (`createdAt`)
- Rows: invoice number, status, amount (2 dp) + currency, due date
- Footer: Outstanding (same status set as KPI)
- Empty / loading / error+retry
- `ValueKey('hq-platform-billing-$franchiseId')` + provider reload pattern

**No** pay CTA, **no** `/hq/invoices` route, **no** dual Billing Summary + Invoices cards.

**Smoke:** List + Outstanding 164.50 matched KPI unpaid sum; empty franchise copy; switch in place.

---

## 4. Alerts card (partial)

**Implemented:** Filter popup (All/Error/Warning/Info), client-side filter, Retry via stream epoch, remove `pushNamed('/alerts')`, `+N more` text only, dashboard ValueKey.

**Not implemented:** AlertListScreen polish, dismiss UX productization, **any alert producers**. Card remains empty until writers insert `alerts` docs with `franchiseId` as **DocumentReference** path `franchises/{id}` (repository query uses `franchiseId.path`).

**Human:** Further Alerts product deferred; pivot away from HQ residual.

---

## 5. Data / schema notes (do not regress)

- Platform invoices for Admin KPI/billing: **`franchises/{franchiseId}/platform_invoices`** (not root-only legacy as primary)
- Analytics: **`franchises/{franchiseId}/analytics_summaries`**
- Payouts for last payout tile: **`franchises/{franchiseId}/payouts`**
- `PlatformInvoice` model: `amount`, `status`, `invoiceNumber`, `dueDate`, `currency`, `franchiseeId`
- Subscription feature keys: `test` franchise needed `mobile_ordering` in planSnapshot.features (was `mobile_app`) for Feature Setup toggle — data fix, not code

---

## 6. Key files touched (this arc)

- `web-app/lib/core/services/admin_firestore_service.dart` — KPI overrides
- `web-app/lib/widgets/financials/franchise_financial_kpi_card.dart`
- `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` — PlatformBillingCard, keys, grid
- `web-app/lib/admin/hq_owner/widgets/alerts_card.dart` — filter/retry/honesty
- `docs/slices/hq-financial-honesty-v1.md`, `hq-platform-billing-v1.md`, polish v1
- `STATUS.md`

---

## 7. What’s left (prioritized)

1. **Platform Owner / Admin dashboard** — human-chosen next focus (inventory of cards, real vs stub, separate slices)  
2. **Payouts HQ card** — still in-dev shell if HQ residual is ever resumed  
3. **Cash Flow / Multi-brand** — **post-MVP only**  
4. **Alerts producers** — only when product defines who writes alerts  
5. Residuals: onboarding progress lag on franchise switch; Liberty `ingredientId`; device re-smoke `mobile_ordering`

---

## 8. Local commit reminder

If Alerts card / dashboard key changes are still unstaged locally:

```bash
git add web-app/lib/admin/hq_owner/widgets/alerts_card.dart web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart
git commit -m "HQ Alerts card: filter, retry, no dead See all"
git pull --rebase origin feat/onboarding-4step
git push origin feat/onboarding-4step
```

Financial honesty + platform billing code should already be on remote from earlier commits; confirm with `git status` / `git log -5`.

---

**Bottom line:** HQ Owner **financial KPI + platform billing** are real in-card MVPs. Alerts card is honest chrome without producers. Cash Flow and Multi-brand are **explicitly post-MVP**. Next conversation should start on **Platform Owner dashboard**, not re-opening deferred HQ shells.
