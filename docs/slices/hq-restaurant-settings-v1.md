# Slice: HQ Restaurant Settings v1

**Status:** Spec locked — implementation not started (2026-08-02)  
**Branch recommendation:** `feat/hq-restaurant-settings-v1` off `main`  
**Authority:** this slice · `docs/plans/customer-web-parity-brand-storefront-v1.md` · Decision 8 (branding) · Decision 14 (POS settings) · `docs/architecture/firestore-per-franchise-config.md` · STATUS

---

## 1. Problem

HQ Owner currently scatters franchise configuration across:

- **Design & Branding** card/screen (colors, logo, name)
- **Customer website** card (URL / QR only)
- **Tax & hours** (`StoreOpsScreen` → `config/store_ops`)
- Onboarding Feature Setup (partial / legacy-shaped toggles)
- Stripe Connect (elsewhere)
- POS station rules (mostly not on HQ yet)

Owners need **one place** to manage branding, public website, ops, channels, payments, station, and contact—structured so customer_web parity and POS can grow without new ad-hoc cards.

---

## 2. Product locks (2026-08-02)

| Choice | Decision |
|--------|----------|
| HQ entry | **One card: Restaurant settings** |
| Shell navigation | **Top tabs** |
| Feature Setup onboarding | **Unchanged for now**; redirect/merge after this shell ships |
| POS tab | **On HQ now**; implement known fields, **stub** the rest |
| Card title | **Restaurant settings** |
| Scope | **Franchise-scoped only** (not Platform Owner global) |

### Top tabs (fixed order)

1. **Brand**  
2. **Website**  
3. **Store ops**  
4. **Channels**  
5. **Payments**  
6. **Station**  
7. **Contact**

---

## 3. HQ home card

**Title:** Restaurant settings  
**Subtitle:** Branding, website, hours, ordering & station  
**CTA:** Open settings  

**Replaces / absorbs entry points for:**

- Design & Branding card  
- Customer website / StorefrontLinkCard (QR/link move under **Website**)  
- Tax & hours standalone navigation (content moves under **Store ops**)

Onboarding progress card stays separate (workflow, not config).

---

## 4. Shell UX

- Full-screen (or large) **Restaurant settings** route under HQ Owner.  
- **App bar:** back, title “Restaurant settings”, franchise id/name.  
- **Top tab bar:** seven sections above.  
- **Save:** per-section (preferred) to avoid partial multi-doc writes; clear dirty state.  
- Wide layout: tabs still **top** (not left nav).  
- No Platform Owner / Developer controls here.

---

## 5. Firestore targets

Prefer architecture-aligned paths under `franchises/{franchiseId}/config/`:

| Doc | Sections |
|-----|----------|
| `ui_config` | Brand (existing) |
| `storefront` | Website content + domain hints (**new**) |
| `store_ops` | Store ops — extend existing tax/hours (**exists**) |
| `features` | Channels / FeatureConfig map (**intent exists**) |
| `pos` | Station (**new**) — or nest under `store_ops` if preferred at implement time |
| Franchise root / storefront | Contact, `storefrontDomain`, Stripe status fields as already used |

**Rules:** No second branding path. No inventing parallel trees without STATUS/architecture note. Migrate UI first onto existing docs where possible.

---

## 6. Settings inventory by tab

### 6.1 Brand

| Field | Source |
|-------|--------|
| Display / app name | ui_config / branding (**exists**) |
| Primary / secondary color | **exists** |
| Optional accent / semantic colors | architecture list; UI may be partial |
| Logo URL | **exists** |
| Show logo in app bar | BrandingConfig |
| Live preview | keep Design & Branding behavior |

### 6.2 Website

| Field | Source |
|-------|--------|
| Public URL (computed `/f/{id}` or custom domain) | Hosting + domain map |
| Custom domain | storefrontDomain / domain_index (**parity**) |
| Copy / Open / QR | absorb StorefrontLinkCard |
| heroImageUrl, heroHeadline, heroSubheadline | **parity** |
| storefrontPhotoUrl, storyBody | **parity** |
| galleryImageUrls[], featuredItemIds[] | **parity** |
| faq[] { question, answer } | **parity** |
| careersBlurb, careersUrl / form enabled | **parity** |
| reviews[] optional | **parity** |

### 6.3 Store ops

| Field | Source |
|-------|--------|
| taxRate | store_ops (**exists**) |
| hours per day + closed | **exists** |
| timezone | **new** (recommended) |
| deliveryEnabled, deliveryFee, deliveryMinimum | **parity** |
| deliveryAreasNote (text) | **new** if no geo engine |
| pickupEnabled | **new** (default true) |
| acceptingOnlineOrders / pause ordering | **new** |
| defaultPrepMinutes | Decision 14 / confirmation |
| Holiday closures | stub / later |

### 6.4 Channels

Owner-facing feature flags (from `FeatureConfig` / `config/features`), including:

- loyaltyEnabled, favoritesEnabled  
- scheduledOrdersEnabled, trackOrderEnabled, notificationsEnabled  
- chatSupportEnabled (mobile; web out of parity wave)  
- enableGuestMode, forceLogin  
- googleAuthEnabled, appleAuthEnabled, facebookAuthEnabled, phoneAuthEnabled  
- inventoryEnabled, nutritionEnabled, languageEnabled  

Wire real reads/writes; do not invent new FeatureConfig fields without human gate.

### 6.5 Payments

| Field | Notes |
|-------|--------|
| Connect onboarding status / link | existing Connect flow |
| paymentsEnabled | fail-closed on checkout |
| Cash-on-pickup channel toggles | if still product-active |
| Test/live indicator | clarity |

### 6.6 Station (POS)

| Field | Notes |
|-------|--------|
| Large-order threshold amount / item count | Decision 14 |
| Large-order approval required | Decision 14 |
| Max split tenders | Decision 14 |
| PIN session timeout | Decision 14 |
| Auto-print rules | Decision 14 |
| Default prep time | Decision 14 |
| Printer routing | link/stub to printer setup |
| Tip prompts (POS only) | Decision 14; **not** customer_web |

Unimplemented items: **visible stub** (“Coming soon” / disabled) with label, not silent omission.

### 6.7 Contact

| Field | Notes |
|-------|--------|
| publicAddress, publicPhone, publicEmail | franchise / storefront |
| mapEmbedUrl or lat/lng | **parity** |
| terms/privacy override | optional advanced |

---

## 7. Implementation phases

| Phase | Work |
|-------|------|
| **S0** | Shell route + top tabs + empty bodies + HQ card |
| **S1** | Brand — migrate Design & Branding UI |
| **S2** | Store ops — migrate Tax & hours; keep same `store_ops` path |
| **S3** | Website — StorefrontLinkCard + storefront doc fields (save even if customer_web reads later) |
| **S4** | Contact |
| **S5** | Channels — features doc |
| **S6** | Payments — status + safe toggles |
| **S7** | Station — implemented fields + stubs |
| **S8** | Remove obsolete HQ cards; docs STATUS/HANDOFF; optional onboarding deep-link later |

---

## 8. Explicit non-goals (v1)

- Platform-wide / multi-tenant SaaS settings  
- Replacing Admin Menu / day-2 ops  
- Reworking Feature Setup onboarding in this slice  
- Full printer hardware wizard  
- Customer_web marketing UI (separate parity plan; **consumes** Website/Store ops/Contact)  

---

## 9. Acceptance

- [ ] One **Restaurant settings** card on HQ home  
- [ ] Shell with **seven top tabs**  
- [ ] Brand edits still save to existing branding/ui_config path  
- [ ] Store ops tax/hours still save to `config/store_ops`  
- [ ] Website shows storefront URL + QR; config fields persist  
- [ ] Station tab lists Decision 14 settings (stub or live)  
- [ ] Design & Branding + standalone website cards removed or redirected  
- [ ] STATUS/HANDOFF updated  

---

## 10. First coding step

**S0:** HQ card → `RestaurantSettingsShellScreen` with `TabBar` (7 tabs) and placeholder bodies; wire navigation only.

---

**End of slice.**
