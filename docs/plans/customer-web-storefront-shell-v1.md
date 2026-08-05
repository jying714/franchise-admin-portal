# customer_web Storefront Shell v1 — Wave 1

**Status:** **COMPLETE** (2026-08-04) — on **main**  
**Authority:** STATUS · HANDOFF · Decisions 11 / 12 / 14 · this plan  
**Related:** `docs/plans/home-page-composition-engine-v1.md` (Wave 2, deferred)

---

## 1. Problem (solved)

Parity core made ordering work, but the public UI felt like stacked Material screens without a persistent restaurant frame.

---

## 2. Product locks (held)

| ID | Lock |
|----|------|
| S1 | One persistent shell for bound franchise |
| S2 | In-panel flow: home → categories → items → customize → cart → checkout → confirmation |
| S3 | Nested in-shell state (not full nested go_router required for v1) |
| S4 | Home sections (hero, story, CTA, footer) |
| S5 | Reuse customize/cart/checkout logic |
| S6 | Read `config/storefront`, branding, `store_ops` |
| S7 | HQ live design studio out of scope (Wave 2) |

---

## 3. Delivered

- `StorefrontShell` + floating chrome  
- In-place menu / cart / checkout / confirmation on `StorefrontHomeScreen`  
- Customize dialog (mobile-parity toppings/portion UI)  
- Cream theme; hero fit; HQ hero + logo upload; structured contact address  
- Footer from store_ops / public contact  

---

## 4. Acceptance

- [x] Bound franchise shows shell + improved home  
- [x] Order path stays in shell frame  
- [x] Categories → items → customize → cart → checkout  
- [x] Cart reachable from shell chrome  
- [x] No Wave 2 studio required  

---

**End of Wave 1 — complete on main.**
