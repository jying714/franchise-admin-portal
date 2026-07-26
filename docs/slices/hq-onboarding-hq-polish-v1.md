# Slice: HQ Onboarding & HQ Dashboard Polish v1

**Status:** Implementation in progress — **W1, W2, W3, W6 done**; **W4 + W5 open** (decisions locked July 26, 2026)  
**Branch:** `feat/onboarding-4step`  
**Created:** July 26, 2026  
**Last code session:** July 26, 2026 afternoon  
**Authority:** This file + STATUS.md  
**Depends on (done):** Menu Items v1; FranchiseProvider ChangeNotifier + single root instance; live HQ branding on switch; picker stale-response guard  
**Owner surfaces:** HQ Owner onboarding shell + Owner HQ dashboard  
**Agent policy:** Surgical outcome tasks from this card. No Menu Items v1 redesign. No second FranchiseProvider. No new DesignTokens/BrandingConfig fields. Progress key for branding is **`onboarding_design_branding`** — do not invent alternate key names. Do not reintroduce `menu_management` Review gate.

---

## 1. Product intent

Make onboarding and the HQ home **honest for MVP**:

- No dead navigation, no false Review errors, no fake “complete” controls.
- Foundation and Menu Items share the same preview/FAB layout language.
- Features and dashboard cards that are not production-ready stay **visible but labeled In development**.
- **Design & Branding is a first-class onboarding step** between Feature Setup and Core Menu Foundation.
- Franchise switch continues to scope branding and domain data; polish must not regress that.
- **Platform billing** is thin: HQ sees whether the franchise owes the platform (SaaS/subscription), not a full AR workbench.

**Success (v1):** Owner walks Feature Setup → **Design & Branding** → Foundation → Menu Items → Review without false blockers; foundation tabs have no JSON/back-arrow/fake mark-complete; menu FAB on list pane; HQ cards work franchise-scoped or show In development; **one** platform-billing card (no dual Billing Summary + Invoices).

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
| Design & Branding UI | `design_branding_screen.dart`; `embeddedInOnboarding: true` in shell; Save writes franchise + `config/ui_config` + marks progress key |
| Platform invoices | **Platform → franchise** bills (SaaS/subscription), **not** diner tickets. Model: `PlatformInvoice` |
| Progress provider listen | Prefer **`OnboardingProgressProviderImpl`** (ChangeNotifier) for UI that must rebuild on mark complete; abstract Proxy alone may not |
| Progress load model | Load + write — **not** a Firestore snapshot stream. Console edits need reload/restart |

---

## 3. Locked product decisions (July 26, 2026)

### 3.1 Design & Branding in onboarding — **A (LOCKED + IMPLEMENTED)**

- Section + progress key: **`onboarding_design_branding`**
- Shell order: Feature → Design & Branding → Foundation → Menu Items → Review (sidebar titles Step 1–5)
- Feature Setup save → branding; Save branding → mark key; Continue → foundation
- HQ Continue + Quick Link first-incomplete include branding
- Review summary + progress chip treat **5** product steps; branding row status = progress key via Impl

### 3.2 Foundation tab “Mark complete” — **REMOVE (LOCKED + IMPLEMENTED)**

- Removed from Types / Ingredients / Categories chrome.
- Nested AppBars removed; in-body titles + template only.
- Foundation AppBar on scaffold background; TabBar selection = bold/size not primary red.

### 3.3 Platform billing on HQ — **ONE THIN CARD (LOCKED — NOT YET IMPLEMENTED IN UI)**

| Rule | Detail |
|------|--------|
| **One card only** | Remove dual **BillingSummaryCard** + **InvoicesCard** |
| **Card name** | **Platform billing** (or “Subscription & fees”) |
| **Default v1 state** | **In development** — no dead `/hq/invoices` |
| **Later** | Stripe portal / hosted invoice URL OK; custom list not required here |

### 3.4 Feature Setup “In development” — **LOCKED — NOT YET IMPLEMENTED**

- Human owns GA vs dev list.
- Dev: visible, toggle disabled, **In development** note.
- Higher-tier gates only; menu customization is for every subscriber.

### 3.5 Review feature gate — **IMPLEMENTED**

- Dropped hard `menu_management` check in `FranchiseFeatureProviderImpl.validate()` (key never existed in feature_metadata).

---

## 4. Workstreams

### W1 — Foundation chrome honesty — **DONE**

- No competing back arrows; no JSON import/export entry points; tab Mark complete removed.
- Nested Scaffold AppBars → in-body title rows; InlineAddIngredientTypeRow removed.
- Foundation TabBar styling fixed.

### W2 — Step 3 FAB + preview parity — **DONE**

- FAB Positioned on list-pane Stack (not full Scaffold).
- Preview without Center; dependencies status uses `DesignTokens.textColor`.

### W3 — Review false positive — **DONE**

- `menu_management` gate removed.

### W4 — Feature Setup in-development UX — **OPEN**

Apply §3.4 after human GA list.

### W5 — HQ Owner dashboard MVP honesty — **OPEN**

1. One **Platform billing** in-dev card; remove Billing Summary + Invoices pair.  
2. Payouts: wire or In development.  
3. Quick Links: only working routes (Onboarding cascade already fixed).  
4. Live Branding + Onboarding Progress sized to grid peers.  
5. Non-MVP mocks → In development shells.

### W6 — Design & Branding onboarding step — **DONE**

- Shell section, handoffs, cascades, Review section order, progress-key status, embedded chrome (no filled AppBar).

---

## 5. Explicit out of scope

- Menu Items v1 redesign; soft-delete; JSON reintroduction  
- Second FranchiseProvider; new DesignTokens/BrandingConfig fields  
- Full Stripe production / custom invoice workbench  
- Color picker; Liberty ingredientId type noise  
- Restoring dual Billing Summary + Invoices cards  
- Reintroducing `menu_management` Review gate  

---

## 6. Implementation order (remaining)

1. **W4** Feature in-dev (needs human GA list)  
2. **W5** HQ dashboard (platform billing one-card + dead links + sizing)  
3. Tick acceptance + STATUS; mark slice **complete**

---

## 7. Acceptance checklist

### Foundation
- [x] No competing back arrow on types/categories/ingredients
- [x] No JSON import/export on those onboarding UIs
- [x] Tab Mark complete **removed**

### Menu Items / preview
- [x] FAB list-pane bottom-end
- [x] Preview aligned with foundation (no Center wrapper)

### Review / features
- [x] No false menu-management issue
- [ ] Non-GA features In development + non-toggleable (**W4**)

### Branding step
- [x] Order: feature setup → design branding → foundation → menu items → review
- [x] Progress key `onboarding_design_branding`
- [x] Cascades + summary treat 5 product steps
- [x] Review branding row tracks progress key (Impl listen)

### HQ dashboard
- [ ] **One** Platform billing card (in-dev OK) (**W5**)
- [ ] No broken invoice/payout named routes from CTAs (**W5**)
- [x] Quick Link Onboarding cascade includes branding
- [ ] Branding + onboarding cards grid-sized (**W5**)
- [x] Franchise switch still live-brands (pre-slice; do not regress)

---

## 8. Smoke (remaining focus)

Already passed in session: Feature→branding handoff; branding Save/progress; Continue/Quick Link branding; foundation chrome; menu FAB; Review no menu_management; Review 5/5 + incomplete branding status.

Still required before close:

1. W4: non-GA features In development.  
2. W5: single platform billing card; no 404 invoice/payout CTAs; card sizing.  
3. Optional: reduce franchise-switch progress lag (reload path or future stream — not required to close if documented).

---

## 9. Key files touched (this slice)

- `hq_onboarding_shell_screen.dart` — section order + completableKeys  
- `onboarding_feature_setup_screen.dart` — handoff to branding  
- `design_branding_screen.dart` — embed mode, progress mark, Continue  
- foundation + types/ingredients/categories screens — chrome  
- `onboarding_menu_items_screen.dart` — FAB Stack + preview  
- `franchise_feature_provider_impl.dart` — validate()  
- `owner_hq_dashboard_screen.dart` — 5-step progress + cascades  
- review summary / issue expansion / navigation utils / review screen  

---

**Last updated:** July 26, 2026 (W1–W3 + W6 implemented and smoke-passed; next = W4 then W5)  
**Next:** Human GA list for W4; then HQ Platform billing one-card (W5).
