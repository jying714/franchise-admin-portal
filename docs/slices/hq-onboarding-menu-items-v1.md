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
| P0–P5 | Gate, schema sidebar, list badges, template residual, interactive preview, FAB/editor path as shipped |
| Preview | Shared `MobileMenuPreviewCard` (`interactive: true`); 340×680 chrome |
| Delete | `deleteMenuItemAndPersist` + list refresh |
| Franchise switch | List + preview + branding in-place |

**Follow-on polish (FAB position, preview constraint parity)** lives in **`docs/slices/hq-onboarding-hq-polish-v1.md`** — not a reopen of this slice.

---

## 3. Smoke (2026-07-26) — passed

Clean foundation, add/edit/delete, $0 warning, template residual, mark complete gate, franchise switch on Step 3.

**Deferred from v1:** Liberty ingredientId type noise; soft-archive; bulk next-broken; JSON on this surface.

---

## 4. Agent policy

Closed. Do not redesign without a new slice. Surgical tasks only under polish slice / STATUS.

**Last updated:** July 26, 2026 (afternoon — polish slice owns residual FAB/preview layout)
