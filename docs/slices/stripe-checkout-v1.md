# Slice: Stripe Checkout v1 (Platform + Connect)

**Status**: **COMPLETE** (2026-07-30)  
**Branch**: `feat/stripe-checkout-v1`  
**Authority**: Decision **12** · STATUS · HANDOFF · this file  
**Depends on**: Active `franchiseId` (Decision 11); Platform Owner billing surfaces may already list invoices  
**Pilot**: Test mode for mock + real; live charges only when real franchise Connect-ready  
**Related**: Cash on pickup / counter is Decision **14** / thin POS — **not** Connect

---

## 1. Problem

Ordering UX exists without a **locked multi-tenant card payment architecture**. Product needs:

- Platform revenue from **HQ SaaS**
- Franchise receipt of **customer card order** funds
- Platform **take-rate** on card orders
- Honest block when a franchise cannot accept **card** payments

---

## 2. Locks (Decision 12)

### Two Stripe surfaces

| Account | Charges |
|---------|---------|
| **Platform Stripe account** | HQ owners — subscriptions, platform invoices, SaaS plans |
| **Connect account per franchise** | End customers — **card** food orders; **application fee** to platform |

```text
Customer card order → Franchise Connect account  (+ application fee → Platform)
HQ subscription     → Platform Stripe account only
Cash on pickup / counter → Thin POS (Decision 14); no Connect charge
```

### Architecture choice

- **Target:** Stripe **Connect** (destination-style charges + application fee) for **card**.  
- **Rejected as long-term:** platform merchant-of-record for all food orders.  
- **Pilot (Option C):** Connect-shaped code paths from day one; **test mode** until live; no second permanent card-checkout architecture.

### Runtime rules

| Rule | Lock |
|------|------|
| Checkout franchise | Always active session `franchiseId` |
| Missing Connect / not ready | **Fail closed** on **card** pay — “Payments not set up” |
| `paymentsEnabled` | True only when connected account can accept charges |
| Cash option | Handled by thin POS (Decision 14); does not require Connect |
| Application fee | Platform-configured % or flat |
| Card order → kitchen / POS | Status **`paid`** drives downstream handling |

---

## 3. Workstreams

| ID | Deliverable | Status |
|----|-------------|--------|
| **ST0** | Docs lock | **Done** |
| **ST1** | Franchise fields: connected account id, status, `paymentsEnabled` | **Done** |
| **ST2** | HQ Connect onboarding entry + status honesty | **Done** |
| **ST3** | Create PaymentIntent (Connect + application fee) | **Done** |
| **ST4** | Webhooks → order paid/failed; idempotent | **Done** |
| **ST5** | Mobile checkout card pay UI + errors when not enabled | **Done** |
| **ST6** | Test mode path mock + real; live gate | **Done** |
| **ST7** | Minimal card refund path (manager-triggered) | Deferred / optional for later |
| **ST8** | Acceptance + STATUS close | **Done** |

---

## 4. Relation to Platform Owner billing and station

- SaaS invoices/subscriptions remain on **platform** Stripe.  
- Station / kitchen surface consumes **`paid`** for card; cash uses thin POS (Decision 14).  
- Manager refunds for card go through Connect-aware refund; cooks never initiate.

---

## 5. Acceptance (implementation)

- [x] HQ Connect onboarding + status
- [x] Mock/real test charges; live only when `paymentsEnabled`
- [x] Webhook marks paid once (idempotent)
- [x] Card checkout blocked when payments not enabled
- [x] Application fee on platform
- [x] Android PaymentSheet path (FlutterFragmentActivity + Theme.MaterialComponents)
- [x] Test-mode end-to-end smoke pass (HQ enable → mobile Card → 4242… → paid)

---

## 6. Residual (deferred)

Post-order UX: “How was your order?” survey currently surfaces immediately after the ease-of-use survey / Back to main menu.  
**Desired:** scheduled push (or in-app) notification X minutes after paid status.  
Do **not** change in this slice. Track under post-order experience / notifications.

---

## 7. Out of scope

- Cash drawer / card-present terminal (thin POS Decision 14)  
- Implementing station / kitchen UI  
- Guest checkout without account  
- Live refunds in v1 (optional ST7 later)

---

## 8. Bottom line

**Platform Stripe** bills franchises for software. **Connect per franchise** takes **customer card** payments with an **application fee**. **Cash** is handled by the thin POS (Decision 14).

**Slice closed 2026-07-30** after successful test-mode smoke.
