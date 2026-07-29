# Slice: Stripe Checkout v1 (Platform + Connect)

**Status**: **Locked** (product approved July 29, 2026 — implementation open)  
**Branch**: TBD (`feat/stripe-checkout-v1` when work starts)  
**Authority**: Decision **12** · STATUS · HANDOFF · this file  
**Depends on**: Active `franchiseId` (Decision 11); Platform Owner billing surfaces may already list invoices  
**Pilot**: Test mode for mock + real; live charges only when real franchise Connect-ready  
**Related**: Cash on pickup is Decision **13** / `kitchen-ops-v1` (feature toggle) — **not** Connect

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
Cash on pickup      → No Connect charge; kitchen-ops feature flags (Decision 13)
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
| Cash option | Only if Admin **cashOnPickup** feature on (Decision 13); does not require Connect |
| Application fee | Platform-configured % or flat |
| Card order → kitchen | Status **`paid`** drives auto-print (kitchen-ops) |

---

## 3. Workstreams

| ID | Deliverable | Status |
|----|-------------|--------|
| **ST0** | Docs lock | **Done** |
| **ST1** | Franchise fields: connected account id, status, `paymentsEnabled` | Open |
| **ST2** | HQ Connect onboarding entry + status honesty | Open |
| **ST3** | Create PaymentIntent (Connect + application fee) | Open |
| **ST4** | Webhooks → order paid/failed; idempotent | Open |
| **ST5** | Mobile checkout card pay UI + errors when not enabled | Open |
| **ST6** | Test mode path mock + real; live gate | Open |
| **ST7** | Minimal card refund path (manager-triggered per Decision 13) | Open |
| **ST8** | Acceptance + STATUS close | Open |

---

## 4. Relation to Platform Owner billing and kitchen

- SaaS invoices/subscriptions remain on **platform** Stripe.  
- Kitchen board consumes **`paid`** for card; cash uses kitchen-ops states/flags.  
- Manager refunds for card go through Connect-aware refund; cooks never initiate.

---

## 5. Acceptance (implementation)

- [ ] HQ Connect onboarding + status
- [ ] Mock/real test charges; live only when `paymentsEnabled`
- [ ] Webhook marks paid once (idempotent)
- [ ] Card checkout blocked when payments not enabled
- [ ] Application fee on platform
- [ ] Cash path not implemented inside this slice except coexistence with Decision 13 flags

---

## 6. Out of scope

- Cash drawer / card-present terminal  
- Implementing kitchen UI (see `kitchen-ops-v1.md`)  
- Guest checkout without account  

---

## 7. Bottom line

**Platform Stripe** bills franchises for software. **Connect per franchise** takes **customer card** payments with an **application fee**. **Cash on pickup** is a separate toggled fulfillment mode under kitchen-ops, not a second card architecture.
