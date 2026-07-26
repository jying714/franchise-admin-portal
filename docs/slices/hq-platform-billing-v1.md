# Slice: HQ Platform Billing v1 (in-card invoice list)

**Status:** **COMPLETE** — implemented and smoke-passed July 26, 2026  
**Branch:** `feat/onboarding-4step`  
**Authority:** This file + STATUS.md  
**Depends on:** HQ polish-v1 COMPLETE; HQ financial honesty v1 COMPLETE  
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
| **Domain** | Platform → franchise SaaS bills (`PlatformInvoice`) |
| **Collection** | `franchises/{franchiseId}/platform_invoices` |
| **UX** | **In-card only** — no new screen, no pay CTA |
| **List order** | Newest first (`createdAt` descending) |
| **Row fields** | Invoice number (fallback id), status, amount (2 decimals) + currency, due date |
| **Outstanding footer** | Sum where status ∈ unpaid / partial / overdue / open |
| **Franchise switch** | `ValueKey` + `didUpdateWidget` + FranchiseProvider listen |

---

## 3. Workstreams

### W1 — Stateful PlatformBillingCard with real list — **DONE**
### W2 — Dashboard wiring — **DONE**
### W3 — Smoke + close — **DONE**

---

## 4. Explicit out of scope

- Pay invoice dialog / Stripe / hosted invoice URL  
- New invoice list screen or `/hq/invoices` navigation  
- Creating/editing invoices from HQ  
- Payouts card, Cash Flow card product work  

---

## 5. Acceptance checklist

- [x] No “In development” label on Platform billing card  
- [x] List loads from `franchises/{id}/platform_invoices`  
- [x] Rows show number, status, amount (2 dp), due date  
- [x] Outstanding footer matches unpaid-class sum (e.g. 164.50 = 30+89+45.50)  
- [x] Empty / loading / error+retry work  
- [x] Franchise switch refreshes list in place  
- [x] No new screen or pay CTA  
- [x] Dual billing/invoice cards not restored  

---

## 6. Smoke (passed July 26, 2026)

- List + Outstanding match KPI unpaid sum  
- Empty franchise → empty copy  
- Franchise switch updates in place  
- No pay CTA / no new route / no dual cards  

---

## 7. Key files

- `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` — `PlatformBillingCard` + grid key  
- `getPlatformInvoicesForFranchisee` on AdminFirestoreService  

---

**Last updated:** July 26, 2026 — slice **COMPLETE**  
**Next:** New product slice only when ready.
