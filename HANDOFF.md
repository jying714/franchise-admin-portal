# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 28, 2026 (~19:25 CDT — W2 + order-experience complete; menu epic on main)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `main`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Latest session (July 28 evening)

### Pizza path (done + polish)

- HQ included + optional add-ons persist; mobile optionalAddOns pools; cheeses/sauces section parity; CBR PASS.
- Order Details: Crust/Cook/Cut via stored groups **or** pizza template fallback when omitted.
- Flat “Add-ons” checkbox groups hidden on pizza/calzone.
- Included ingredients **do not** inflate base price (only doubles / true extras charge).

### Wings + calzone (W0–W7 + **W2 Done**)

Authority: **`docs/slices/hq-wings-calzone-v1.md`**.

| Topic | Lock |
|--------|------|
| Wings portions | Max **2** always |
| Plain | No toss on portion; **still gets free cups** |
| Sauces | Catalog type **`sauces`**; item **binds** via modifier groups; save projects to `dippingSauceOptions` / `sideDipSauceOptions` |
| Free cups / extra $ | Menu item per size → `freeDipCupCount` / `sideDipUpcharge` |
| UI | Build your wings + **Dipping sauces** only; no included/optional; no Order Details |
| Calzone | **`menuProfile: calzone`**; pizza twin; **no left/right**; cheeses/sauces like pizza |
| **W2 pool** | `franchises/{id}/config/menu_profile_wings`; HQ save/apply; mobile item → groups → pool → empty |

Human acceptance: wings, calzone, pizza — **PASS**.

### Salad / dinner mobile (done)

- No Order Details for salad/dinner.
- Optional ingredients only when HQ set `optionalAddOns` (`menuProfile: standard` — no new profiles).
- Salad: optional pool uses Click to Add; selected items move to Current only; included not listed on both.
- Pricing: included never auto-added to starting total.

### M5 dual-tree cutover (**Done**)

- Canonical-only `toFirestore` (always write menuProfile/modifierGroups; skip empty dual lists).
- `effectiveMenuProfile` / `effectiveModifierGroups` stored-only; `_legacyToModifierGroups` deleted.
- Offline cache DB v3 + profile/groups columns.
- Admin day-2 form preserves canonical; dual Customize dialog + customization_types deleted.
- Dynamic form Save preserves menuProfile/modifierGroups.
- Full reseed; legacy dual-tree data deleted; smoke green.

### Deferred order-experience feedback (**Done**)

- Confirmation: ordering survey only; schedules `pending_order_experience_feedback` (+45m).
- MainMenu: when due, shows `FeedbackMode.orderExperience` once, then clears key.

### Still open

1. Developer dashboard  
2. Residual polish under explicit human task only  
3. Confirm Hosting after this `main` docs push  

### Do not regress

- Pizza optionalAddOns contract (Current / Additional / Cheeses / Sauces / Order Details)  
- HQ included + optional persist (non-wings profiles)  
- Included ingredients not charged as extras until double or truly extra  
- No `FranchiseProvider()` zero-arg / DesignTokens invention  
- No Cook/Cut/Crust as ingredient types  
- No new `wing_sauces` ingredient type  
- Wings: single dipping list; no dual tabs; no included/optional UI  
- No dual production write paths after M5  

---

## 2. Prior closures

| Area | Status |
|------|--------|
| HQ onboarding sole host | Done |
| Platform Owner MVP | Done |
| Admin ops v1 | Done on `main` |
| Menu rebuild M1–M5 | **Done** on `main` |
| Foundation seed Doughboys | Done |
| Wings + calzone W0–W7 + W2 | **Done** on `main` |
| Salad/dinner mobile optional UX + pricing honesty | Done on `main` |
| Deferred order-experience prompt | Done on `main` |

---

## 3. What’s next

1. Developer dashboard  
2. Residual product polish only under explicit human task  
3. Confirm Hosting deploy for this `main` tip  

---

## 4. Key references

- `docs/slices/hq-wings-calzone-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  
- `docs/MOBILE_DYNAMIC.md`  
- `packages/shared_core/.../menu_item.dart`  
- `packages/shared_core/.../menu_profile_templates.dart`  
- `mobile_app/.../customization_modal.dart`  
- `mobile_app/.../optional_addons_group.dart`  
- `mobile_app/.../wings_portion_selector.dart` / `wings_dip_sauce_selector.dart`  
- `web-app/.../menu_item_editor_sheet.dart`  
- `web-app/.../wings_franchise_sauce_pool.dart`  

---

**Bottom line:** Menu modifier rebuild **M1–M5 + W2 complete** on **`main`**. Wings/calzone/pizza/salad paths green. Canonical `menuProfile` + `modifierGroups` only. Next epic: Developer dashboard.
