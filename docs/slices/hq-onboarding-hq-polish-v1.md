# Slice: HQ Onboarding & HQ Dashboard Polish v1

**Status:** Spec locked — implementation open (§3 decisions locked July 26, 2026)  
**Branch:** `feat/onboarding-4step`  
**Created:** July 26, 2026  
**Authority:** This file + STATUS.md  
**Depends on (done):** Menu Items v1; FranchiseProvider ChangeNotifier + single root instance; live HQ branding on switch; picker stale-response guard  
**Owner surfaces:** HQ Owner onboarding shell + Owner HQ dashboard  
**Agent policy:** Surgical outcome tasks from this card. No Menu Items v1 redesign. No second FranchiseProvider. No new DesignTokens/BrandingConfig fields. Progress key for branding is **fixed below** — do not invent alternate key names.

---

## 1. Product intent

Make onboarding and the HQ home **honest for MVP**:

- No dead navigation, no false Review errors, no fake “complete” controls.
- Foundation and Menu Items share the same preview/FAB layout language.
- Features and dashboard cards that are not production-ready stay **visible but labeled In development**.
- **Design & Branding is a first-class onboarding step** between Feature Setup and Core Menu Foundation.
- Franchise switch continues to scope branding and domain data; polish must not regress that.

**Success (v1):** Owner walks Feature Setup → **Design & Branding** → Foundation → Menu Items → Review without false blockers; foundation tabs have no JSON/back-arrow/fake mark-complete; Step 3 FAB matches Step 2; HQ cards work franchise-scoped or show In development; billing/invoices are a single honest card story.

---

## 2. Ground truth (do not regress)

| Fact | Detail |
|------|--------|
| Onboarding host | `HqOnboardingShellScreen` only |
| Progress path | `franchises/{id}/onboarding_progress/progress` |
| Product keys (final set) | `onboarding_feature_setup` → **`onboarding_design_branding`** → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview` |
| Foundation product complete | Save & Continue / explicit foundation complete — **not** tab mark complete |
| Menu Items | Slice closed; `MobileMenuPreviewCard`; `deleteMenuItem` / `deleteMenuItemAndPersist` |
| FranchiseProvider | **Single** web instance at app root; branding setters call `_bumpConfig()` |
| Design & Branding UI | Reuse `design_branding_screen.dart` (embed or shell section); Save already writes franchise + `config/ui_config` |

---

## 3. Locked product decisions (July 26, 2026)

### 3.1 Design & Branding in onboarding — **A (LOCKED)**

- **New onboarding step** between Feature Setup and Core Menu Foundation.
- **Section key:** `onboarding_design_branding`
- **Progress product key:** `onboarding_design_branding` (same string)
- **UI:** Reuse existing Design & Branding screen/flow inside HQ shell (no duplicate branding model).
- **Complete when:** Owner saves branding successfully (or explicit Mark complete only if Save already persisted — prefer Save success → enable continue / mark step).
- **Navigation updates required:**
  - Shell section order / sidebar
  - Feature Setup success → `switchToSection('onboarding_design_branding')` (not straight to foundation)
  - Design & Branding continue → `onboarding_menu_foundation`
  - HQ **Continue onboarding** + **Quick Link** first-incomplete cascade must insert the new key after feature setup and before foundation
  - Review / summary `N/4` becomes **N/5** product steps if panel counts product keys

### 3.2 Foundation tab “Mark complete” — **REMOVE (LOCKED)**

- Remove Mark complete controls from Ingredient Types, Ingredients, and Categories onboarding chrome.
- Do **not** wire them to `onboarding_menu_foundation`.
- Sub-key detail % may remain if already driven by data counts; no fake tab complete buttons.

### 3.3 Billing summary vs Invoices — **MERGE TO ONE IN-DEV CARD (LOCKED)**

Human accepted recommendation:

- **Do not** show two competing cards (Billing summary + Invoices) while both lack solid MVP data/routes.
- **Replace with one** card: **“Billing & invoices”** with **In development** state (no dead “View all” that 404s).
- When real invoice list + route ship later, expand this card or split under a new slice — not in polish v1 unless routes already work end-to-end (then human may re-open).

### 3.4 Feature Setup “In development”

- Human owns GA vs dev list (Firestore status preferred; else const allowlist).
- Dev: visible, toggle disabled, **In development** note.

---

## 4. Workstreams (ordered)

### W1 — Foundation chrome honesty (Step 2)

**Files:** `onboarding_ingredient_type_screen.dart`, `onboarding_ingredients_screen.dart`, `onboarding_categories_screen.dart`, foundation shell if needed.

1. Remove competing **back arrows** (shell owns back).
2. Remove **JSON import/export** entry points from onboarding UI.
3. **Remove** tab Mark complete (§3.2).
4. Leave Continue / orphan gates / product key writers intact.

**Exit:** No JSON CTAs; no redundant back; no tab Mark complete.

---

### W2 — Step 3 FAB + preview parity

**Files:** `onboarding_menu_items_screen.dart`, foundation screen (reference), `mobile_menu_preview_card.dart`.

1. FAB on **list pane** bottom-end (Step 2 parity).
2. Same parent constraints for shared preview card; do not fork chrome.

---

### W3 — Review false positive (“menu management”)

1. Tracer: Review rule → feature key → Feature Setup persist path.
2. Align keys or drop obsolete rule.
3. No new schema/flags without approval.

**Exit:** Features enabled ⇒ no false menu-management blocker.

---

### W4 — Feature Setup in-development UX

Apply §3.4 after GA list exists.

---

### W5 — HQ Owner dashboard MVP honesty

1. Franchise-scoped live cards only.
2. Dead payouts/quick-link targets → wire or **In development** / remove.
3. **§3.3:** single **Billing & invoices** in-dev card (remove duplicate Billing summary + Invoices pair).
4. Live Branding + Onboarding Progress sized to grid peers.
5. Quick Links: Onboarding + Design & Branding (and any other working routes only).

---

### W6 — Design & Branding onboarding step (**A — in scope**)

1. Register section `onboarding_design_branding` in HQ shell order **after** feature setup, **before** foundation.
2. Persist progress key `onboarding_design_branding` via `shared.OnboardingProgressProvider` only.
3. Embed/reuse Design & Branding UI; Save path unchanged (franchise doc + ui_config).
4. Update handoffs: Feature Setup → branding step → foundation.
5. Update first-incomplete cascades (Continue + Quick Link) and summary panel key list (5 steps).
6. Sidebar labels: e.g. “Design & Branding”.

**Exit:** New step appears in order; complete/incomplete toggles only that key; Continue path does not skip it when incomplete.

---

## 5. Explicit out of scope

- Menu Items v1 redesign; soft-delete; JSON reintroduction
- Second FranchiseProvider; new DesignTokens/BrandingConfig fields
- Full Stripe production; color picker
- Liberty ingredientId noise
- Splitting billing/invoices back into two live cards without working data

---

## 6. Implementation order

1. **W3** Review false positive  
2. **W1** Foundation chrome  
3. **W2** FAB + preview  
4. **W6** Branding step (shell + progress + cascades)  
5. **W4** Feature in-dev (after GA list)  
6. **W5** HQ dashboard (including billing merge)  

---

## 7. Acceptance checklist

### Foundation
- [ ] No competing back arrow on types/categories/ingredients
- [ ] No JSON import/export on those onboarding UIs
- [ ] Tab Mark complete **removed**

### Menu Items / preview
- [ ] FAB list-pane bottom-end
- [ ] Preview size parity with foundation

### Review / features
- [ ] No false menu-management issue
- [ ] Non-GA features In development + non-toggleable

### Branding step
- [ ] Shell order: feature setup → **design branding** → foundation → menu items → review
- [ ] Progress key `onboarding_design_branding` only for this step
- [ ] First-incomplete cascades include the new key
- [ ] Summary / Continue treat 5 product steps correctly

### HQ dashboard
- [ ] Single Billing & invoices in-dev (or successor) — not two dead cards
- [ ] Payouts/Quick Links honest
- [ ] Branding + onboarding cards grid-sized
- [ ] Franchise switch still live-brands

---

## 8. Smoke

1. Feature Setup save → lands on **Design & Branding** step.  
2. Save branding → can continue to foundation; progress key set.  
3. Skip branding incomplete → Continue/Quick Link still offers branding first when prior steps done.  
4. Foundation: no JSON/back/mark-complete noise.  
5. Menu Items FAB + preview vs foundation.  
6. Review: no false feature blocker.  
7. HQ: one billing card; no broken invoice/payout CTAs; switch franchise branding OK.  

---

**Last updated:** July 26, 2026 (decisions locked: A branding step; remove tab mark-complete; merge billing/invoices in-dev)  
**Next:** W3 tracer; W1 xAI outcomes; W6 shell wiring plan.
