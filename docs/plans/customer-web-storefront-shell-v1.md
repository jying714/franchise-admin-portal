# customer_web Storefront Shell v1 — Wave 1

**Status:** **Locked for implementation** (2026-08-03)  
**Branch (when coding):** `feat/customer-web-storefront-shell-v1`  
**Authority:** STATUS · HANDOFF · Decisions 11 / 12 / 14 · this plan  
**Related:** `docs/plans/home-page-composition-engine-v1.md` (Wave 2, deferred) · `docs/plans/customer-web-parity-brand-storefront-v1.md`

---

## 1. Problem

Parity core made ordering work, but the public UI still feels like stacked Material screens:

- `BrandingShell` = simple AppBar  
- Home = solid-color hero + story text + “View menu”  
- Menu opens via `Navigator.push`, leaving the marketing frame  

Owners and guests need a **persistent restaurant site frame** with order flow **inside** it.

---

## 2. Product locks

| ID | Lock |
|----|------|
| S1 | **One persistent shell** (logo, primary nav, cart, account) for bound franchise |
| S2 | **In-panel stack:** home → categories → category items → item detail/customize → cart → checkout → confirmation |
| S3 | Do **not** require full nested `go_router` URLs in v1; shell + nested Navigator (or equivalent) is enough; URLs can follow |
| S4 | Home built as **named section widgets** (Hero, Story, Order CTA, Hours strip, …)—code-default order OK |
| S5 | Reuse existing customize/cart/checkout **logic**; only change mount target (shell body) |
| S6 | Read `config/storefront`, branding, `store_ops` — no new required schema for Wave 1 |
| S7 | **HQ live design studio out of scope** (Wave 2) |

---

## 3. Target UX

```text
┌──────────────────────────────────────────────────┐
│ Logo   Order · Story · Contact      Cart  Account │
├──────────────────────────────────────────────────┤
│                                                  │
│            SHELL BODY (swaps)                    │
│   Home sections | Menu | Detail | Cart | Pay     │
│                                                  │
├──────────────────────────────────────────────────┤
│ Footer: address · phone · hours · links            │
└──────────────────────────────────────────────────┘
```

- **Order online** / nav **Order** → categories (or home order band → same).  
- Browser back / in-app back walks the **inner** stack.  
- Cart icon always available from shell.

---

## 4. Work breakdown

| # | Task | Notes |
|---|------|--------|
| W1.1 | `StorefrontShell` | Replaces ad-hoc full-screen `BrandingShell` for main journey; may wrap or supersede |
| W1.2 | Inner navigation controller | Enum or nested Navigator: home, categories, items, detail, cart, checkout |
| W1.3 | Wire menu screens as body | `MenuCategoryGridScreen` / items / detail without root `push` that drops shell |
| W1.4 | Cart + checkout in shell | Same chrome; optional full-bleed body |
| W1.5 | Home section widgets | Hero, Story, CTA, optional Hours from store_ops; max-width layout |
| W1.6 | Visual pass | Typography, spacing, hero image, no “Franchise App” when bound name exists |
| W1.7 | Story / Contact entry | Simple in-shell panels or scroll targets; full pages OK if still under shell |
| W1.8 | Docs / STATUS | Mark Wave 1 complete when smoke passes |

---

## 5. Explicit non-goals (Wave 1)

- HQ split-pane live preview  
- Add/remove/reorder sections in config  
- Templates  
- Custom domains  
- Mobile home composition  
- Rewriting customize pricing/rules  

---

## 6. Acceptance

- [ ] Bound `/f/{id}` shows shell + improved home (hero/story/CTA)  
- [ ] Order path never loses shell chrome (except intentional auth overlays if needed)  
- [ ] Categories → items → customize → add → cart → checkout works  
- [ ] Cart reachable from shell on every step  
- [ ] Home implemented as discrete section widgets (not one opaque blob)  
- [ ] No Wave 2 studio required to ship Wave 1  

---

## 7. First coding step

**W1.1 + W1.2:** Introduce `StorefrontShell` with an inner stack; mount current `StorefrontHomeScreen` body; change `_openMenu` to push **inner** route/state to category grid instead of root `MaterialPageRoute` that replaces the whole page.

---

**End of Wave 1 plan.**
