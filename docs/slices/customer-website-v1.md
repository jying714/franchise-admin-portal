# Slice: Customer Website v1 (`customer_web`)

**Status**: **MVP + parity core on `main`** (2026-08-02)  
**App path**: `customer_web/`  
**Live**: https://franchise-storefront.web.app · URL `.../f/{franchiseId}`  
**Authority**: Decisions **11 / 12 / 14** · STATUS · HANDOFF · `docs/plans/customer-web-parity-brand-storefront-v1.md` · this file

---

## 1. Problem

Shareable https ordering site (QR / HQ) with franchise branding, menu, auth cart, Connect pay, POS intake — without the Admin shell.

---

## 2. Product locks

| Lock | Choice |
|------|--------|
| One Flutter web app | `customer_web` + Hosting target `storefront` |
| Bind | `/f/{franchiseId}` (hash bootstrap for cold path / mobile QR) |
| Browse | Signed-out OK |
| Cart / checkout | Auth required |
| Pay | Connect; `source: 'web'` |
| Pricing | Size `basePrice` + option upcharges **else** size `toppingPrice` |
| Customize | menuProfile-driven; pizza + wings parity with mobile rules |
| Delivery | `deliveryType` lowercase; `deliveryAddress` = `Address` map; `customerPhone` |
| Cart lines | Unique `cartItemKey` on add; edit replaces by key |
| HQ | Restaurant settings → Website / Store ops / Contact |

---

## 3. Acceptance

- [x] Firebase + shared_core + Hosting
- [x] `/f/{id}` bind + branding + menu
- [x] Auth gate cart/checkout
- [x] Connect pay; POS sees `source: 'web'`
- [x] store_ops hours/tax gate
- [x] HQ URL + QR / Restaurant settings Website tab
- [x] Phase 4b line price + customizations on cart
- [x] Cart qty steppers
- [x] Shell cart + sign-in/out + My orders
- [x] **Merge to `main`**
- [x] Pizza full customize (portion, double, cheeses/sauces, remove included, structural)
- [x] Wings 2-portion + dip cups
- [x] Shared line customization summary
- [x] Checkout pickup/delivery + structured address + customerPhone
- [x] Edit cart line replace via cartItemKey

### Still open (parity / brand wave)

- [ ] D0 marketing shell (hero home, Story, Careers, Contact from `config/storefront`)
- [ ] Promo codes
- [ ] Directory / change restaurant
- [ ] Loyalty (feature-flagged)
- [ ] Optional custom domains
- [ ] Pre-seed edit customize from stored groups; out-of-stock disable

---

## 4. Pricing note (Doughboys)

Many add-on `ModifierOption`s have **no** `upcharge` field. Charge comes from selected `SizeData.toppingPrice` on top of `SizeData.basePrice`.

---

## 5. Out of scope v1

Guest cart · per-franchise Hosting · second menu schema · tips · chat · live tracking

---

## 6. Bottom line

**Order path + pizza/wings customize parity core is on `main`.** Next: D0 brand/marketing pages and residual P1 epics from the parity plan.
