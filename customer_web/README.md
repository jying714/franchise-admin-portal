# customer_web

Franchise-scoped **customer storefront** for online ordering (Flutter web).

Guests browse a bound restaurant, customize menu items, manage a cart, and check out via Stripe Connect. Branding, menu, hours, and layout are driven by per-franchise Firestore config—not hard-coded to one cuisine.

| | |
|---|---|
| **App** | Public storefront |
| **Hosted** | https://franchise-storefront.web.app |
| **Bind URL** | `/f/{franchiseId}` |
| **Package** | Flutter web (`customer_web/`) |
| **Shared domain** | `packages/shared_core` |
| **Firebase project** | `doughboyspizzeria-2b3d2` (and other franchises on the same platform) |

---

## Role in the monorepo

| App | Audience |
|-----|----------|
| **customer_web** | Guests ordering online |
| `mobile_app` | Guests on iOS/Android |
| `web-app` | HQ Owner + Admin ops |
| `pos_app` | Counter / station |
| `packages/shared_core` | Models, Firestore services, franchise branding |

Customer web must stay franchise-scoped: config, menu, cart, and orders live under `franchises/{franchiseId}/…`.

---

## Features

### Ordering
- Category → items → customize dialog (modifier groups, portions, mobile-parity toppings where applicable)
- Auth-gated cart and checkout
- Stripe Connect PaymentSheet / payment intents (`source: 'web'`)
- In-shell checkout on the storefront home; cart as a **side sheet** (end drawer) with badge on the shell chrome

### Storefront shell
- `StorefrontShell` — floating slim top bar (logo, name, Order now, cart badge, account)
- Nested landing under a local `Navigator`
- Cart: `StorefrontShell.openCartSheet()` / `requestCheckout()` (closes drawer, shows in-page checkout, scrolls into view)

### Templates (`config/storefront.templateId`)

| Value | Layout |
|-------|--------|
| `default` (or missing) | Plain MVP home (`StorefrontHomeScreen`) |
| `modern` | Pizzon-inspired landing (`ModernStorefrontHome`) |

**Modern includes:** full-bleed hero, Featured strip (up to 4 photo items), story/hours band, branded category/item cards, full order path, dark footer. HQ picks the template under Restaurant settings → **Website**.

### Config sources
- **Branding** — `FranchiseProvider` → theme primary / logo / app name  
- **Storefront** — `franchises/{id}/config/storefront` (hero, story, photo, `templateId`)  
- **Hours / ops** — `config/store_ops`  
- **Contact** — franchise `address` map, `publicPhone`, etc.  
- **Menu** — franchise `menu_items` / `categories` via `FirestoreService`  
- **Inventory** — `MenuItem.isSellable` (tracked qty at 0 blocks sell-through)

---

## Key paths

```text
customer_web/lib/
  main.dart / app bootstrap + router
  core/router.dart
  widgets/storefront_shell.dart          # chrome + cart drawer + keys
  features/storefront/
    storefront_landing.dart              # templateId resolver
    storefront_template.dart
    templates/modern/modern_storefront_home.dart
  features/home/storefront_home_screen.dart   # default template
  features/menu/                         # categories, items, customize
  features/cart/cart_screen.dart         # embed + branded sheet lines
  features/checkout/checkout_screen.dart
  features/auth/sign_in_screen.dart