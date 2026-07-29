# Slice: Stripe Checkout v1 (Platform + Connect)

**Status**: **Locked** (product approved July 29, 2026 — implementation open)  
**Branch**: TBD (`feat/stripe-checkout-v1` when work starts)  
**Authority**: Decision **12** · STATUS · HANDOFF · this file  
**Depends on**: Active `franchiseId` (Decision 11); Platform Owner billing surfaces may already list invoices  
**Pilot**: Test mode for mock + real; live charges only when real franchise Connect-ready

---

## 1. Problem

Ordering UX exists without a **locked multi-tenant payment architecture**. Product needs:

- Platform revenue from **HQ SaaS**
- Franchise receipt of **customer order** funds
- Platform **take-rate** on orders
- Honest block when a franchise cannot accept payments

---

## 2. Locks (Decision 12)

### Two Stripe surfaces

| Account | Charges |
|---------|---------|
| **Platform Stripe account** | HQ owners — subscriptions, platform invoices, SaaS plans |
| **Connect account per franchise** | End customers — food orders; **application fee** to platform |

```text
Customer order  →  Franchise Connect account  (+ application fee → Platform)
HQ subscription →  Platform Stripe account only
```

### Architecture choice

- **Target:** Stripe **Connect** (destination-style charges + application fee).  
- **Rejected as long-term:** platform merchant-of-record for all food orders.  
- **Pilot (Option C):** Connect-shaped code paths from day one; **test mode** until live; no second permanent checkout architecture.

### Runtime rules

| Rule | Lock |
|------|------|
| Checkout franchise | Always active session `franchiseId` |
| Missing Connect / not ready | **Fail closed** — “Payments not set up” |
| `paymentsEnabled` | True only when connected account can accept charges |
| Application fee | Platform-configured % or flat (product sets value in implementation) |
| Refunds on orders | Connect charge rules; sync order status |
| SaaS refunds | Platform account |

---

## 3. Workstreams

| ID | Deliverable | Status |
|----|-------------|--------|
| **ST0** | Docs lock (this file + Decision 12) | **Done** |
| **ST1** | Franchise fields: connected account id, status, `paymentsEnabled` | Open |
| **ST2** | HQ Connect onboarding entry + status honesty | Open |
| **ST3** | Create PaymentIntent (Connect + application fee) for active franchise | Open |
| **ST4** | Webhooks → order paid/failed; idempotent | Open |
| **ST5** | Mobile checkout pay UI + errors when not enabled | Open |
| **ST6** | Test mode path mock + real; live gate | Open |
| **ST7** | Minimal refund / status sync path | Open |
| **ST8** | Acceptance + STATUS close | Open |

---

## 4. Relation to Platform Owner billing

- Existing platform invoice / subscription **display** remains on **platform** Stripe.  
- This slice does **not** replace SaaS billing with Connect.  
- Order GMV and SaaS fees stay separate.

---

## 5. Acceptance (implementation)

- [ ] HQ can start Connect onboarding and see status
- [ ] Mock franchise: test charge path or honest disabled state
- [ ] Real franchise: test then live when `paymentsEnabled`
- [ ] Paid webhook marks order paid once (idempotent)
- [ ] Checkout blocked when payments not enabled
- [ ] Application fee recorded on platform
- [ ] No long-term single-account-for-all-orders design

---

## 6. Out of scope

- Marketplace payouts complexity beyond Connect destination + fee  
- Split tender / gift cards  
- Full dispute management UI (Dashboard OK for pilot)  
- Changing Decision 11 bind rules  

---

## 7. Bottom line

**Platform Stripe** bills franchises for software. **Connect per franchise** takes customer order payments with an **application fee** to the platform. Implement Connect-shaped checkout only; pilot in test mode until the real franchise is Connect-ready.
