# Slice: HQ Onboarding & HQ Dashboard Polish v1

**Status:** Spec locked — implementation open  
**Branch:** `feat/onboarding-4step`  
**Created:** July 26, 2026  
**Authority:** This file + STATUS.md + human product decisions below  
**Depends on (done):** Menu Items v1; FranchiseProvider ChangeNotifier + single root instance; live HQ branding on switch; picker stale-response guard  
**Owner surfaces:** HQ Owner onboarding shell + Owner HQ dashboard  
**Agent policy:** Derive **surgical outcome tasks** from this card only after human locks the open product choices in §3. No redesign of Menu Items v1. No second FranchiseProvider. No new DesignTokens/BrandingConfig fields.

---

## 1. Product intent

Make onboarding and the HQ home **honest for MVP**:

- No dead navigation, no false Review errors, no fake “complete” controls.
- Foundation and Menu Items share the same preview/FAB layout language.
- Features and dashboard cards that are not production-ready stay **visible but labeled In development** (not silently broken).
- Franchise switch continues to scope branding **and** domain data (already proven); polish must not regress that.

**Success (v1):** Owner can walk Feature Setup → Foundation → Menu Items → Review without false blockers; foundation tabs have no JSON/back-arrow noise; Step 3 FAB matches Step 2; HQ cards either work franchise-scoped or show In development; optional path for branding in onboarding is decided and either implemented lightly or explicitly deferred.

---

## 2. Ground truth (do not regress)

| Fact | Detail |
|------|--------|
| Onboarding host | `HqOnboardingShellScreen` only; Admin onboarding tree deleted |
| Progress path | `franchises/{id}/onboarding_progress/progress` |
| Product keys | `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview` |
| Foundation product complete | Save & Continue / explicit foundation complete — **not** tab-only mark complete |
| Menu Items | Slice closed; shared `MobileMenuPreviewCard`; `deleteMenuItem` / `deleteMenuItemAndPersist` |
| FranchiseProvider | **Single** web instance at app root; `ChangeNotifier`; branding setters call `_bumpConfig()` |
| Live branding | `DesignTokens` ← FranchiseProvider; MaterialApp `appBarTheme` + HQ AppBar use primary |
| Picker | After id change, load doc; apply only if `franchiseId == requestedId` |

---

## 3. Locked / pending product decisions

### 3.1 Design & Branding in onboarding (pending human pick)

| Option | Description | v1 lean |
|--------|-------------|--------|
| **A. New shell section** | e.g. Identity step before or after Feature Setup; embed/reuse `DesignBrandingScreen`; new progress key only if human approves key name | Heavier |
| **B. Review gate only** | Review requires appName + primary/secondary present; CTA opens Design & Branding | Lighter |
| **C. Defer** | HQ card only (status quo) | Fastest |

**Until chosen:** no agent tasks that invent progress keys or restructure the 4-step order.

### 3.2 Foundation tab “Mark complete”

| Option | Rule |
|--------|------|
| **Preferred** | **Remove** mark-complete from Ingredient Types / Ingredients / Categories chrome when it does not write product keys |
| Alternate | Keep only if wired to **sub-keys** for foundation detail % — never mark `onboarding_menu_foundation` from tab-only |

### 3.3 Billing summary vs Invoices (HQ)

| Option | Rule |
|--------|------|
| **Preferred** | **One** billing/invoices story for MVP: either real invoices card **or** combined “Billing & invoices — In development” if both are mock/dead |
| Alternate | Keep both only if each has distinct working data (plan/subscription vs invoice list) |

### 3.4 Feature Setup “In development”

- Human owns the **GA vs dev** list (Firestore `platform_features` status field preferred; else const allowlist in screen).
- UI: row still visible; toggle **disabled**; chip/note **In development**.
- Do not delete platform feature docs from this slice.

---

## 4. Workstreams (ordered)

### W1 — Foundation chrome honesty (Step 2)

**Files (expected):**

- `onboarding_ingredient_type_screen.dart`
- `onboarding_ingredients_screen.dart`
- `onboarding_categories_screen.dart`
- `onboarding_menu_foundation_screen.dart` (if chrome lives here)

**Requirements:**

1. **Remove back arrow** on Ingredient Types and Categories when embedded in HQ shell (shell owns back). Same for Ingredients if it still shows a competing leading back.
2. **Remove JSON import/export entry points** from Types, Ingredients, and Categories onboarding surfaces (dialogs may remain in tree unused; no user-facing buttons/menus on these screens).
3. **Tab mark complete:** implement §3.2 (remove or sub-key only).
4. Do not change foundation Continue gates, orphan rules, or product key writers except as required by §3.2.

**Exit:** No JSON CTAs; no redundant AppBar back; no non-functional “Mark complete” that implies product step done.

---

### W2 — Step 3 FAB + preview parity

**Files:**

- `onboarding_menu_items_screen.dart`
- `onboarding_menu_foundation_screen.dart` (reference layout)
- `mobile_menu_preview_card.dart` (size source of truth — avoid divergent chrome)

**Requirements:**

1. **FAB:** “Add menu item” sits at **bottom of the list (left) pane**, same visual language as Step 2 foundation FAB placement — not below/under the preview column.
2. **Preview sizing:** Step 2 and Step 3 call sites constrain the shared card the same way (same flex/rail width pattern). Phone chrome remains 340×680 inside the card; do not fork a second phone widget.

**Exit:** Side-by-side smoke: FAB position matches; preview physical size matches within normal layout tolerance.

---

### W3 — Review false positive (“menu management”)

**Problem:** Step 4 reports Feature Setup issue “enable menu management” / Fix now when all features appear enabled.

**Requirements:**

1. **Human/Grok tracer first:** locate Review rule → feature key string → Feature Setup persist path (`FranchiseFeatureProvider` / Firestore).
2. Align key names **or** remove obsolete rule if feature is not part of MVP gate.
3. No schema invention; no new feature flags without human approval.

**Exit:** With features enabled for franchise, Review does not show that false blocker.

---

### W4 — Feature Setup in-development UX

**Files:**

- `onboarding_feature_setup_screen.dart`
- `feature_toggle_tile.dart` (if shared)

**Requirements:**

1. Apply §3.4 list.
2. Dev features: visible, toggle disabled (or non-interactive), **In development** note.
3. GA features unchanged in behavior.
4. Save / mark complete still only reflect real toggles.

**Exit:** Owner cannot “enable” vaporware; UI explains why.

---

### W5 — HQ Owner dashboard MVP honesty

**Files:**

- `owner_hq_dashboard_screen.dart`
- Related cards: invoices, billing summary, payout status, quick links, financial KPI, etc.
- Routes referenced by CTAs

**Requirements:**

1. **Franchise scope:** Every live metric card uses current `franchiseId` from FranchiseProvider (single instance). Re-smoke after switch.
2. **Dead links:** “View all payouts”, “Invoices”, Quick Link targets — either wire to existing screens **or** disable CTA + In development (no silent no-op / broken named routes).
3. **Quick Links:** Only ship working targets (Onboarding works; add Design & Branding if desired; hide/disable others until routes work).
4. **Billing vs Invoices:** implement §3.3.
5. **Card sizing:** Live Branding Preview and Onboarding Progress use the **same grid rhythm** as peer cards (constrained height/aspect consistent with dashboard grid — not a full-bleed outlier unless intentional).
6. Non-MVP / mock-only cards: show content shell + **In development** rather than fake numbers that imply production data.

**Exit:** No broken CTAs; clear MVP vs in-dev; branding + onboarding cards sized with grid; franchise switch still updates branding chrome.

---

### W6 — Design & Branding in onboarding (optional)

Only after §3.1 choice.

- **If B (Review gate):** Review checks branding presence; CTA → existing Design & Branding route; no new progress key required unless human wants one.
- **If A (new step):** Human names section key + progress key; embed existing screen; update shell order + Continue cascade + HQ Continue/Quick Link first-incomplete lists.
- **If C:** Document defer in this file + STATUS; no code.

---

## 5. Explicit out of scope

- Reopening Menu Items v1 architecture / schema sidebar redesign
- Soft-delete menu items; JSON reintroduction on foundation/menu
- Second `FranchiseProvider` under authenticated MultiProvider
- New DesignTokens / BrandingConfig / FeatureConfig fields
- Full Stripe production integration (decisions only; implementation separate)
- Mobile app feature parity in this slice
- Liberty `ingredientId` type noise
- Color picker UI (downstream of Design & Branding)

---

## 6. Implementation order (recommended)

1. **W3** Review false positive (trust)  
2. **W1** Foundation chrome  
3. **W2** FAB + preview parity  
4. **W4** Feature in-dev flags (after GA list locked)  
5. **W5** HQ dashboard audit  
6. **W6** Branding-in-onboarding if chosen  

xAI: prefer one outcome per task, named files, quote-first, max 1–2 regions; human tracers for W3 and §3 decisions first.

---

## 7. Acceptance checklist

### Foundation

- [ ] No back arrow competing with shell on types/categories (and ingredients if applicable)
- [ ] No JSON import/export actions on types/ingredients/categories onboarding UI
- [ ] No non-functional product-level Mark complete on foundation tabs

### Menu Items / preview

- [ ] Add Menu Item FAB on list pane bottom-end (Step 2 parity)
- [ ] Step 2 vs Step 3 preview size parity with shared card

### Review / features

- [ ] No false “enable menu management” when features enabled
- [ ] Non-GA features show In development and cannot be toggled on as if live

### HQ dashboard

- [ ] Payouts / Invoices / Quick Links: working or explicitly In development
- [ ] Billing vs Invoices decision implemented
- [ ] Live Branding + Onboarding Progress card sizing aligned to grid
- [ ] Franchise switch still live-brands AppBar + Live Branding card

### Branding-in-onboarding

- [ ] §3.1 decided; A/B implemented or C deferred in STATUS

---

## 8. Smoke scripts

**Onboarding**

1. Feature Setup → only GA toggles interact; save → foundation.  
2. Foundation tabs: no JSON; no bogus back; Continue still gates orphans/counts.  
3. Menu Items: FAB position; preview size vs foundation.  
4. Review: no false menu-management issue with features on.  

**HQ**

1. Switch franchise: AppBar + Live Branding + progress track.  
2. Each card CTA: lands on real screen or disabled/in-dev.  
3. Grid visual: branding + onboarding cards not wildly oversized vs neighbors.  

---

## 9. Related completed work (context only)

| Item | Ref |
|------|-----|
| Menu Items v1 | `docs/slices/hq-onboarding-menu-items-v1.md` |
| Design & Branding v1 | `docs/slices/hq-design-branding-v1.md` |
| Single FranchiseProvider | STATUS July 26 afternoon |
| Branding notify + picker guard | `franchise_provider.dart`, `franchise_picker_dropdown.dart` |

---

**Last updated:** July 26, 2026  
**Next:** Lock §3.1–3.3 if needed; start W3 tracer + W1 xAI outcomes.
