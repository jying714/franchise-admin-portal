# Slice: HQ Onboarding Step 3 — Menu Items v1

**Status:** Spec locked — implementation not started (rework)  
**Branch:** `feat/onboarding-4step`  
**Authority:** This file + smoke findings (2026-07-25) + product decisions below  
**Owner surface:** HQ Owner onboarding only (`HqOnboardingShellScreen` → section `onboardingMenuItems`)  
**Human-owned:** Full rework is **out of xAI AFK batches** until this card is sliced into explicit tasks. Agents must not invent menu editor architecture.

---

## 1. Product intent

Step 3 exists so a franchise can **build a mobile-valid menu** during onboarding.

| Concern | Rule |
|---------|------|
| Primary job | Create and fix **onboarding menu items** for the selected franchise so the customer mobile app can render a working menu |
| Templates | **Keep and polish** — primary fast path for catalog bootstrap |
| Normalize (menu) | After template/seed load, auto-map menu item references to existing foundation entities where safe |
| Schema sidebar | Residual repair when normalize cannot fix a link; also **gatekeeper** for minimum mobile integrity |
| JSON import/export | **Cut from this screen for MVP** |
| Foundation upstream | Catalog quality (types, typed ingredients, categories, no orphans) is enforced **before** productive menu work |

**Success (v1):**  
Owner sees a usable item list (error affordance on broken items), an always-visible **navigable mobile-style preview** (categories → items), can add/edit items with form validation for incomplete fields and a schema sidebar only for **broken references**, cannot save an item with reference errors, and cannot mark Step 3 complete while any item still has schema **errors**. Templates apply + normalize reduce residual issues. JSON tooling is gone from this surface.

---

## 2. Ground truth (current code — do not pretend this is the target)

| Fact | Detail |
|------|--------|
| Screen | `web-app/lib/admin/hq_owner/onboarding/screens/onboarding_menu_items_screen.dart` |
| Editor | `.../widgets/menu_items/menu_item_editor_sheet.dart` + `MenuItemEditSession` |
| Sidebar | `.../widgets/menu_items/schema_issue_sidebar.dart` |
| Detection | `packages/shared_core/.../menu_item_schema_issue.dart` → `detectAllIssues` |
| Repair util | `.../widgets/menu_items/menu_item_utility.dart` (`repairMenuItem`, template helpers, construct helpers) |
| Standalone editor | `.../screens/menu_item_editor_screen.dart` (manager/ops path — **keep concept**) |
| Progress key | `onboardingMenuItems` |
| Persist | `MenuItemProvider` + `AdminFirestoreService.saveMenuItem` + `persistChanges` / `deleteMenuItem` |

**Known defects (baseline)**

- Flat list + nested Scaffold; not category-first preview UX  
- Dual issue pipelines (legacy handlers inside `build` + session); GlobalKey + dummy `repairSchemaIssue('init'|'normalize')`  
- Sidebar `Navigator.pop` unsafe when embedded  
- Dependency gate navigates to non-shell keys (`onboardingIngredientTypes`, etc.)  
- `$0` price treated as schema **error**  
- New-item path noisy / clunky; sidebar semantics unclear  
- JSON import still exposed  
- Duplicate-key risk on some franchises (Liberty) — fix early, not only after UX polish  

---

## 3. Locked product decisions

### 3.1 Form validation vs schema sidebar

Two problem classes — **do not mix**:

| Class | Examples | UI |
|-------|----------|-----|
| Incomplete form | Empty name, empty description, non-numeric price | **Field validators** / required labels; Save disabled |
| Allowed edge | Price `0` (free item) | **Warning under price field** — does **not** block save |
| Broken reference | Unknown `categoryId`, missing ingredient id, missing type id on refs | **Schema sidebar** only |

**New item:** With clean foundation and pickers bound only to real entities, sidebar should be empty or “All clean.” Required empty fields are form validation, not sidebar spam.

**Imported / template / corrupt item:** List row shows **error affordance** → Edit opens draft + sidebar for residual **reference** issues.

### 3.2 Normalize split

| Stage | Responsibility |
|-------|----------------|
| **Foundation (Step 2)** | Ingredient ↔ type coherence; **hard block orphans** (`typeId` empty); optional “Normalize ingredient types” action; gate Continue on live counts (types ≥ 1, categories ≥ 1, typed ingredients ≥ 5, orphans == 0) |
| **Menu items (Step 3)** | After template/seed: `normalizeSchemaReferences` (or equivalent) maps menu item refs to foundation ids/names where safe |
| **Sidebar** | Only what normalize cannot safely auto-fix |

Foundation normalize **reduces** Step 3 noise; it does not replace menu-level normalize.

### 3.3 Save / publish item policy

- **Block save** until: form valid **and** zero schema **errors** (reference integrity).  
- Warnings (e.g. $0 price) do not block.  
- This is a **primary mobile integrity gate** for item-level data. Review remains franchise-wide audit.

### 3.4 Mark complete

- Control remains **manual** (complete ↔ incomplete).  
- **Enabled only when** no menu item has schema **errors** (run `detectAllIssues` over provider list).  
- Disabled state shows short reason (e.g. “N items still have schema errors”).

### 3.5 Templates vs JSON

- **Templates:** in scope; polish apply + normalize + residual sidebar.  
- **JSON import/export on this screen:** **out** for MVP (remove entry points from Step 3 chrome).

### 3.6 Editor field scope (MVP)

In scope: name, description, price, category, availability/out-of-stock, image, **sizes/pricing**, **included + optional ingredients**, **customization groups**, **nutrition** (feature-gated display OK; model required), item-level preview optional.

### 3.7 List + preview UX

**List surface**

```
┌────────────────────────────┬─────────────────────────────┐
│ Menu item list             │ Always-visible phone preview│
│  error badge on bad items  │ Categories → tap → items    │
│  Add / Edit / Delete       │ Live from providers         │
└────────────────────────────┴─────────────────────────────┘
```

- Preview: **always visible** on list (no toggle for MVP).  
- Interaction: foundation-style phone chrome; **navigable** categories then items under selected category.  
- Not a permanent “categories-only admin left rail” unless preview already provides that navigation.

**Edit surface**

```
┌────────────────────────────┬─────────────────────────────┐
│ Editor form                │ Schema sidebar              │
│ field validators           │ reference issues only       │
│ Save gated on 0 errors     │ map existing / create new   │
└────────────────────────────┴─────────────────────────────┘
```

### 3.8 Create-from-issue

- **Map to existing first** (dropdown).  
- **Create New** secondary (category / ingredient / type) via same providers foundation uses; then bind new id into draft.  
- Do not force a full navigation to foundation for every missing template id; do not make Create the only path.

### 3.9 Delete

- MVP: **hard delete** with confirm (name in dialog) via `deleteMenuItem` + persist.  
- Soft-archive deferred until order history requires it.  
- “Unavailable” / out-of-stock remains separate from delete.

### 3.10 Broken-item workflow after normalize

- MVP: **per-row edit only** (no “next broken item” queue).  
- List error affordance is enough to drive fixes.

### 3.11 Standalone editor

- **Keep** `MenuItemEditorScreen` (or successor) for post-onboarding managers.  
- Share session + detection + repair + form sections with HQ embed.  
- Schema sidebar allowed there too.  
- Not registered as onboarding progress host.

### 3.12 Agent / xAI policy

- No AFK outcome batches that redesign this screen until human cuts tasks from this card.  
- Allowed later: surgical fixes explicitly listed (e.g. duplicate keys, `$0` severity, remove JSON buttons) after human approval.

---

## 4. Detection rules (target)

### Errors (block save + mark-complete eligibility)

- `categoryId` missing or not in franchise categories  
- Ingredient refs on included / optional / customization groups missing from franchise ingredients  
- Ingredient **type** refs on those structures missing from franchise types (when present on the ref)  
- Empty **name** may remain form-only or error — prefer **form validator** for empty name on draft; detection may still flag empty name on **persisted** items for list badges  

### Warnings (do not block)

- `price == 0` → field warning only (change from current `missingField` error)  

### Out of detection (form only while typing)

- Transient empty fields on a **new** draft before first save attempt  

Implementation note: adjust `MenuItemSchemaIssue.detectAllIssues` price branch accordingly; keep shared_core as single detection source.

---

## 5. Surfaces & files (target ownership)

| Surface | Path (expected) | Notes |
|---------|-----------------|-------|
| Step 3 screen | `onboarding_menu_items_screen.dart` | List + preview + open editor; no JSON; mark complete gated |
| Editor sheet | `menu_item_editor_sheet.dart` | Single session; no nested chrome wars with shell |
| Schema sidebar | `schema_issue_sidebar.dart` | Embedded: **no** `Navigator.pop` to dismiss |
| Issue model | `menu_item_schema_issue.dart` | `$0` → warning; detection stays shared |
| Utility | `menu_item_utility.dart` | normalize + repair; no dummy issue types for refresh |
| Preview | Reuse/extend foundation mobile preview patterns under `widgets/menu_items/` or foundation | Category → items navigable |
| Standalone | `menu_item_editor_screen.dart` | Thin wrapper; shared sheet |

**Shell:** Section key remains `onboardingMenuItems`. Back chrome owned by `HqOnboardingShellScreen`. Editor must not pop the shell accidentally.

---

## 6. Navigation & dependency gate

**Before list is usable**

- Types, categories, ingredients loaded for franchise  
- Foundation readiness: orphans == 0, minimum typed ingredients / categories / types (same numbers as foundation Continue)  
- If not ready: blocker UI with **Force refresh** and navigate to **`onboarding_menu_foundation`** (not fake Admin section keys)

**Open editor**

- In-place or shell-safe route; stay under HQ onboarding  
- Cancel / back returns to list without leaving shell  

---

## 7. Implementation phases (ordered)

| Phase | Work | Exit criteria |
|-------|------|---------------|
| **P0 Unblock** | Duplicate keys; foundation orphan/`typeId` quality; dependency nav keys → foundation | No red-screen on Liberty; Continue foundation honest |
| **P1 Issue plumbing** | Single `MenuItemEditSession` stream; remove dummy repairs; sidebar no `Navigator.pop`; `$0` warning | New item clean sidebar; repair updates issues without hacks |
| **P2 List + badges** | Error affordance per item; mark complete enabled only when all clean; remove JSON entry points | Bad rows visible; mark complete gated |
| **P3 Template path** | Apply template → normalize → residual issues only | Template load does not require hand-fixing every id |
| **P4 Preview** | Always-on navigable category → items phone on list | Owner can browse preview like mobile |
| **P5 Editor polish** | MVP fields stable; save gate; Create-from-issue map-first | Create/edit/delete smoke passes on seed franchise |
| **P6 Standalone align** | Shared sheet wiring for manager editor | One repair model |

Phases may compress once P0–P1 are solid; do not start P4–P5 on a red-screen list.

---

## 8. Explicit out of scope (v1)

- JSON import/export UI on Step 3  
- Bulk “open next broken item” queue  
- Soft-delete / archive collection design  
- Mobile app menu editor  
- New Firestore collections for menu  
- Auto-mark `onboardingMenuItems` complete without user action  
- xAI redesign of the whole screen without task cards derived from this doc  
- Changing progress path away from `franchises/{id}/onboarding_progress/progress`  

---

## 9. Acceptance checklist (v1)

### Foundation upstream

- [ ] Foundation Continue uses live counts + **orphan hard block**  
- [ ] Optional foundation normalize for ingredient `typeId` documented/implemented  
- [ ] Menu Step 3 dependency gate points at **`onboarding_menu_foundation`**

### List

- [ ] Items load for selected franchise  
- [ ] Items with reference schema **errors** show clear error affordance  
- [ ] Always-visible navigable preview: categories → items  
- [ ] No JSON import/export actions on this screen  
- [ ] Delete confirms and removes item (hard delete)  
- [ ] No duplicate-key crash on known seed franchises  

### Editor

- [ ] Add menu item: form validators for empty required fields; sidebar not spammed  
- [ ] Edit bad item: prefilled draft + sidebar for residual **reference** issues  
- [ ] Save disabled until form valid and zero schema **errors**  
- [ ] `$0` price allowed with visible warning  
- [ ] Sizes, ingredients, customization groups, nutrition editable per MVP  
- [ ] Create-from-issue map-first; create secondary  
- [ ] Sidebar dismiss does not pop HQ shell  

### Template

- [ ] Apply template then normalize  
- [ ] Residual issues only on sidebar / row badges  

### Progress

- [ ] Mark complete **disabled** while any item has schema errors  
- [ ] When enabled, toggles `onboardingMenuItems` only  

### Regression

- [ ] Stays inside HQ shell section `onboardingMenuItems`  
- [ ] Standalone manager editor still reachable conceptually (shared core)  

---

## 10. Smoke script (post-implement)

1. Franchise with clean foundation → Step 3 list loads; preview navigable.  
2. Add item → fill name/price/category → save succeeds; sidebar clean.  
3. Set price `0` → warning, save still allowed if otherwise clean.  
4. Apply template → normalize → list badges only on residual failures.  
5. Edit bad row → fix refs in sidebar → badge clears → save.  
6. Mark complete disabled until all clean; then toggle works.  
7. Delete item with confirm.  
8. Switch franchise → list/preview match new franchise; no Admin bounce (switcher policy elsewhere).  

---

## 11. Open items (explicit non-blockers for card lock)

- Exact visual for row error badge (icon vs background) — choose at implement time  
- Whether empty **persisted** name is list error vs form-only — prefer list error if name empty in Firestore  
- Nutrition feature-gate vs always-on fields — follow existing `PlatformFeature` pattern  

---

**Last updated:** July 25, 2026 (spec locked for human + Grok rework)  
**Next:** Human/Grok implementation from phases P0→P6; derive xAI tasks only for surgical items after P0/P1 design is applied.
