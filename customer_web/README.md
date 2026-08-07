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
HQ writes storefront fields from:
web-app/lib/admin/hq_owner/screens/website_settings_panel.dart

Run locally
From monorepo root (or customer_web/ if that is your habit):
PowerShellcd C:\projects\franchise-admin-portal\customer_web

flutter pub get

flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
Open a bound franchise, for example:
http://localhost:xxxxx/f/doughboyspizzeria
Use a real STRIPE_PK test publishable key from the project’s Stripe setup. Do not commit secrets.
Useful defines

DefinePurposeSTRIPE_PKStripe publishable key (required for checkout)
Station/POS dart-defines are not used by customer_web.

Template switch (ops)
Firestore (or HQ Website tab):
textfranchises/{franchiseId}/config/storefront
  templateId: "modern" | "default"
  heroImageUrl, heroHeadline, heroSubheadline
  storyBody, storefrontPhotoUrl
Save in HQ → reload storefront. Default layout must remain unchanged when templateId is absent or default.

Cart & checkout contract

User signed in (Firebase Auth).
Cart stream: FirestoreService.getCart(uid, franchiseId: …).
Shell badge counts line quantities.
Side sheet uses CartScreen(embed: true, branded: true, onCheckout: StorefrontShell.requestCheckout).
Checkout is in-shell on the landing (_showingCheckout), not a long-lived full-route replacement for the main marketing page.
Orders should keep source: 'web' and franchise scoping.


Branding
Live path matches the rest of the platform:

Franchise doc / UI config → FranchiseProvider
ThemeData / colorScheme.primary for accents on Modern cards, hero CTA, cart sheet, footer

Do not invent parallel global theme models. Prefer DesignTokens / FranchiseProvider patterns already used by web-app and mobile.

Non-goals

Reservation / “Book Now” forms
Blog, team, multi-page marketing site
Guest (signed-out) cart
Dual menu trees
Pixel-perfect port of third-party HTML/CSS (Pizzon is visual intent only)


Deploy
Hosting is typically the franchise-storefront Firebase Hosting target (see repo workflows / firebase.json). Prefer CI (deploy-web or storefront-specific workflow) over ad-hoc deploys unless documented otherwise.
Confirm the correct hosting target and project in firebase.json / GitHub Actions before production push.

Related docs


DocTopicSTATUS.md / HANDOFF.mdLive checklistdocs/plans/customer-web-storefront-shell-v1.mdWave 1 shelldocs/plans/customer-web-template-modern-v1.mdModern templatedocs/architecture/firestore-per-franchise-config.mdFranchise config layoutdocs/plans/mvp-ops-inventory-v1.mdSellability / stockRoot README.mdMonorepo overview

Agent / contributor notes

Quote real files; do not invent schema fields.
Prefer surgical UI changes; keep default template behavior when touching shared menu widgets (branded: true only from Modern).
Cart chrome for the public storefront goes through StorefrontShell (sheet), not a second in-page cart stack.
Human remains the merge gate for config, schema, and architecture changes.