# Slice: Mobile Design Tokens v1

**Status**: **Locked** (map approved; implementation not started)  
**Branch**: `feat/mobile-design-tokens-v1`  
**Authority**: this file · STATUS · `docs/MOBILE_DYNAMIC.md` · HQ Design & Branding (seeds only)  
**Scope**: **mobile_app customer-facing** screens and widgets only — **not** web-app / HQ / Admin / Developer  
**Locked map**: July 28, 2026 (~23:00 CDT) — human approved as-is  
**Repo**: https://github.com/jying714/franchise-admin-portal

---

## 1. Problem

Customer mobile UI mixes:

- Franchise-aware `UiConfig.primaryColor` / `secondaryColor`
- Static `DesignTokens` hex fallbacks
- Hard-coded `Colors.*` / one-off hex in screens and widgets

That makes white-label inconsistent and invites HQ to request per-button colors. Expanding Firestore/HQ with dozens of color fields would be unmaintainable and produce poor contrast.

**Goal:** normalize mobile to a **small semantic role vocabulary**, driven by **HQ brand seeds only**, with everything else **derived at runtime**.

---

## 2. Product rules (do not reopen without human)

### HQ may edit (seeds only)

| Seed | Source today |
|------|----------------|
| Primary color | Franchise branding / `FranchiseProvider` → `UiConfig.primaryColor` |
| Secondary color | Franchise branding / `UiConfig.secondaryColor` |
| App name | Franchise branding |
| Logo URL / assets | Franchise branding |
| Optional later | Surface mode preset (Light / Soft tint / Dark) — **not** freeform per-widget colors |

### HQ must not edit

- Per-screen or per-widget colors (cart trash, heart, qty stepper, dialog labels, etc.)
- Status chip colors (order lifecycle meaning)
- Social provider brand colors (Facebook, etc.)
- Fixed feedback colors (`error`, `success`, `warning`, `info`) except by product-wide design change

### Architecture rules

```
HQ seeds (primary, secondary, appName, logo)
  → Runtime ColorScheme / semantic getters (derive)
    → Screens & widgets reference roles only
```

| Rule | Lock |
|------|------|
| Persist in Firestore | Seeds only — **not** 15–80 hex fields |
| `DesignTokens` static color consts | Remain **defaults/fallbacks**; do not explode with new per-widget fields |
| `FranchiseProvider` | Single franchise-scoped branding SoT; **no** `FranchiseProvider()` zero-arg |
| New DesignTokens members | Prefer theme/`ColorScheme` derivation over inventing static getters |
| Web-app | Out of scope for this slice (may share seeds later; separate work) |
| Menu / modifier schema | No changes |

### Approved decisions (D1–D8)

| ID | Topic | Lock |
|----|--------|------|
| **D1** | App bar | `primary` background + `onPrimary` title/icons (matches current `FranchiseAppBar`) |
| **D2** | Favorite heart | Alias `favorite` → **`error`** when active; inactive → `onSurfaceVariant` / outline |
| **D3** | Price text (item, cart, totals) | **`onSurface`** (not primary) |
| **D4** | Status chips | Fixed `success` / `warning` / `info` / `error` / neutral only |
| **D5** | Category card border | **`primary`** |
| **D6** | Category title on photo | Text-on-media ≈ white / `onPrimary` (not `onSurface`) |
| **D7** | Social provider colors | Fixed provider brands; never franchise secondary |
| **D8** | HQ editable set | primary, secondary, appName, logo only |

---

## 3. Semantic vocabulary (canonical)

### Surfaces

| Role | Meaning |
|------|---------|
| `background` | Page / scaffold fill |
| `surface` | Cards, dialogs, sheets |
| `surfaceContainer` | Nested panels (ingredient tiles, QR block, sub-cards) |
| `outline` | Borders, dividers, unselected control rings |

### Content

| Role | Meaning |
|------|---------|
| `onBackground` | Text on page background when distinct from surface |
| `onSurface` | Primary body / title text on surface |
| `onSurfaceVariant` | Labels, captions, hints, secondary lines |

### Brand (from HQ seeds + contrast)

| Role | Meaning |
|------|---------|
| `primary` | Brand fill: CTA, selected, app bar, key accents |
| `onPrimary` | Text/icons on primary |
| `secondary` | Secondary brand accent (sparingly) |
| `onSecondary` | Text/icons on secondary |

### Feedback (fixed — not HQ)

| Role | Meaning |
|------|---------|
| `error` / `onError` | Errors, destructive emphasis, active favorite |
| `success` | Completed / delivered / positive |
| `warning` | Pending / caution / stars (optional) |
| `info` | In-progress / neutral informational |

### Component aliases (still derived — not stored)

| Alias | Resolves to |
|-------|-------------|
| `cta` | `primary` fill + `onPrimary` label |
| `ctaMuted` | Outline / transparent fill + `primary` label (+ `outline` border) |
| `destructive` | `error` (text, icon, or outline button) |
| `favorite` | Active → `error`; inactive → `onSurfaceVariant` |

### Non-color (existing DesignTokens — out of color map)

Typography, radii, spacing, elevation, animation durations remain in `DesignTokens` as today. This slice is **color semantics only**.

### Not tokens (do not HQ-edit)

| Item | Handling |
|------|----------|
| Image assets / logo URLs | Branding assets, not color roles |
| Shadow / image scrim | Fixed black @ alpha for readability |
| Shimmer base/highlight | Fixed neutrals |
| Facebook/Google button chrome | Provider brand fixed colors |

---

## 4. Runtime derivation (implementation intent)

**Do not implement in the map-only lock; this is the intended code shape for later workstreams.**

1. Read seeds: `FranchiseProvider` / `UiConfig.primaryColor` / `secondaryColor` (fallback `DesignTokens.*Hex`).
2. Build `ColorScheme` (e.g. `ColorScheme.fromSeed` + hand-tuned surface/outline if seed looks poor).
3. Map:
   - `background`, `surface`, `onSurface`, `outline`, `primary`, `onPrimary`, …
   - `surfaceContainer` ← slight elevaton/tint of `surface`
   - `onSurfaceVariant` ← muted onSurface or scheme `onSurfaceVariant`
   - `error` / `success` / `warning` / `info` ← fixed defaults (current DesignTokens feedback hexes acceptable)
4. Inject via `ThemeData.colorScheme` at mobile `MaterialApp` / franchise theme rebuild.
5. Widgets use `Theme.of(context).colorScheme.*` (or thin `AppColors` wrapper) — **not** raw `Colors.blue`.

**Contrast:** `onPrimary` / `onSecondary` must meet readable contrast against seeds; reject or auto-adjust in HQ save later (optional polish).

---

## 5. Mobile customer token map (complete)

Authority inventory of **customer-facing** `mobile_app` surfaces. Every element maps to the vocabulary above.

### 0. Global shell / chrome

| Screen / element | Role | Notes |
|------------------|------|--------|
| Scaffold / page background | `background` | All customer scaffolds |
| Default card / sheet / dialog panel | `surface` | |
| Nested panel (tiles inside cards, QR block, ingredient rows) | `surfaceContainer` | |
| Borders, dividers, unselected control rings | `outline` | Replace hard-coded greys where used as chrome |
| Primary body text | `onSurface` | |
| Labels, captions, hints, secondary lines | `onSurfaceVariant` | |
| Text on pure page bg when needed | `onBackground` | Often same as `onSurface` in light mode |
| Primary brand fill (selected, key CTA) | `primary` | Franchise seed |
| Text/icons on primary fill | `onPrimary` | Contrast-derived |
| Secondary brand accent | `secondary` | Franchise seed; use sparingly |
| Text on secondary fill | `onSecondary` | |
| App bar background | `primary` | Matches `FranchiseAppBar` default today |
| App bar title / leading / action icons | `onPrimary` | |
| App bar bottom hairline | `outline` | |
| Cart badge background | `error` (preferred) or `secondary` | Attention; not HQ |
| Cart badge count text | `onError` / `onSecondary` | Match badge fill |
| Loading shimmer base / highlight | fixed neutrals | Non-brand |
| Shadow / scrim under images | fixed black @ alpha | Not HQ; not `primary` |
| Snackbar success | `success` + light on-color | Fixed |
| Snackbar error | `error` / `onError` | Fixed |
| Offline / global error boundary text | `onSurface` + `error` icon | |

**Files:** `main.dart` theme, `widgets/header/franchise_app_bar.dart`, `widgets/header/cart_icon_badge.dart`, `widgets/header/profile_icon_button.dart`, `core/widgets/global_error_boundary.dart`, `widgets/loading_shimmer_widget.dart`, `widgets/empty_state_widget.dart`.

---

### 1. Splash

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` (preferred) or `primary` | Prefer neutral shell unless branded splash chosen |
| Logo | asset / network | No color token |
| Spinner | `primary` | |

**File:** `features/splash/splash_screen.dart`

---

### 2. Auth (sign-in / sign-up / login)

| Element | Role | Notes |
|---------|------|--------|
| Page background | `background` | |
| Form card | `surface` | |
| Field fill | `surfaceContainer` or `surface` | |
| Field border | `outline` | Focus ring: `primary` |
| Labels / hints | `onSurfaceVariant` | |
| Input text | `onSurface` | |
| Primary submit (Sign in / Create account) | `cta` → `primary` + `onPrimary` | |
| Secondary / text links | `primary` | |
| Error under field | `error` | |
| Social buttons container | `surface` + `outline` | |
| Facebook / Google chrome | **Fixed provider colors** | D7 — never franchise secondary |
| Divider “or” text | `onSurfaceVariant` | |

**Files:** `features/auth/sign_in_screen.dart`, `features/auth/sign_up_screen.dart`, `features/user_accounts/login_screen.dart`, `widgets/social_sign_in_buttons.dart`, `features/user_accounts/complete_profile_dialog.dart`

---

### 3. Home / Main menu (categories host)

| Element | Role | Notes |
|---------|------|--------|
| Page background | `background` | |
| App bar | `primary` / `onPrimary` | |
| Promo banner chrome (border if any) | `outline` | Image is content |
| Banner overlay scrim | fixed black @ alpha | Readability only |
| Category grid gap | spacing only | Non-color |
| **Category card border** | `primary` | D5; current `CategoryCard` |
| Category card fill | transparent over image | |
| Category name on image | `onPrimary` (or pure white) | D6 text-on-media |
| Category description on image | `onPrimary` @ lower opacity | |
| Empty / error state icon | `onSurfaceVariant` / `error` | |
| Order-experience prompt banner (if shown) | `surfaceContainer` + `onSurface` | CTA: `cta` |

**Files:** `features/main_menu/main_menu_screen.dart`, `features/home/home_screen.dart`, `widgets/categories/category_grid.dart`, `widgets/categories/category_card.dart`, `widgets/banner/banner_carousel.dart`, `widgets/banner/promo_banner_card.dart`, `widgets/banner/banner_action_handler.dart`

---

### 4. Category screen (items in a category)

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| App bar | `primary` / `onPrimary` | |
| Promo strip (when present) | image + optional `outline` | Collapse when empty (existing product rule) |
| List / grid background | `background` | |
| Empty state | `onSurfaceVariant` | |

**File:** `features/category/category_screen.dart`

---

### 5. Menu item card (shared)

| Element | Role | Notes |
|---------|------|--------|
| Card background | `surface` | |
| Card border | `outline` | Optional; keep subtle |
| Item title | `onSurface` | |
| Description / meta | `onSurfaceVariant` | |
| Price | `onSurface` | D3 — **not** primary |
| Heart (favorite) active | `favorite` → `error` | D2 |
| Heart inactive | `onSurfaceVariant` | |
| Add to cart button bg | `cta` → `primary` | |
| Add to cart label | `onPrimary` | |
| Customize button bg | `ctaMuted` | transparent/`surface` + `outline` |
| Customize label | `primary` | |
| Quantity − / value / + | `onSurface`; active icons may use `primary` | |
| Disabled add (price 0 / must customize) | muted `onSurfaceVariant` | Hide or disable per existing rules |
| Dietary / allergen chips | `surfaceContainer` + `onSurfaceVariant` | Alert-level allergen → `warning` / `error` if needed |

**Files:** `widgets/menu_item_card.dart`, `widgets/add_to_cart_button.dart`, `widgets/customize_and_add_to_cart_button.dart`, `widgets/favorite_button.dart`, `widgets/quantity_stepper.dart`, `widgets/dietary_allergen_chips_row.dart`, `widgets/included_ingredients_preview.dart`, `widgets/menu_item_image.dart`, `widgets/network_image_widget.dart`

---

### 6. Item detail screen

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| App bar | `primary` / `onPrimary` | |
| Hero image area | content | Scrim fixed if needed |
| Title | `onSurface` | |
| Description | `onSurfaceVariant` | |
| Price | `onSurface` | D3 |
| Heart | `favorite` | D2 |
| Qty stepper | same as menu item card | |
| Add to cart | `cta` / `onPrimary` | |
| Customize | `ctaMuted` / `primary` text | |
| Included ingredients preview text | `onSurfaceVariant` | |

**File:** `features/menu/item_screen.dart`

---

### 7. Customization modal (menu item selection)

| Element | Role | Notes |
|---------|------|--------|
| Dialog / sheet background | `surface` | |
| Header title | `onSurface` | |
| Header close icon | `onSurfaceVariant` | |
| Section headers (Current toppings, Order details, etc.) | `onSurface` (weight) | |
| Helper / “removed” notes | `onSurfaceVariant` | |
| Body / option names | `onSurface` | |
| Ingredient / option tile bg | `surfaceContainer` | |
| Tile selected border / check | `primary` | |
| Tile unselected border | `outline` | |
| Portion circles (left/whole/right) selected | `primary` + `onPrimary` | |
| Portion circles unselected | `outline` + `onSurface` | |
| Regular / Double selected | `primary` + `onPrimary` | |
| Regular / Double unselected | `outline` + `onSurface` | |
| Add control | `primary` | |
| Remove control | `destructive` → `error` | |
| Size dropdown field | `surface` + `outline`; value `onSurface` | |
| Cost / upcharge labels | `onSurfaceVariant` | |
| Wings portion / dip selectors | same tile rules | |
| Optional add-ons “Click to add” chip | `outline` + `onSurface`; active `primary` | |
| Checkbox / radio active | `primary` | |
| Checkbox / radio inactive | `outline` | |
| Bottom bar background | `surface` or `surfaceContainer` | |
| “Total” label | `onSurfaceVariant` | |
| Price total | `onSurface` | D3; strong weight OK |
| Cancel | text / `onSurfaceVariant` | |
| Add to cart (footer) | `cta` / `onPrimary` | |
| Validation error text | `error` | |

**Files:** `widgets/customization/customization_modal.dart`, `widgets/customization/header.dart`, `widgets/customization/bottom_bar.dart`, `widgets/customization/current_ingredients.dart`, `widgets/customization/optional_addons_group.dart`, `widgets/customization/checkbox_customization_group.dart`, `widgets/customization/radio_customization_group.dart`, `widgets/customization/portion_pill_toggle.dart`, `widgets/portion_selector.dart`, `widgets/customization/sauce_selector_group.dart`, `widgets/customization/dressing_selector_group.dart`, `widgets/customization/size_dropdown.dart`, `widgets/customization/topping_cost_label.dart`, `widgets/customization/wings_portion_selector.dart`, `widgets/customization/wings_dip_sauce_selector.dart`, `widgets/customization/wings_optional_addons_group.dart`, `widgets/customization/dinner_included_ingredients.dart`, `widgets/customization/drinks_flavor_selector.dart`, `widgets/customization/pizza_sauce_selector_tab.dart`

---

### 8. Cart

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| App bar | `primary` / `onPrimary` | |
| Line item card | `surface` | |
| Line item title | `onSurface` | |
| Line item options / notes | `onSurfaceVariant` | |
| Line price | `onSurface` | D3 |
| Trash delete | `destructive` | |
| Qty stepper | same as item card | |
| “Add more items” | `primary` text or `ctaMuted` | Prefer text `primary` |
| “Clear cart” | `destructive` | |
| Subtotal / tax labels | `onSurfaceVariant` | |
| Totals values | `onSurface` | D3 |
| Proceed to checkout | `cta` / `onPrimary` | |
| Empty cart text | `onSurfaceVariant` | |

**File:** `features/ordering/cart_screen.dart`

---

### 9. Checkout

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Section cards | `surface` | |
| Section titles | `onSurface` | |
| Field labels | `onSurfaceVariant` | |
| Field text | `onSurface` | |
| Field border | `outline`; focus `primary` | |
| Selected delivery/pickup chip | `primary` + `onPrimary` | |
| Unselected chip | `outline` + `onSurface` | |
| Address row | `surface` + `outline` | |
| Place order / pay CTA | `cta` / `onPrimary` | |
| Error banners | `error` / `onError` or tinted surface | |
| Disabled CTA | muted `onSurfaceVariant` | |

**File:** `features/ordering/checkout_screen.dart`

---

### 10. Confirmation

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Success icon | `success` | Fixed |
| Title / body | `onSurface` / `onSurfaceVariant` | |
| Order number | `onSurface` | |
| Return home CTA | `cta` / `onPrimary` | |
| Secondary actions | `ctaMuted` / `primary` text | |

**File:** `features/ordering/confirmation_screen.dart`  
Survey dialogs: §19 Feedback.

---

### 11. QR scan

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` or camera chrome | |
| Instruction text | `onSurface` / `onPrimary` if on dark overlay | |
| Frame / accent | `primary` | |
| Error | `error` | |

**File:** `features/ordering/qr_scan_screen.dart`

---

### 12. Order tracking

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Status presentation | StatusChip roles (§15) | |
| Body text | `onSurface` | |

**File:** `features/tracking/tracking_screen.dart` (thin today; same roles when expanded)

---

### 13. Profile

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | Must not stay pure black unless dark surface mode |
| App bar | `primary` / `onPrimary` | |
| Avatar ring | `outline` / `primary` | |
| Display name | `onSurface` | |
| Email / secondary | `onSurfaceVariant` | |
| Field labels | `onSurfaceVariant` | |
| Field values | `onSurface` | |
| Edit pencil | `primary` | |
| Nav tiles (`profile_nav_tile`) | title `onSurface`; chevron `onSurfaceVariant` | |
| Reward / QR card | `surfaceContainer` | |
| Reward title / points | `onSurface` | Optional single `primary` accent on points — prefer weight over second brand |
| Sign out button | `destructive` | Prefer outline `error` + `error` text |
| Loyalty points widget on profile | `surfaceContainer` + `onSurface` | |

**Files:** `features/user_accounts/profile_screen.dart`, `widgets/profile_nav_tile.dart`, `widgets/info_tile.dart`, `widgets/sign_out_button.dart`, `widgets/loyalty_points_widget.dart`

---

### 14. Delivery addresses

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Address row card bg | `surface` | |
| Row outline | `outline` | |
| Row primary text | `onSurface` | |
| Row secondary (line2) | `onSurfaceVariant` | |
| Selected indicator | `primary` | |
| Edit icon | `primary` | |
| Delete icon | `destructive` | |
| Add address button | `cta` / `onPrimary` | |
| Form dialog bg | `surface` | |
| Form fields | same as auth fields | |

**Files:** `features/user_accounts/delivery_addresses_screen.dart`, `widgets/Address/delivery_addresses_body.dart`, `widgets/Address/delivery_address_tile.dart`, `widgets/Address/address_list_view.dart`, `widgets/Address/address_form.dart`, `widgets/Address/edit_address_dialog.dart`

---

### 15. Order history

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Order row card | `surface` | |
| Order title / id | `onSurface` | |
| Meta (date, total) | `onSurfaceVariant` | |
| **Status chip fill** | `success` / `warning` / `info` / `error` / neutral | D4 — **fixed**; not brand secondary |
| **Status chip text** | contrast on chip (black/white from luminance) | Matches current `StatusChip` idea |
| Selected order emphasis | stronger `outline` or `primary` border | |
| Reorder button | `ctaMuted` preferred (secondary action) or `cta` | |
| Survey status text | `onSurfaceVariant`; complete may use `success` text | |
| Empty state | `onSurfaceVariant` | |

**Suggested status → role mapping (fixed):**

| Status (examples) | Role |
|-------------------|------|
| pending | `warning` |
| processing / in progress | `info` |
| delivered / complete | `success` |
| cancelled / canceled / failed | `error` |
| out of stock / unknown | neutral (`outline` / muted grey) |

**Files:** `features/user_accounts/order_history_screen.dart`, `widgets/status_chip.dart`, `features/user_accounts/scheduled_orders_screen.dart` (same card/status pattern)

---

### 16. Favorites

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Section titles (Menu items / Orders) | `onSurface` | |
| Section icons | `onSurfaceVariant` (default) or `primary` if selected tab | |
| Tab selected indicator | `primary` | |
| Card bg | `surface` | |
| Card border | `outline` | |
| Card title | `onSurface` | |
| Card body | `onSurfaceVariant` | |
| Heart | `favorite` → `error` | D2 |
| Order-info cards | same as history cards | |

**File:** `features/user_accounts/favorites_screen.dart`

---

### 17. Language

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Title (“Select language”) | `onSurface` | |
| Language row text | `onSurface` | |
| Selected row / radio | `primary` | |
| Unselected radio | `outline` | |

**File:** `features/language/language_screen.dart`  
(`language_provider.dart` is logic-only — no color roles.)

---

### 18. Loyalty

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Points hero card | `surfaceContainer` | |
| Points number | `onSurface` | Optional single `primary` accent — prefer typography weight |
| Reward tiles | `surface` + `outline` | |
| Claim / CTA | `cta` / `onPrimary` | |
| Disabled reward | `onSurfaceVariant` | |

**File:** `features/loyalty/loyalty_screen.dart`

---

### 19. Feedback / surveys

| Element | Role | Notes |
|---------|------|--------|
| Dialog bg | `surface` | |
| Title / body | `onSurface` / `onSurfaceVariant` | |
| Star selected | fixed `warning` / amber preferred | Not HQ; not required to be franchise secondary |
| Star unselected | `outline` | |
| Submit | `cta` / `onPrimary` | |
| Cancel | `onSurfaceVariant` | |

**Files:** `features/feedback/feedback_screen.dart`, `widgets/feedback/feedback_submission_dialog.dart`

---

### 20. Chat support

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| Incoming bubble | `surfaceContainer` + `onSurface` | |
| Outgoing bubble | `primary` + `onPrimary` | |
| Input bar | `surface` + `outline` | |
| Send icon | `primary` | |

**File:** `features/chat_support/chat_screen.dart`

---

### 21. Franchise selector (customer)

| Element | Role | Notes |
|---------|------|--------|
| Background | `background` | |
| List tile | `surface` | |
| Name | `onSurface` | |
| Meta | `onSurfaceVariant` | |
| Selected check | `primary` | |
| Continue CTA | `cta` / `onPrimary` | |

**File:** `features/user_accounts/franchise_selector_screen.dart`

---

### 22. Shared dialogs / filters

| Element | Role | Notes |
|---------|------|--------|
| Confirmation dialog bg | `surface` | |
| Title / body | `onSurface` / `onSurfaceVariant` | |
| Confirm (destructive) | `destructive` | |
| Confirm (normal) | `cta` | |
| Cancel | `onSurfaceVariant` | |
| Filter dropdown | `surface` + `outline` + `onSurface` | |

**Files:** `widgets/confirmation_dialog.dart`, `widgets/filter_dropdown.dart`

---

## 6. Explicitly out of scope

| Item | Reason |
|------|--------|
| web-app / HQ / Admin / Developer dashboards | Separate surfaces; may consume same seeds later |
| New Firestore color fields beyond seeds | Product rule D8 |
| Menu modifier / menuProfile schema | Orthogonal |
| Inventing DesignTokens per-widget color consts | Anti-goal |
| Real claim impersonation / Developer v1 residuals | Other slices |
| Typography / radius / elevation redesign | Not this slice |
| Dark mode full product | Optional surface mode only if explicitly added later |

---

## 7. Workstreams (post-map)

| ID | Name | Status |
|----|------|--------|
| **T0** | Map lock (this document) | **Done** |
| **T1** | Runtime `ColorScheme` derivation from primary/secondary + theme injection | Open |
| **T2** | Wire shell: `FranchiseAppBar`, badges, scaffold backgrounds | Open |
| **T3** | MainMenu + `CategoryCard` + category screen | Open |
| **T4** | `MenuItemCard` + item screen + qty/favorite/CTA widgets | Open |
| **T5** | Customization modal family | Open |
| **T6** | Cart + checkout + confirmation | Open |
| **T7** | Profile + addresses + favorites + order history + loyalty + language | Open |
| **T8** | Auth + social buttons (preserve provider colors) + franchise selector | Open |
| **T9** | Chat, feedback, QR, tracking, empty/shimmer/error chrome | Open |
| **T10** | HQ contrast validation / preview (optional) + STATUS close | Open |

**Suggested build order:** T1 → T2 → T3 → T4 → (parallel T8) → T5 → T6 → T7 → T9 → T10.

Prefer surgical commits per workstream; no multi-file “while you’re at it” outside listed IDs.

---

## 8. Acceptance checklist (implementation)

### Map / product

- [x] Semantic vocabulary locked
- [x] Full customer mobile map approved
- [x] D1–D8 locked
- [x] HQ seeds-only rule explicit

### Code (when T1–T10 done)

- [ ] Theme derives scheme from franchise primary/secondary with DesignTokens fallback
- [ ] No new per-widget HQ color fields in Firestore
- [ ] MainMenu + category card use roles only (spike bar)
- [ ] Menu item card CTAs use `cta` / `ctaMuted`; prices use `onSurface`
- [ ] Customization modal tiles use `surfaceContainer` / `primary` selection
- [ ] Cart checkout primary CTA = `cta`; trash/clear = `destructive`
- [ ] Profile background = `background`; sign out = `destructive`
- [ ] Status chips use fixed feedback roles only
- [ ] Favorite active = `error`
- [ ] Social provider colors unchanged (not franchise-tinted)
- [ ] No `FranchiseProvider()` zero-arg; no DesignTokens invention spam

### Regression

- [ ] Menu modifier / wings / salad behavior unchanged
- [ ] Franchise switch still recolors primary-driven chrome after theme rebuild

---

## 9. Key files (implementation targets)

**Theme / seeds**

- `mobile_app/lib/main.dart`
- `packages/shared_core/lib/src/core/config/ui_config.dart`
- `packages/shared_core/lib/src/core/config/design_tokens.dart` (fallbacks only)
- `packages/shared_core/lib/src/core/providers/franchise_provider.dart`

**High-traffic UI (first waves)**

- `mobile_app/lib/widgets/header/franchise_app_bar.dart`
- `mobile_app/lib/features/main_menu/main_menu_screen.dart`
- `mobile_app/lib/widgets/categories/category_card.dart`
- `mobile_app/lib/widgets/menu_item_card.dart`
- `mobile_app/lib/widgets/customization/customization_modal.dart`
- `mobile_app/lib/features/ordering/cart_screen.dart`
- `mobile_app/lib/features/user_accounts/profile_screen.dart`

**Do not invent**

- New BrandingConfig color fields for hearts, trash, steppers, etc.
- New menuProfile / modifierGroups fields for theming

---

## 10. Test / smoke plan (human)

1. Cold start → splash + auth use readable background/text.
2. Main menu: category borders primary; names readable on image gradient.
3. Category → item card: price not brand-red by default; CTA primary; customize muted.
4. Open customization: tiles/selection/total/cancel/add match roles.
5. Cart: checkout CTA primary; clear/trash destructive.
6. Profile: background matches app shell; sign out clearly destructive.
7. Order history: status colors encode meaning independent of brand gold/red.
8. Change franchise primary in HQ (or test override) → app bar + CTAs update after theme path rebuild; surfaces remain readable.
9. Facebook/Google buttons still provider-colored.

---

## 11. Exit criteria

Slice **Complete** when:

- T0–T10 done or explicitly deferred with STATUS note
- Acceptance checklist green under human smoke
- Customer mobile has no remaining *required* hard-coded brand-irrelevant `Colors.blue` / random greys on mapped chrome (shimmer/scrim/provider exceptions allowed)
- Merge to `main` is a **separate** human gate

---

## 12. Bottom line

**Mobile Design Tokens v1** locks a **semantic role system** for the customer app: HQ sets **identity seeds** (primary, secondary, name, logo); the app derives **surfaces, content, brand, and fixed feedback** roles. The full screen/widget map in §5 is the authority for implementation. No per-control franchise color pickers.

**Next code step after this lock:** T1 runtime `ColorScheme` derivation + T2/T3 shell and MainMenu wiring under human review.
