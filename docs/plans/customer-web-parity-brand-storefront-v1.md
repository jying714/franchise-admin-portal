# customer_web Parity + Brand Storefront — Development Plan

**Status:** Plan locked for implementation (2026-08-02)  
**Authority:** Decisions **11 / 12 / 14** · MVP order path on `main` · mobile_app as functional source of truth · franchise branding tokens · one Hosting site + optional custom domains  
**App path:** `customer_web/`  
**Related:** `docs/slices/customer-website-v1.md` · `docs/plans/customer-website-v1-development-plan.md` (Phases 0–12 baseline) · STATUS · HANDOFF

---

## Product statement

> `customer_web` is the **public franchise storefront**: marketing-quality restaurant website **and** full online ordering.  
> **Ordering logic** matches **mobile_app** (categories, profile-aware customize, cart, pickup/delivery, promos, loyalty, bind).  
> **Visual design** is a **branded web experience** (hero, story, map, inviting layout)—not a reskin of the mobile app UI.  
> Long-term, **custom domains** (e.g. `doughboyscarlyle.com`) CNAME to the same Hosting deployment; hostname → `franchiseId` mapping.

---

## 0. Current baseline (already on `main`)

| Area | Status |
|------|--------|
| Scaffold + Firebase + shared_core | Done |
| Path/hash bootstrap + `/f/:franchiseId` bind | Done |
| Google + email auth; cart gated | Done |
| Menu browse (flat categories-from-items) | **Replace** in P0a |
| Basic customize (size, groups, toppings) | **Replace** with full parity in P0b |
| Cart, checkout CardField, Connect PI, `source: 'web'` | Done |
| Order history + detail | Done (enrich later) |
| Hosting `storefront` + HQ storefront URL card | Done |
| Closed banner / responsive grid / empty cart | Done |

**This plan builds on that baseline; do not re-scaffold.**

---

## 1. Locked product decisions

| ID | Decision |
|----|----------|
| A | **Category-first** IA: categories → category items → detail/customize. Optional later desktop master–detail; not all-items-first. |
| B | Customize is **menuProfile-driven**, same rules as mobile. |
| C | **Half / portion** (whole / left / right) when mobile allows it. |
| D | One customize epic: pizza, wings, calzone, sub, salad, dinner, drinks, etc. |
| E | **Delivery** required; match mobile depth first; HQ config for fee/enable/etc. |
| F | **Change restaurant** + directory + cart-clear (P1). |
| G | **One franchise promo** per order. |
| H | **Loyalty now** (feature-flagged); **chat out**. |
| — | Tips **out**. Guest cart **out**. Live tracking **out**. Scheduled orders **out**. |
| — | Categories from **`categories` collection**; hide empty. |
| — | Customer can **remove included** ingredients. |
| — | Extra / double toppings **in scope**. |
| — | Type grouping (Meats / Veggies / …) via ingredient **type metadata**, not hard-coded web-only lists. |
| Domain | Long-term custom domain → `customer_web` Hosting. |
| Hero | **Hero image URL** in franchise config. |
| Content | **Story, Careers (hiring), Contact, map, FAQ-style blocks** in this wave (franchise-configurable where possible). |

---

## 2. Design system (web-native, not mobile clone)

Inspired by doughboyscarlyle.com **structure and feel**, not a pixel clone.

### 2.1 Global chrome

- **Sticky partial app bar** over hero on home: logo left; links (Menu, Our Story, More…); **Sign in** / account; primary **Order online**.
- On inner pages (menu, cart, checkout): solid/blurred bar using franchise primary; cart badge; account menu.
- **Footer:** logo, Menu / Story / Hiring / Contact, address, phone, email, hours snippet, accessibility note, “Powered by …” optional.

### 2.2 Home (bound franchise) — content blocks

1. **Hero:** full-bleed image (`heroImageUrl`), dark gradient overlay, headline + subcopy, **Order online** CTA.  
2. **Featured:** horizontal cards from menu (flagged items or first N by category)—optional if data exists.  
3. **Welcome / Story teaser:** storefront photo + short about + link to full Story.  
4. **Fresh / menu tease:** copy + Explore menu.  
5. **Order online band:** pickup / delivery / dine-in messaging (dine-in = info only unless POS tables later).  
6. **Gallery:** configurable image URLs or featured item photos.  
7. **Visit us:** hours from `store_ops`, address, phone.  
8. **Reviews:** optional static/config quotes (no forced Google scrape in v1).  
9. **Service icons:** Takeout / Delivery / Dine-in.  
10. **Loyalty band:** if feature on.  
11. **FAQ accordion:** config list of Q&A.  
12. **Location:** embedded map (Google Maps link or embed URL) + Get directions + Order online.

### 2.3 Visual tokens

- Colors/logo/name from existing franchise branding (`primaryColorHex`, `secondaryColorHex`, `logoUrl`, `appName`).  
- Typography: web-friendly scale (display for hero, clear section titles)—not Material dense mobile.  
- Spacing: generous sections, max content width ~1100–1200px, full-bleed heroes.  
- Buttons: filled primary for Order; text/outline secondary.

### 2.4 Explicit design non-goals

- Not cloning Owner.com SEO `/tags/*` or `/places/*` farms.  
- Not copying mobile bottom-nav / modal-only chrome.  
- Not requiring identical spacing to any one franchise’s old site.

---

## 3. Data & HQ configuration

### 3.1 Existing (reuse)

| Path / field | Use |
|--------------|-----|
| `franchises/{id}` | name, branding, `storefrontDomain`, public contact if present |
| `franchises/{id}/config/ui_config` or branding fields | colors, logo, appName |
| `franchises/{id}/config/store_ops` | hours, taxRate, dayClosed, delivery-related if any |
| `franchises/{id}/categories` | id, name, imageUrl, sortOrder, active |
| `franchises/{id}/menu_items` | full item + modifierGroups, sizes, included, profile |
| Ingredients + types | type labels for Meats/Veggies/… |
| `menu_profile` / wings profile | rule source |
| Promos collection (franchise) | codes, discounts |
| Loyalty collections / feature flags | as mobile |
| User addresses | as mobile |
| Orders | `source: 'web'`, line items, totals |

### 3.2 New / extended storefront config (HQ-editable)

Prefer **one doc** e.g. `franchises/{id}/config/storefront` (or fields on existing public profile)—exact path chosen to match architecture doc; **no invented parallel trees without STATUS update**.

| Field | Purpose |
|-------|---------|
| `heroImageUrl` | Home hero |
| `heroHeadline` / `heroSubheadline` | Optional overrides |
| `storyMarkdown` or `storyHtml` / plain `storyBody` | Our Story page |
| `storefrontPhotoUrl` | Welcome section building photo |
| `galleryImageUrls[]` | Gallery |
| `faq[]` { question, answer } | FAQ |
| `careersBlurb` + `careersFormEnabled` or external careers URL | Hiring |
| `publicPhone` / `publicEmail` / `publicAddress` | Contact (fallback franchise) |
| `mapEmbedUrl` or lat/lng | Map |
| `featuredItemIds[]` | Featured row |
| `reviews[]` { quote, author, stars } | Optional |
| `deliveryEnabled` | Toggle |
| `deliveryFee` | Flat fee (match mobile; extend later) |
| `deliveryMinimum` | Optional |
| `loyaltyEnabled` | Mirror feature flag if not already |

**HQ UI:** Storefront / Store ops screen: hours, tax, delivery, hero, story, contact, FAQ—replace or absorb “tax/hours only on quicklinks.”

### 3.3 Domain mapping

- `franchises/{id}.storefrontDomain` **or** `domain_index/{hostname}` → `franchiseId`.  
- Router: if host matches mapped domain, bind that franchise **without** requiring `/f/{id}` (path still works).  
- Firebase Hosting: add custom domain on **storefront** site.

---

## 4. Routing (target)

| Route | Screen |
|-------|--------|
| `/` | Unbound: directory / “open link”; **bound domain:** Home |
| `/f/:franchiseId` | Bind → Home (or redirect to `/` when domain-bound) |
| `/menu` | Category grid |
| `/menu/c/:categoryId` | Items in category |
| `/menu/item/:itemId` | Detail + customize |
| `/cart` | Cart |
| `/checkout` | Checkout (auth) |
| `/orders` | History (auth) |
| `/orders/:orderId` | Detail (auth) |
| `/sign-in` | Auth |
| `/account` | Profile / loyalty entry (auth) |
| `/story` | Our Story |
| `/careers` | Hiring |
| `/contact` | Contact + map |
| `/rewards` or account section | Loyalty (if enabled) |

Hash strategy + bootstrap retained unless path strategy is re-proven; custom domain must keep cold-start bind reliable.

---

## 5. Epic breakdown (granular)

### Epic D0 — Brand shell & marketing pages

**Goal:** Bound franchise feels like a restaurant site.

| # | Task | Detail |
|---|------|--------|
| D0.1 | Storefront theme | TextTheme + ColorScheme from franchise branding; section spacing; max-width layout helpers |
| D0.2 | `StorefrontAppBar` | Logo, nav links, Sign in, Order online; transparent-over-hero variant |
| D0.3 | `StorefrontFooter` | Links, address, phone, hours, legal |
| D0.4 | Home hero | `heroImageUrl`, headlines, CTA → `/menu` |
| D0.5 | Home sections | Welcome, menu tease, order band, gallery, visit hours, services, loyalty teaser, FAQ, location |
| D0.6 | Story page | Full story from config |
| D0.7 | Careers page | Blurb + mailto/external or simple form (email to `publicEmail`) |
| D0.8 | Contact page | Address, phone, email, map, hours, Order CTA |
| D0.9 | Load storefront config | Provider or one-shot fetch with FranchiseProvider |
| D0.10 | HQ fields (minimal) | heroImageUrl, story, contact, FAQ list—can land with D0 or HQ epic in parallel |

**Acceptance:** Bound `/f/doughboys…` shows hero + sections; Story/Contact/Careers reachable; mobile-like chrome gone from home.

---

### Epic P0a — Category-first menu

| # | Task | Detail |
|---|------|--------|
| P0a.1 | Fetch `categories` | sortOrder, image, name; filter inactive |
| P0a.2 | Category grid screen | `/menu` — cards with image/name |
| P0a.3 | Hide empty | Category with zero visible items hidden |
| P0a.4 | Category items screen | `/menu/c/:id` — items for that category only |
| P0a.5 | Item card web | Image, name, price from, allergens snippet; tap → customize |
| P0a.6 | 86 / visibility | Respect archived, hideInMenu, out-of-stock if mobile does |
| P0a.7 | Closed banner | Keep on menu surfaces |
| P0a.8 | Featured on home | Optional: `featuredItemIds` or top sellers |

**Acceptance:** No all-items single scroll as primary path; empty categories hidden.

---

### Epic P0b — Full customize parity

**Source of truth:** `mobile_app/lib/widgets/customization/*` especially `customization_modal.dart`, portion, optional_addons, wings_*, sauce selectors, size_dropdown, current_ingredients.

| # | Task | Detail |
|---|------|--------|
| P0b.1 | Profile detection | effective menuProfile / item flags |
| P0b.2 | Size selection | sizes + basePrice + toppingPrice ladder |
| P0b.3 | Structural groups | Crust / cook / cut (label-only); **exclude** from billable topping payload like mobile |
| P0b.4 | Type-grouped add-ons | Group options by ingredient type label (Meats, Veggies, Cheeses, …) |
| P0b.5 | maxFree | Per group / profile rules |
| P0b.6 | Included ingredients | List + **remove**; removed reflected in cart payload |
| P0b.7 | Portion / half | Whole / left / right when `allowsPortion`; portion on toppings |
| P0b.8 | Extra / double | Same state model as mobile |
| P0b.9 | Wings | Portions, sauces, free cups / dip rules, wings optional addons |
| P0b.10 | Sauce / dressing / drinks flavor | Match mobile selectors for those profiles |
| P0b.11 | Live price | Footer total = base + paid toppings − free allowance + extras |
| P0b.12 | Qty on customize | Add N to cart |
| P0b.13 | Cart payload | Shape compatible with POS/kitchen (groups, labels, portions, removed included)—mirror mobile fields |
| P0b.14 | Validation | Required groups, min/max selectable |
| P0b.15 | UI | Full-page web layout (sticky price bar); not mobile bottom sheet clone |

**Acceptance:** Pizza (half + meats/veggies groups + remove included), wings, and at least one other profile smoke vs mobile totals/payload.

---

### Epic P1a — Delivery + addresses + HQ store ops

| # | Task | Detail |
|---|------|--------|
| P1a.1 | Audit mobile checkout | Document exact delivery fields, fee, eligibility |
| P1a.2 | Checkout fulfillment | Pickup vs Delivery toggle |
| P1a.3 | Address book | List/add/edit/select user addresses (same collections as mobile) |
| P1a.4 | Fee + minimum | From config/mobile rules; show on totals |
| P1a.5 | Closed / open | Same `store_ops`; block order when closed |
| P1a.6 | Order document | `fulfillmentType`, address snapshot, deliveryFee |
| P1a.7 | HQ Store ops / Storefront | tax, hours, deliveryEnabled, deliveryFee, deliveryMinimum, public contact |
| P1a.8 | POS visibility | Delivery orders readable on board (existing fields) |

**Acceptance:** Delivery order with fee appears in POS; pickup unchanged.

---

### Epic P1b — Promos

| # | Task | Detail |
|---|------|--------|
| P1b.1 | Code entry on checkout | One active code |
| P1b.2 | Validate | Franchise-scoped rules (%, $ off, min subtotal, active dates)—match mobile |
| P1b.3 | Apply to totals | Discount line; prevent stacking |
| P1b.4 | Order fields | promoCode, discountAmount |
| P1b.5 | Clear / change code | UX |

---

### Epic P1c — Directory & change restaurant

| # | Task | Detail |
|---|------|--------|
| P1c.1 | Directory | List orderable franchises (public fields) |
| P1c.2 | Change restaurant | From app bar / account |
| P1c.3 | Cart clear confirm | If cart non-empty |
| P1c.4 | Rebind | New franchiseId + theme reload |
| P1c.5 | Domain host bind | hostname → franchise without `/f/` |

---

### Epic P2 — Loyalty

| # | Task | Detail |
|---|------|--------|
| P2.1 | Feature flag | Hide if off |
| P2.2 | Balance display | Account / home band |
| P2.3 | Earn | Same as mobile on paid web orders |
| P2.4 | Redeem | Checkout option if mobile supports |
| P2.5 | Join / rewards page | Copy + CTA |

---

### Epic D1 — Domain & cutover

| # | Task | Detail |
|---|------|--------|
| D1.1 | Hosting custom domain | `doughboyscarlyle.com` (and www) on storefront site |
| D1.2 | Firestore domain map | Write mapping; router bind |
| D1.3 | SSL / DNS | CNAME docs for franchisees |
| D1.4 | HQ publish | Show custom domain URL when set |
| D1.5 | Owner.com sunset | Redirect menu/order URLs when ready (franchise ops) |

---

### Epic Q — Polish & parity QA

| # | Task | Detail |
|---|------|--------|
| Q.1 | Responsive | Home, menu, customize, checkout 375–1440px |
| Q.2 | A11y | Focus, contrast, form labels |
| Q.3 | Stripe matrix | success / decline / closed / payments disabled |
| Q.4 | Dual path | Web order ↔ POS board |
| Q.5 | Compare mobile | Same pizza config → same price within rounding |
| Q.6 | Docs | STATUS, HANDOFF, slice, this plan checkboxes |

---

## 6. Suggested implementation order

```text
D0.1–D0.4     Brand shell + hero home (config stubs OK)
P0a           Category-first menu
P0b           Full customize (largest)
D0.5–D0.10    Remaining home sections + Story/Careers/Contact
P1a           Delivery + HQ store ops fields
P1b           Promos
P1c           Change restaurant + domain bind
P2            Loyalty
D1            Custom domain cutover
Q             Hardening + docs lock
```

**Thin parallel:** HQ storefront field editors can track D0/P1a so content isn’t blocked on code-only stubs.

---

## 7. Explicit non-goals (this wave)

- Guest cart  
- Tips  
- Chat / support messaging  
- Live driver tracking  
- Scheduled orders  
- Owner.com-style mass SEO tag/place pages  
- Second menu/modifier system  
- Per-franchise separate Hosting projects  
- Exact mobile visual clone  
- Exact pixel clone of doughboyscarlyle.com  

---

## 8. Acceptance criteria (wave complete)

1. Custom or `/f/{id}` URL loads **branded home** (hero, story teaser, hours, map/contact path).  
2. **Menu → category → items → full customize** (pizza half + type groups + remove included; wings rules).  
3. Cart → checkout **pickup or delivery** with correct fee/tax; **one promo**; pay via Connect; `source: 'web'`.  
4. POS sees order with modifiers/fulfillment.  
5. Loyalty visible when enabled.  
6. Change restaurant clears cart with confirm.  
7. Story / Careers / Contact work from config.  
8. HQ can set hero, story, hours, tax, delivery fee/enable.  
9. Domain mapping documented; ready to point `doughboyscarlyle.com` at storefront.  
10. STATUS + HANDOFF updated; smoke checklist signed.

---

## 9. Risk register

| Risk | Mitigation |
|------|------------|
| Customize modal complexity | Port rules from mobile in slices; golden-price tests per profile |
| Delivery rules thin on mobile | Match actual code; HQ flat fee; no fake zones |
| Config schema drift | Single storefront/store_ops doc; update architecture note |
| Domain + hash routing | Keep bootstrap/redirect; test custom domain cold load |
| Content empty at launch | Sensible empty states; HQ required fields for go-live |

---

## 10. First coding step

**D0.2 + D0.4:** `StorefrontAppBar` + Home hero using branding + optional `heroImageUrl` (fallback solid primary), **Order online** → menu route—then **P0a** category grid.

**Recommended branch:** `feat/customer-web-parity-v1` off current `main`.

---

## 11. Reference — current public site structure (Owner.com)

Indexed paths for design/content inspiration (not to clone pixel-for-pixel):

| Path | Role |
|------|------|
| `/` | Home: hero, featured, story, gallery, hours, reviews, FAQ, map |
| `/menu` | Online menu + order |
| `/story` | Our Story |
| `/careers` | Hiring |
| Nav | Menu, Events, Our Story, More, Sign in, Order online |
| Footer | Menu, We’re Hiring, Gift Cards, Contact Us |

**Ops facts (Carlyle example):** 960 Fairfax St, Carlyle IL 62231 · (618) 594-6209 · hours as published on site · takeout + delivery + dine-in messaging.

---

**End of plan.** Update STATUS/HANDOFF when epics start; check boxes as tasks complete.
