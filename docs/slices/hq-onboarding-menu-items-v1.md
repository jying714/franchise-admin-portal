# Slice: HQ Onboarding Step 3 — Menu Items v1

**Status:** ✅ COMPLETE (July 26, 2026)  
**Branch:** `feat/onboarding-4step`  
**Authority:** This file + STATUS.md + smoke (2026-07-26)  
**Owner surface:** HQ Owner onboarding only (`HqOnboardingShellScreen` → section `onboardingMenuItems`)

---

## 1. Product intent (achieved)

Step 3 builds a **mobile-valid menu** during onboarding: list + error affordance, always-visible navigable phone preview (categories → items), template path, schema sidebar for residual reference issues, mark-complete gated on zero schema **errors**.

---

## 2. Implementation outcome (July 26)

| Area | Result |
|------|--------|
| P0 Unblock | Foundation gate; nav to `onboarding_menu_foundation`; dupe-id skip |
| P1 Issue plumbing | `$0` warning; sidebar no shell-pop; Create-from-issue map-first |
| P2 List + badges | Error affordance; mark-complete gated; JSON out of this surface |
| P3 Template | Picker + residual snackbar |
| P4 Preview | Shared `MobileMenuPreviewCard` (`interactive: true`); foundation chrome 340×680 |
| List chrome | Tiles aligned with foundation category tiles |
| Delete | `deleteMenuItemAndPersist` + list refresh |
| Franchise switch (Step 3) | List + preview reload in-place (FranchiseProvider ChangeNotifier + picker branding) |
| Schema sidebar | Theme-based contrast; readable `displayMessage` |

**Shared preview:** `web-app/lib/admin/hq_owner/onboarding/widgets/foundation/mobile_menu_preview_card.dart`  
**Screen:** `.../screens/onboarding_menu_items_screen.dart`

---

## 3. Smoke (2026-07-26)

- [x] Clean foundation → list loads + preview navigable  
- [x] Add item → form valid + clean refs → save  
- [x] Price `$0` → warning, save allowed  
- [x] Template → normalize → badges only on residual  
- [x] Edit bad row → sidebar fix → badge clears → save  
- [x] Mark complete disabled until all clean; toggles `onboardingMenuItems` only  
- [x] Delete with confirm + list updates  
- [x] Franchise switch on Step 3 reloads list + preview + branding  

**Deferred (not blocking v1):**

- Liberty-only `ingredientId` String/int TypeError (irrelevant test franchise noise)  
- HQ Owner **dashboard** full design re-theme on franchise switch (progress card updates; shell chrome often does not) — separate follow-up  
- Soft-archive deletes; bulk “next broken”; JSON reintroduction; standalone manager redesign  

---

## 4. Related shell fixes (same session)

- `FranchiseProvider` extends `ChangeNotifier`; `_bumpConfig` → `notifyListeners`  
- `main.dart`: `ChangeNotifierProvider<FranchiseProvider>`; FranchiseInfo proxy **reuses** prev instance  
- `franchise_picker_dropdown.dart`: after `setFranchiseId`, `setBrandingFromFranchiseDoc` / `applyBrandingFromInfo`  

---

## 5. Agent / xAI policy going forward

- This slice is **closed** — do not re-open for redesign without a new slice card.  
- Surgical xAI tasks allowed for residual product backlog (STATUS “Still open”) under normal SCOPE_CARD rules.  
- Do not invent menu editor architecture or new Firestore fields.

---

**Last updated:** July 26, 2026  
**Next product focus:** HQ dashboard live branding on switch; remaining STATUS open items; xAI outcome batches for surgical backlog.
