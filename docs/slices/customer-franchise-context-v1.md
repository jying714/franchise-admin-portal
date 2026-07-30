# Slice: Customer Franchise Context v1

**Status**: **COMPLETE on `main`** (implemented + smoke-passed + merged July 29–30, 2026)  
**Branch**: merged; feature branch deleted  
**Authority**: Decision **11** · STATUS · HANDOFF · this file  
**Depends on**: FranchiseProvider, QR/deep link foundations, mobile tokens on `main`  
**Pilot**: Real franchise + mock seeded franchise (both directory-listable)

---

## 1. Problem

Customer app can bind a franchise via QR/deep link foundations and holds `selectedFranchiseId`, but lacked a **complete multi-tenant product path**:

- No reliable **cold start** without a hard-coded default trap
- No first-class **switch restaurant** for signed-in users (QR-only is insufficient)
- No **directory** for signed-out / App Store open / second-tenant QA
- Unclear **cart policy** across franchise changes
- Signed-out **browse vs checkout** rules not productized

---

## 2. Locks (Decision 11 + v1 implementation refinement)

| Topic | Lock |
|--------|------|
| Binary | Hybrid multi-tenant; session = one `franchiseId` |
| Branding | Follows active franchise after bind |
| Acquisition | QR/SMS/links **primary**; directory **required foundation** |
| Bind | One pipeline (`FranchiseBindService`) for link, QR, directory, recents, switcher |
| Landing | No franchise → **SignInScreen** (auth + Browse directory) |
| Signed-out | **Browse menu OK**; **add-to-cart / cart / checkout require auth** (Firestore cart is user-scoped; guest cart deferred) |
| Guest app bar | Title + change restaurant only (no profile/cart/QR clutter) |
| Cart switch | Confirm → clear cart → switch |
| Share QR payload | Prefer `https://franchisehq.io/f/{id}` (parse still accepts `fhq://f/{id}`) |
| Geo | Out of v1 |
| Guest pay | Out of v1 |

---

## 3. Workstreams

| ID | Deliverable | Status |
|----|-------------|--------|
| **CF0** | Docs lock (this file + Decision 11) | **Done** |
| **CF1** | Cold-start: no silent tenant; no franchise → SignIn; deep link / stored id bind | **Done** |
| **CF2** | QR + deep link via bind; cold-start context retry; https share QR | **Done** (OS App Links / AASA polish deferred) |
| **CF3** | Recents (local, max 8) on successful bind | **Done** |
| **CF4** | Change restaurant sheet: current · recents · scan · directory | **Done** |
| **CF5** | Cart non-empty switch: confirm + clear + switch | **Done** |
| **CF6** | Signed-out browse; auth gate add-to-cart / cart / checkout; guest banners | **Done** |
| **CF7** | Directory: `listedInDirectory`; search; QR scan CTA; same bind pipeline | **Done** |
| **CF8** | Mock + real listable / switchable in QA | **Done** (smoke) |
| **CF9** | Post-bind: branding, ingredient reload, MainMenu | **Done** |
| **CF10** | Acceptance smoke + STATUS close | **Done** |

---

## 4. Key mobile paths

| Path | Role |
|------|------|
| `mobile_app/lib/core/services/franchise_bind_service.dart` | Single bind pipeline |
| `mobile_app/lib/features/franchise/franchise_directory_screen.dart` | Public directory + QR entry |
| `mobile_app/lib/features/franchise/change_restaurant_sheet.dart` | Switcher sheet |
| `mobile_app/lib/main.dart` | HomeWrapper session routing; IngredientMetadataProvider reload |
| `packages/shared_core/lib/src/core/utils/qr_utils.dart` | parse/generate franchise QR |

**Web residual:** `OnboardingProgressProviderImpl` `defaultSteps` must include `onboarding_design_branding` so Step 2 survives cold load.

---

## 5. Directory data

- Only franchises with **`listedInDirectory == true`** and safe public fields (name, city, logo, id).
- Rules: public **read** of franchise docs when listed (see deployed `firestore.rules`).
- Mock + real both appear when flagged.

---

## 6. Acceptance (implementation)

- [x] Cold start without franchise → SignIn (not silent Doughboys default)
- [x] QR / https link binds correct franchise and branding (two-franchise smoke)
- [x] Directory search + open uses same bind as link
- [x] Recents update after bind
- [x] Switcher / cart clear confirmed when needed
- [x] Signed-out can browse; add-to-cart / cart / checkout force sign-in
- [x] Mock and real franchises switchable in QA
- [x] No cross-franchise cart merge
- [x] Directory QR scan CTA; share QR https-form
- [x] Merged to `main`; feature branch deleted

---

## 7. Out of scope / deferred

- Map/geo radius  
- Guest cart / guest checkout without account  
- Full Android App Links / iOS Universal Links assetlinks + AASA production verification  
- Multi-location-within-one-franchise store picker  
- Stripe PaymentIntent (see `stripe-checkout-v1.md`)  

---

## 8. Bottom line

**Shipped on `main`:** link/QR/directory **bind pipeline**, cold start without silent tenant, directory foundation, recents/switcher, safe cart clear, signed-out **browse** with **auth-gated cart/checkout**, ingredient reload after bind. Next release epic: **`stripe-checkout-v1`**.
