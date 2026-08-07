# customer_web Template Modern v1

**Status:** **COMPLETE** (2026-08-05 template · 2026-08-06 polish)  
**Branch:** merged to **main**  
**Authority:** STATUS · HANDOFF · this plan · `customer_web/README.md`  
**Surface:** `customer_web` only

---

## Goal

Config-driven **Modern** landing for franchises with `config/storefront.templateId = "modern"`. Default layout unchanged.

---

## Delivered

| Item | Detail |
|------|--------|
| Resolver | `StorefrontLanding` reads `templateId` |
| Default | `StorefrontHomeScreen` (unchanged) |
| Modern home | `templates/modern/modern_storefront_home.dart` |
| Hero | Full-width banner; HQ hero fields |
| Featured | Up to 4 sellable items with images; 4-across desktop |
| Story band | `storyBody` + `storefrontPhotoUrl` + hours |
| Menu path | Category → items (branded) → customize → cart sheet → in-shell checkout |
| Cart | Shell endDrawer; `CartScreen(branded: true)`; badge; `requestCheckout` + scroll |
| Footer | Address, phone, hours |
| HQ | Template dropdown; hero + story photo upload |

---

## Explicit non-goals (held)

- Reservation / Book Now  
- Blog / multi-page marketing  
- mobile_app changes  
- Full-width marketing header (small floating bar kept by choice)  
- Home composition Wave 2 studio  

---

## Acceptance

- [x] `templateId = modern` shows Modern landing  
- [x] Hero + story editable from HQ  
- [x] Featured + full category order path  
- [x] Cart side sheet + branded lines  
- [x] Default template unchanged  
- [x] No reservation UI  
- [x] HQ template picker  

---

**End of plan — complete.**
