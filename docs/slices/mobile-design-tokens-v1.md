# Slice: Mobile Design Tokens v1

**Status**: **Complete** (T1–T9 customer chrome implemented; human smoke remaining for merge gate)  
**Branch**: `feat/mobile-design-tokens-v1`  
**Authority**: this file · STATUS · `docs/MOBILE_DYNAMIC.md` · HQ Design & Branding (seeds only)  
**Scope**: **mobile_app customer-facing** screens and widgets — **not** web-app / HQ / Admin / Developer  
**Locked map**: July 28, 2026 — human approved as-is  
**Implementation closed**: July 29, 2026  
**Repo**: https://github.com/jying714/franchise-admin-portal

---

## 1. Problem

Customer mobile UI mixed franchise-aware `UiConfig` colors, static `DesignTokens` hex fallbacks, and hard-coded `Colors.*`. White-label was inconsistent; expanding HQ with dozens of color fields would be unmaintainable.

**Goal:** normalize mobile to a **small semantic role vocabulary**, driven by **HQ brand seeds only**, with everything else **derived at runtime**.

---

## 2. Product rules (do not reopen without human)

### HQ may edit (seeds only)

| Seed | Source |
|------|--------|
| Primary color | Franchise branding / `FranchiseProvider` → `UiConfig.primaryColor` |
| Secondary color | Franchise branding / `UiConfig.secondaryColor` |
| App name | Franchise branding |
| Logo URL / assets | Franchise branding |
| Optional later | Surface mode preset (Light / Soft tint / Dark) — **not** freeform per-widget colors |

### HQ must not edit

- Per-screen or per-widget colors
- Status chip colors (order lifecycle meaning)
- Social provider brand colors
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
| `DesignTokens` static color consts | **Defaults/fallbacks** only |
| `FranchiseProvider` | Single franchise-scoped branding SoT; **no** zero-arg |
| Live updates | `franchises/{id}` **snapshots** → `setBrandingFromFranchiseDoc` + theme `Selector` on configVersion\|primary\|secondary |
| Web-app HQ Design page | Out of scope this slice (seeds only; vocabulary expansion deferred) |
| Menu / modifier schema | No changes |

### Approved decisions (D1–D8)

| ID | Topic | Lock |
|----|--------|------|
| **D1** | App bar | `primary` + `onPrimary` |
| **D2** | Favorite heart | Active → `error`; inactive → `onSurfaceVariant` |
| **D3** | Price text | `onSurface` (not primary) |
| **D4** | Status chips | Fixed success / warning / info / error / neutral |
| **D5** | Category card border | `primary` |
| **D6** | Category title on photo | Text-on-media ≈ `onPrimary` |
| **D7** | Social provider colors | Fixed; never franchise secondary |
| **D8** | HQ editable set | primary, secondary, appName, logo only |

---

## 3. Semantic vocabulary (canonical)

### Surfaces
`background` · `surface` · `surfaceContainer` · `outline`

### Content
`onBackground` · `onSurface` · `onSurfaceVariant`

### Brand (HQ seeds + contrast)
`primary` · `onPrimary` · `secondary` · `onSecondary`

### Feedback (fixed — not HQ)
`error` / `onError` · `success` · `warning` · `info`

### Component aliases (derived — not stored)
| Alias | Resolves to |
|-------|-------------|
| `cta` | `primary` + `onPrimary` |
| `ctaMuted` | surface/outline + `primary` text |
| `destructive` | `error` |
| `favorite` | active `error`; inactive `onSurfaceVariant` |

---

## 4. Runtime derivation (implemented)

1. Seeds from `FranchiseProvider` / `UiConfig.primaryColor` / `secondaryColor` (DesignTokens fallbacks).
2. `buildFranchiseColorScheme` in `mobile_app/lib/main.dart` builds light `ColorScheme` (surfaces from UiConfig defaults; brand from seeds; error fixed).
3. `MaterialApp` theme: `useMaterial3`, `colorScheme`, app bar `surfaceTintColor: transparent`.
4. Theme rebuild: `Selector` on `currentConfigVersion|currentPrimaryColorHex|currentSecondaryColorHex`.
5. Live HQ changes: `HomeWrapper._listenBranding` → `franchises/{id}.snapshots()` → `setBrandingFromFranchiseDoc`.
6. Widgets use `Theme.of(context).colorScheme.*` for chrome.

---

## 5. Mobile customer token map (complete)

*(Full inventory §0–§22 retained from map lock — authority for residual polish.)*

High-traffic paths implemented July 29: global theme, MainMenu/status bar, FranchiseAppBar, CategoryCard, MenuItemCard + CTA/favorite widgets, customization header/bottom bar/portions/optional add-ons/current ingredients, cart, profile/info/sign-out, order history + StatusChip, favorites, language, delivery addresses + tiles/body, QR scan screen.

**Deferred residual (optional follow-up, not blocking Complete):** checkout, confirmation, item detail, category screen promo chrome, auth/social (D7), loyalty, chat, feedback stars, franchise selector, empty/shimmer if still UiConfig-heavy.

---

## 6. Explicitly out of scope

| Item | Reason |
|------|--------|
| web-app / HQ Design vocabulary expansion | Separate slice; seeds-only for mobile v1 |
| New Firestore color fields beyond seeds | D8 |
| Menu modifier schema | Orthogonal |
| Inventing DesignTokens per-widget colors | Anti-goal |
| Typography / radius redesign | Not this slice |

---

## 7. Workstreams

| ID | Name | Status |
|----|------|--------|
| **T0** | Map lock | **Done** |
| **T1** | Runtime ColorScheme + theme injection | **Done** |
| **T2** | Shell: FranchiseAppBar, MainMenu surface/status bar | **Done** |
| **T3** | CategoryCard (+ MainMenu host) | **Done** |
| **T4** | MenuItemCard + qty/favorite/CTA widgets | **Done** |
| **T5** | Customization modal family (header, footer, pills, portions, ingredients, add-ons) | **Done** |
| **T6** | Cart CTAs / surfaces / destructive | **Done** |
| **T7** | Profile + addresses + favorites + order history + language | **Done** |
| **T8** | Auth + social + franchise selector | **Deferred** (explicit STATUS note — not required for v1 close) |
| **T9** | QR scan + residual snackbars / status bar consistency | **Done** (QR + snackbar/status residuals) |
| **T10** | STATUS + slice close | **Done** (this commit) |

---

## 8. Acceptance checklist

### Map / product

- [x] Semantic vocabulary locked
- [x] Full customer mobile map approved
- [x] D1–D8 locked
- [x] HQ seeds-only rule explicit

### Code (T1–T9)

- [x] Theme derives scheme from franchise primary/secondary with DesignTokens fallback
- [x] Live franchise doc stream updates branding without full restart
- [x] No new per-widget HQ color fields in Firestore
- [x] MainMenu + category card use scheme roles
- [x] Menu item card CTAs use cta / ctaMuted; prices onSurface; favorite error
- [x] Customization header/footer/portions/ingredients/add-ons use scheme roles
- [x] Cart primary CTA + destructive clear/trash
- [x] Profile surface + sign out destructive
- [x] Status chips fixed feedback roles only (D4)
- [x] QR scan surface / primary / error / fixed success
- [x] No FranchiseProvider() zero-arg; no DesignTokens invention spam
- [ ] Human device smoke (see §10) — merge gate
- [ ] Auth/social residual (T8 deferred)
- [ ] Checkout / confirmation / item detail residual — optional follow-up

### Regression

- [ ] Menu modifier / wings / salad behavior unchanged under human smoke
- [x] Franchise primary change recolors app bar + CTAs via stream + Selector

---

## 9. Key files (implemented)

- `mobile_app/lib/main.dart` — ColorScheme + branding stream + Selector
- `mobile_app/lib/widgets/header/franchise_app_bar.dart`
- `mobile_app/lib/features/main_menu/main_menu_screen.dart`
- `mobile_app/lib/widgets/categories/category_card.dart`
- `mobile_app/lib/widgets/menu_item_card.dart`
- `mobile_app/lib/widgets/add_to_cart_button.dart`
- `mobile_app/lib/widgets/customize_and_add_to_cart_button.dart`
- `mobile_app/lib/widgets/favorite_button.dart`
- `mobile_app/lib/widgets/customization/{header,bottom_bar,portion_pill_toggle,optional_addons_group,current_ingredients}.dart`
- `mobile_app/lib/widgets/portion_selector.dart`
- `mobile_app/lib/features/ordering/cart_screen.dart`
- `mobile_app/lib/features/ordering/qr_scan_screen.dart`
- `mobile_app/lib/features/user_accounts/{profile_screen,order_history_screen,favorites_screen,delivery_addresses_screen}.dart`
- `mobile_app/lib/features/language/language_screen.dart`
- `mobile_app/lib/widgets/{info_tile,sign_out_button,status_chip}.dart`
- `mobile_app/lib/widgets/Address/{delivery_address_tile,delivery_addresses_body}.dart`

---

## 10. Test / smoke plan (human)

1. Cold start → MainMenu surface + app bar primary; status bar tracks primary contrast.
2. HQ change primary gold ↔ red → app bar + CTAs update **without** full restart (stream).
3. Category borders primary; names readable on image.
4. Item card: price onSurface; Add primary; Customize muted; heart error when favorited.
5. Customize: portion/pill primary; footer total onSurface; Add primary.
6. Cart: checkout primary; clear/trash error.
7. Profile: surface shell; sign out error.
8. Order history: status chips independent of brand gold/red.
9. Favorites / language / addresses / QR: no black residual scaffolds.
10. Menu modifier / wings / salad paths still functional.

---

## 11. Exit criteria

- [x] T0–T7, T9, T10 done; T8 deferred with STATUS note
- [ ] Acceptance smoke green under human
- [x] Customer high-traffic chrome on scheme roles; seeds-only HQ
- Merge to `main` is a **separate** human gate

---

## 12. Bottom line

**Mobile Design Tokens v1** delivers a semantic role system for the customer app: HQ sets **identity seeds**; the app derives **surfaces, content, brand, and fixed feedback**. High-traffic paths (shell, menu, customize, cart, profile, history, favorites, language, addresses, QR) are wired. Auth/checkout leftovers are optional follow-ups. **Next:** human smoke → merge gate when ready.
