# Slice: Customer Website v1 (`customer_web`)

**Status**: **MVP vertical + Phase 4b PASS** (2026-08-02) on `feat/customer-website-v1`  
**App path**: `customer_web/`  
**Live**: https://franchise-storefront.web.app · URL `.../f/{franchiseId}`  
**Authority**: Decisions **11 / 12 / 14** · STATUS · HANDOFF · this file

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
| Pricing | Size `basePrice` + option `upcharge`/`upchargeBySize` **else** size `toppingPrice` per selected add-on |
| HQ | StorefrontLinkCard: copy / open / QR |

---

## 3. Acceptance

- [x] Firebase + shared_core + Hosting
- [x] `/f/{id}` bind + branding + menu
- [x] Auth gate cart/checkout
- [x] Connect pay; POS sees `source: 'web'`
- [x] store_ops hours/tax gate
- [x] HQ URL + QR
- [x] **Phase 4b** line price + customizations on cart
- [x] Cart qty steppers
- [x] Shell cart + sign-in/out + My orders

### Still open (non-blocking for MVP path)

- [ ] Merge to `main`
- [ ] Optional custom domains
- [ ] Extra responsive / SEO polish

---

## 4. Pricing note (Doughboys)

Many add-on `ModifierOption`s have **no** `upcharge` field. Charge comes from selected `SizeData.toppingPrice` (e.g. Antipasta Small 0.85 / Large 1.15) on top of `SizeData.basePrice`.

---

## 5. Out of scope v1

Guest cart · per-franchise Hosting · second menu schema · full mobile parity (loyalty/chat)

---

## 6. Bottom line

**MVP storefront path is complete on the feature branch.** Merge when human approves; optional domains later.
