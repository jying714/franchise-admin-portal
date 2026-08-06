# customer_web Template Modern v1

**Status:** **COMPLETE** (2026-08-05)  
**Branch:** `feat/customer-web-template-modern-v1` (merge to main when ready)  
**Authority:** STATUS · HANDOFF · this plan  
**Surface:** `customer_web` only

---

## Goal

Config-driven **Modern** (Pizzon-inspired) landing for franchises that opt in via `config/storefront.templateId = "modern"`. Default layout unchanged.

---

## Delivered

| Item | Detail |
|------|--------|
| Resolver | `StorefrontLanding` reads `templateId` |
| Default | `StorefrontHomeScreen` (unchanged) |
| Modern home | `templates/modern/modern_storefront_home.dart` |
| Hero | Full-width banner; HQ `heroHeadline` / `heroSubheadline` / `heroImageUrl` |
| Featured | Up to 8 sellable items with images → customize dialog |
| Menu path | Category grid → items → customize → cart → checkout → confirm |
| Footer | Address, phone, hours from franchise + store_ops |
| Shell chrome | Right-aligned floating bar |
| HQ | Website tab **Storefront template** dropdown (`default` \| `modern`) |

---

## Explicit non-goals (held)

- Reservation / Book Now  
- Blog / multi-page marketing  
- mobile_app changes  
- Home composition Wave 2 studio  

---

## Acceptance

- [x] `templateId = modern` shows Modern landing  
- [x] Hero editable from HQ  
- [x] Featured + full category order path  
- [x] Default template unchanged  
- [x] No reservation UI  
- [x] HQ template picker  

---

**End of plan — complete.**
