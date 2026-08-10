# customer_web

Franchise-scoped **customer storefront** for online ordering (Flutter web).

Guests browse a bound restaurant, customize menu items, manage a cart, and check out via Stripe Connect. Branding, menu, hours, and layout are driven by per-franchise Firestore config.

| | |
|---|---|
| **App** | Public storefront |
| **Hosted** | https://franchise-storefront.web.app |
| **Bind URL** | `/f/{franchiseId}` |
| **Shared domain** | `packages/shared_core` |
| **Firebase** | Platform project (e.g. `doughboyspizzeria-2b3d2`) |

---

## Role in the monorepo

| App | Audience |
|-----|----------|
| **customer_web** | Guests ordering online |
| `mobile_app` | Guests on iOS/Android |
| `web-app` | HQ Owner + Admin ops |
| `pos_app` | Counter / station |
| `packages/shared_core` | Models, services, branding |

Everything is franchise-scoped under `franchises/{franchiseId}/…`.

---

## Features

### Ordering
- Category → items → customize dialog (modifier groups / mobile-parity toppings where applicable)
- Auth-gated cart and checkout
- Stripe Connect (`source: 'web'`)
- Inventory-aware sellability (`MenuItem.isSellable`)
- **Promo codes** at checkout via shared `PromoPricing` (same engine as mobile)

### Shell & cart
- `StorefrontShell` — floating bar: logo, name, Order now, **cart badge**, account
- Cart = **side sheet** (`openCartSheet` / endDrawer), not a second in-page stack
- `CartScreen(embed: true, branded: true)` in the drawer
- Checkout in-shell on the landing; `requestCheckout` closes drawer and scrolls to checkout

### Templates (`config/storefront.templateId`)

| Value | Layout |
|-------|--------|
| `default` (or missing) | `StorefrontHomeScreen` |
| `modern` | `ModernStorefrontHome` — hero, Featured (4-across), story/hours, branded menu cards, footer |

HQ: Restaurant settings → **Website** (template dropdown, hero + story photo upload).

---

## Key paths

```text
customer_web/lib/
  widgets/storefront_shell.dart
  features/storefront/storefront_landing.dart
  features/storefront/templates/modern/modern_storefront_home.dart
  features/home/storefront_home_screen.dart
  features/menu/
  features/cart/cart_screen.dart
  features/checkout/checkout_screen.dart   # PromoPricing apply
  features/auth/sign_in_screen.dart
```

Plans: `docs/plans/customer-web-storefront-shell-v1.md`, `docs/plans/customer-web-template-modern-v1.md`.  
Promos: `docs/slices/promo-system-v1.md`.

---

## Run locally

```powershell
cd C:\projects\franchise-admin-portal\customer_web
flutter pub get
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
```

Open `/f/{franchiseId}` (e.g. `doughboyspizzeria`). Do not commit secrets.

---

## Config contract

```text
franchises/{id}/config/storefront
  templateId, heroImageUrl, heroHeadline, heroSubheadline
  storyBody, storefrontPhotoUrl
franchises/{id}/config/store_ops   # hours, deliveryFee, taxRate
franchises/{id}/promotions         # promo codes (Promo model)
franchises/{id}                    # address, publicPhone, branding fields
```

---

## Non-goals

- Book Now / reservations, blog, multi-page marketing site  
- Guest cart, dual menu trees  
- Pixel-perfect third-party HTML ports  

---

## Deploy

Firebase Hosting target for the storefront (see `firebase.json` / CI). Prefer documented workflows over ad-hoc production deploys.

---

## Agent notes

- No invented schema; quote real files.  
- Shared menu widgets: use `branded: true` only from Modern embeds.  
- Public cart UX goes through `StorefrontShell` only.
- Checkout discounts only via `PromoPricing` — do not hardcode promo codes.
