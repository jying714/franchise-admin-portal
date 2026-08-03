# STATUS.md — Live Project Snapshot

**Last Updated**: August 3, 2026 (~00:25 CDT — storefront shell Wave 1 + composition engine locked)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch (active work)**: **`main`** (next feature: `feat/customer-web-storefront-shell-v1` when coding starts)  
**Main**: HQ Restaurant settings · customer_web MVP + parity core · POS/mobile/HQ pilots  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| HQ / Admin / menu / mobile / POS pilot | **On main** |
| HQ Restaurant settings v1 | **On main** |
| customer_web order + customize parity | **On main** |
| **Storefront shell + nested order UX (Wave 1)** | **Locked — next build** |
| **Home composition engine / HQ studio (Wave 2)** | **Locked deferred** |
| POS hardware · mobile iOS port | **Waiting on equipment** |

---

## Decision locks (2026-08-03) — storefront presentation

### Wave 1 — Public storefront shell (build next)

**Authority:** `docs/plans/customer-web-storefront-shell-v1.md`

| Lock | Choice |
|------|--------|
| Navigation | **Persistent shell**; menu → items → customize → cart → checkout **in-panel** (not leave-site stack of disconnected screens) |
| First impl | Shell + nested navigator (or equivalent stack); full `go_router` nested URLs can follow |
| Home | **Widget-shaped sections** (Hero, Story, CTA, Hours, …) even if order still code-default |
| Config | Read existing `config/storefront` + branding + `store_ops` |
| HQ live designer | **Out of Wave 1** |

### Wave 2 — Home page composition engine (deferred)

**Authority:** `docs/plans/home-page-composition-engine-v1.md`

| Lock | Choice |
|------|--------|
| Model | Ordered **closed widget catalog** (not free HTML/CSS/JS) |
| HQ UX | Split pane: editor left, **live preview** right; add / remove / reorder |
| Integrity | Prop schemas, design tokens, draft → publish, responsive rules inside widgets |
| Templates | **Post-MVP** starter packs |
| Mobile | **Same composition principle post-MVP**; shared schema; **surface-specific renderers**; order-biased mobile templates — not 1:1 web layout |

---

## customer_web parity core (on main)

Pizza/wings customize, cart summary + edit via `cartItemKey`, checkout pickup/delivery + `deliveryAddress` + `customerPhone`.  
**Authority:** `docs/slices/customer-website-v1.md` · `docs/plans/customer-web-parity-brand-storefront-v1.md`

### Residual (after / beside Wave 1)

| Priority | Work |
|----------|------|
| P1 | Promo codes; store_ops delivery fee; out-of-stock options |
| P2 | Directory / change restaurant; loyalty; saved addresses |
| P3 | Custom domains |

---

## Next product focus

1. **Wave 1:** `StorefrontShell` + nested in-panel flow + home visual sections.  
2. Promos / fee residual as needed.  
3. **Wave 2** only after Wave 1 home is widgetized and shippable.  
4. POS hardware + iOS when devices arrive.

**Decision locks:** 11 / 12 / 14 + storefront Wave 1/2 above.

---

**Update this file after significant sessions.**
