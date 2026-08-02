# Slice: HQ Restaurant Settings v1

**Status:** Implementation **largely complete** on `feat/hq-restaurant-settings-v1` (2026-08-02)  
**Authority:** this slice · `docs/plans/customer-web-parity-brand-storefront-v1.md` · Decision 8 · Decision 14 · `docs/architecture/firestore-per-franchise-config.md` · STATUS

---

## 1. Problem (solved)

HQ Owner config was scattered across Design & Branding, Customer website card, Tax & hours, and incomplete feature/POS surfaces. Owners need **one franchise-scoped shell** for branding, website, ops, channels, payments, station, and contact.

---

## 2. Product locks

| Choice | Decision |
|--------|----------|
| HQ entry | **One card: Restaurant settings** |
| Shell navigation | **Top tabs** |
| Feature Setup onboarding | **Unchanged** until a later pass |
| POS tab | **On HQ** — live fields + stubs |
| Scope | **Franchise-scoped only** |

### Top tabs

1. Brand · 2. Website · 3. Store ops · 4. Channels · 5. Payments · 6. Station · 7. Contact

---

## 3. Implementation status

| Phase | Work | Status |
|-------|------|--------|
| **S0** | Shell + top tabs + HQ **Restaurant settings** card | **Done** |
| **S1** | Brand = `DesignBrandingScreen(embeddedInSettingsShell)` | **Done** |
| **S2** | Store ops = `StoreOpsScreen(embeddedInSettingsShell)` | **Done** |
| **S3** | Website panel: URL/QR + content fields | **Done** |
| **S3b** | Website Save → `config/storefront` | **Done** |
| **S4** | Contact → franchise `public*` + `mapEmbedUrl` | **Done** |
| **S5** | Channels → `config/features` | **Done** |
| **S6** | Payments → Connect callables | **Done** |
| **S7** | Station → `config/pos` + stubs | **Done** |
| **S8** | HQ cleanup: drop website card; Tax & hours → tab 2 | **Done** |
| **S9** | Store ops delivery + timezone dropdown (labeled) | **Done** |
| **S10** | Merge to `main` + delete feature branch | **Open** |
| — | Feature Setup onboarding → shell deep-link | **Deferred** |
| — | FAQ/gallery/careers/reviews editors on Website | **Optional residual** |
| — | POS reads `config/pos` | **POS residual** |
| — | customer_web reads `config/storefront` | **Parity D0** |

---

## 4. Firestore paths

| Doc | Content |
|-----|---------|
| `config/ui_config` + franchise root | Brand (existing Design & Branding save) |
| `config/storefront` | heroImageUrl, heroHeadline, heroSubheadline, storefrontPhotoUrl, storyBody |
| `config/store_ops` | taxRate, hours, delivery*, pickupEnabled, acceptingOnlineOrders, timezone |
| `config/features` | FeatureConfig keys (owner subset) |
| `config/pos` | large-order, splits, PIN timeout, prep, auto-print flags |
| franchise root | publicAddress, publicPhone, publicEmail, mapEmbedUrl |

---

## 5. Key files

- `web-app/lib/admin/hq_owner/screens/restaurant_settings_shell_screen.dart`
- `website_settings_panel.dart` · `contact_settings_panel.dart` · `channels_settings_panel.dart`
- `payments_settings_panel.dart` · `station_settings_panel.dart`
- `design_branding_screen.dart` (`embeddedInSettingsShell`)
- `store_ops_screen.dart` (`embeddedInSettingsShell` + delivery + timezone)
- `owner_hq_dashboard_screen.dart` (`RestaurantSettingsCard`, S8 cleanup)

---

## 6. Acceptance

- [x] One **Restaurant settings** card on HQ home  
- [x] Shell with **seven top tabs**  
- [x] Brand saves to existing branding/ui_config path  
- [x] Store ops tax/hours (+ delivery + timezone) → `config/store_ops`  
- [x] Website URL/QR + content → `config/storefront`  
- [x] Station lists Decision 14 settings (stub or live)  
- [x] Design & Branding card replaced; Customer website card removed from grid  
- [ ] Merge feature branch → `main`  
- [ ] STATUS/HANDOFF on main after merge  

---

## 7. Explicit non-goals (still)

- Platform-wide settings  
- Admin Menu day-2 ops  
- Rework Feature Setup onboarding in this slice  
- Full printer wizard  
- customer_web marketing UI (consumes storefront doc in parity plan)  

---

**End of slice.**
