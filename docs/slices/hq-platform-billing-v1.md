# Slice: HQ Platform Billing v1 (in-card invoice list)

**Status:** OPEN — decisions locked July 26, 2026  
**Branch:** `feat/onboarding-4step`  
**Authority:** This file + STATUS.md  
**Depends on:** HQ polish-v1 COMPLETE; HQ financial honesty v1 COMPLETE (Admin path for platform invoices)  
**Owner surface:** Owner HQ dashboard — **Platform billing** card only  
**Agent policy:** Surgical. No new DesignTokens/BrandingConfig fields. No new screens or named routes for invoices. No pay/Stripe/mark-paid in this slice. Prefer AdminFirestoreService / existing `getPlatformInvoicesForFranchisee`. Do not restore dual Billing Summary + Invoices cards. Do not expand Payouts product work here.

---

## 1. Product intent

Replace the **In development** Platform billing shell with a **fully developed, read-only MVP** of platform → franchise SaaS invoices for the **current franchise**, entirely **inside the existing card**.

**Success:** HQ owner sees a live list of platform invoices for the selected franchise (or an honest empty state), with loading/error/retry, outstanding total aligned with KPI outstanding rules, and list refresh on franchise switch without leaving the dashboard.

---

## 2. Locked product decisions (July 26, 2026)

| Topic | Decision |
|-------|----------|
| **Domain** | Platform → franchise SaaS bills (`PlatformInvoice`), not diner/customer AR |
| **Collection** | `franchises/{franchiseId}/platform_invoices` |
| **UX** | **In-card only** — no new screen, no `/hq/invoices` CTA |
| **Actions** | **Read-only** — no pay dialog, no mark paid, no Stripe portal in v1 |
| **List order** | Newest first (`createdAt` / `dueDate` descending) |
| **Row fields** | Invoice number (fallback id), status, amount (2 decimals) + currency, due date |
| **Outstanding footer** | Sum of amounts where status ∈ `unpaid` / `partial` / `overdue` / `open` (same rule as KPI Financial Honesty) |
| **Empty** | “No platform invoices for this franchise.” after a successful empty query |
| **Franchise switch** | `ValueKey(franchiseId)` + reload when franchise changes |
| **Service** | Reuse `getPlatformInvoicesForFranchisee` on AdminFirestoreService |

---

## 3. Ground truth (do not regress)

| Fact | Detail |
|------|--------|
| Current UI | `PlatformBillingCard` in `owner_hq_dashboard_screen.dart` — In development shell |
| Model | `packages/shared_core/.../platform_invoice.dart` — `amount`, `status`, `invoiceNumber`, `dueDate`, `currency`, `franchiseeId` |
| Admin read | `getPlatformInvoicesForFranchisee(franchiseeId)` already franchise-scoped |
| KPI outstanding | Same status set and path — billing card total should match KPI Outstanding for the same franchise when data is shared |
| Grid | Card stays a peer in the HQ grid (same aspect sizing); do not go full-bleed |

---

## 4. Workstreams

### W1 — Stateful PlatformBillingCard with real list — **OPEN**

- Replace shell with stateful card taking `franchiseId`.
- Load via `Provider.of<FirestoreService>` → `getPlatformInvoicesForFranchisee`.
- Sort newest first.
- Render compact list (max ~5–8 rows visible; scroll inside card if more).
- Footer: Outstanding total (2 decimals).
- Loading / error + retry / empty states.
- `ValueKey` + `didUpdateWidget` / provider reload on franchise change.

### W2 — Dashboard wiring — **OPEN**

- Pass `franchiseId` into the card; key by franchise.
- Do not reintroduce InvoicesCard / BillingSummaryCard.
- Do not add Quick Link to invoices.

### W3 — Smoke + close — **OPEN**

- Seeded franchises show list + outstanding match KPI.
- Franchise with no invoices → empty copy.
- Switch franchises without leaving HQ.
- STATUS + this file → COMPLETE.

---

## 5. Explicit out of scope

- Pay invoice dialog / Stripe / hosted invoice URL  
- New invoice list screen or `/hq/invoices` navigation  
- Creating/editing invoices from HQ  
- Root-level `platform_invoices` as primary source  
- Payouts card, Cash Flow card  
- New DesignTokens / BrandingConfig fields  

---

## 6. Implementation order

1. **W1** Implement stateful `PlatformBillingCard` (or replace class body in dashboard file / dedicated widget file under `hq_owner/widgets` if cleaner — prefer one small widget file next to other HQ cards).  
2. **W2** Wire `franchiseId` + key from `owner_hq_dashboard_screen.dart`.  
3. **Smoke** on `test` / `doughboyspizzeria` (seed data from financial honesty).  
4. **W3** Mark STATUS + slice COMPLETE; commit.

---

## 7. Acceptance checklist

- [ ] No “In development” label on Platform billing card  
- [ ] List loads from `franchises/{id}/platform_invoices`  
- [ ] Rows show number, status, amount (2 dp), due date  
- [ ] Outstanding footer matches unpaid-class sum  
- [ ] Empty / loading / error+retry work  
- [ ] Franchise switch refreshes list in place  
- [ ] No new screen or pay CTA  
- [ ] Dual billing/invoice cards not restored  

---

## 8. Smoke

1. Franchise with seed invoices → list + outstanding ≈ KPI Outstanding.  
2. Franchise without invoices → empty message.  
3. Switch franchise on HQ → list updates without leaving dashboard.  
4. Grid layout still peer-sized; no overflow into neighboring cards.

---

## 9. Key files (expected)

- `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` — wire card + key  
- Platform billing widget (inline or `web-app/lib/admin/hq_owner/widgets/platform_billing_card.dart`)  
- `web-app/lib/core/services/admin_firestore_service.dart` — reuse existing invoice read (no API invent)  
- `packages/shared_core/.../platform_invoice.dart` — model only  

---

**Last updated:** July 26, 2026 — slice opened  
**Next:** W1 stateful PlatformBillingCard with real franchise-scoped list.
