# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: August 2, 2026 (~10:50 CDT)  
**Current focus**: Merge `feat/customer-website-v1` when gated; optional domains / POS hardware  
**Active branch**: `feat/customer-website-v1`

## Vision

Multi-tenant white-label Flutter platform: web + mobile + counter station, franchise-scoped.

---

## Completed (high level)

- HQ onboarding, branding, Platform Owner, Admin ops, menu M1–M5
- Mobile Design Tokens; Developer Dashboard
- Customer franchise context (11); Stripe Connect (12)
- Thin POS software pilot (14) on `main`
- **Customer website MVP path** on `feat/customer-website-v1`: bind, menu, **4b pricing**, cart, auth, Connect, HQ QR, order history

---

## Active / next

| Epic | Status |
|------|--------|
| Customer website MVP path | **PASS on feature branch** |
| Merge customer_web → main | **Open** |
| Custom domains | **Open** (optional) |
| Stripe Terminal / printers | **Open** |
| Staff/driver UI, 86 | **Open** |
| CF Node 22 | Before ~2026-10-30 |

---

## Customer website milestones

| Milestone | Status |
|-----------|--------|
| Scaffold + Firebase + shared_core | **Reached** |
| Bind + menu + branding | **Reached** |
| Auth + cart + Connect | **Reached** |
| Hosting + QR / path bind | **Reached** |
| Phase 4b pricing + cart fidelity | **Reached** |
| Shell account + order history | **Reached** |
| Merge to main | **Open** |
| Custom domains | **Open** |

---

## Success criteria (hard release)

- Hybrid location + menu profiles + HQ branding
- Customer bind + auth cart + Connect
- Thin POS software **done**; hardware residual optional
- Customer website **MVP path done** on feature branch — **merge closes software hard-release gate** for website

## How to use

Agents: STATUS + slice; human merge gate for cutover.
