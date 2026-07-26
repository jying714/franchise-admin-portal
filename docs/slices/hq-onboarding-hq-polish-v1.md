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
- **Platform billing** is thin: HQ sees whether the franchise owes the platform (SaaS/subscription), not a full AR workbench.

**Success (v1):** Owner walks Feature Setup → **Design & Branding** → Foundation → Menu Items → Review without false blockers; foundation tabs have no JSON/back-arrow/fake mark-complete; Step 3 FAB matches Step 2; HQ cards work franchise-scoped or show In development; **one** platform-billing card (no dual Billing Summary + Invoices).

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
| Design & Branding UI | Reuse `design_branding_screen.dart`; Save writes franchise + `config/ui_config` |
| Platform invoices | **Platform → franchise** bills (SaaS/subscription/royalties), **not** diner order tickets. Model: `PlatformInvoice`. |

---

## 3. Locked product decisions (July 26, 2026)

### 3.1 Design & Branding in onboarding — **A (LOCKED)**

- **New onboarding step** between Feature Setup and Core Menu Foundation.
- **Section key + progress key:** `onboarding_design_branding`
- **UI:** Reuse existing Design & Branding flow inside HQ shell.
- **Complete when:** successful Save (prefer) → mark step / continue.
- **Nav:** Feature Setup → branding → foundation; first-incomplete cascades + summary use **5** product keys.

### 3.2 Foundation tab “Mark complete” — **REMOVE (LOCKED)**

- Remove from Types / Ingredients / Categories onboarding chrome.
- Never write `onboarding_menu_foundation` from tab-only complete.

### 3.3 Platform billing on HQ — **ONE THIN CARD (LOCKED, refined)**

**Domain:** Invoices are **bills from the platform to the franchise** (subscription/SaaS), not customer POS checks.

**MVP need:** “Do we owe the platform anything?” + path to pay/view if live — **not** a full invoice product.

| Rule | Detail |
|------|--------|
| **One card only** | Remove dual **BillingSummaryCard** + **InvoicesCard** pair from HQ grid |
| **Card name** | **Platform billing** (or “Subscription & fees”) |
| **Default v1 state** | **In development** — no dead `pushNamed('/hq/invoices')` / Pay now that 404 |
| **When data/Stripe is real (later)** | Same single card may show outstanding + overdue + CTA to **Stripe Customer Portal / hosted invoice URL** — still **no** requirement to ship custom list in this slice |
| **Do not for this slice** | Wire full `InvoiceListScreen` as MVP; invent create-invoice; keep zeroed InvoicesCard KPIs; leave broken Quick Link “Invoices” |

**Code context (do not treat as MVP mandate):**

- `BillingSummaryCard` — service-backed AR snapshot; CTAs → `/hq/invoices` (route **not** registered on current HQ MaterialApp).
- `InvoicesCard` on HQ — hard-coded zeros + same dead route.
- `InvoiceListScreen` — exists on disk; orphaned from navigator; post-MVP if ever revived under a billing slice.

### 3.4 Feature Setup “In development”

- Human owns GA vs dev list.
- Dev: visible, toggle disabled, **In development** note.

---

## 4. Workstreams (ordered)

### W1 — Foundation chrome honesty (Step 2)

Remove competing back arrows; remove JSON import/export entry points; **remove** tab Mark complete. Leave Continue/orphan/product-key writers intact.

### W2 — Step 3 FAB + preview parity

FAB on list pane bottom-end; shared `MobileMenuPreviewCard` constraints match foundation.

### W3 — Review false positive (“menu management”)

Tracer → align feature key or drop obsolete rule. No new schema.

### W4 — Feature Setup in-development UX

Apply §3.4 after GA list exists.

### W5 — HQ Owner dashboard MVP honesty

1. Franchise-scoped live cards only where data is real.
2. **§3.3:** one **Platform billing** card (in-dev for v1); remove Billing Summary + Invoices pair; remove/disable Quick Link “Invoices” unless CTA is real.
3. Payouts: wire or **In development** (no broken `/hq/payouts`).
4. Quick Links: Onboarding + Design & Branding (+ only working routes).
5. Live Branding + Onboarding Progress sized to grid peers.
6. Non-MVP mock cards → In development shells.

### W6 — Design & Branding onboarding step

Shell order, progress key `onboarding_design_branding`, handoffs, first-incomplete cascades, summary N/5.

---

## 5. Explicit out of scope

- Menu Items v1 redesign; soft-delete; JSON reintroduction
- Second FranchiseProvider; new DesignTokens/BrandingConfig fields
- **Full Stripe production integration / custom invoice list+detail workbench** (separate future billing slice)
- Color picker; Liberty ingredientId noise
- Restoring dual Billing Summary + Invoices cards

---

## 6. Implementation order

1. **W3** Review false positive  
2. **W1** Foundation chrome  
3. **W2** FAB + preview  
4. **W6** Branding step  
5. **W4** Feature in-dev  
6. **W5** HQ dashboard (platform billing one-card + dead links)  

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
- [ ] Order: feature setup → design branding → foundation → menu items → review
- [ ] Progress key `onboarding_design_branding`
- [ ] Cascades + summary treat 5 product steps

### HQ dashboard
- [ ] **One** Platform billing card (in-dev OK); **not** Billing Summary + Invoices pair
- [ ] No broken invoice/payout named routes from CTAs
- [ ] Quick Links honest
- [ ] Branding + onboarding cards grid-sized
- [ ] Franchise switch still live-brands

---

## 8. Smoke

1. Feature Setup save → **Design & Branding** step.  
2. Save branding → foundation; progress key set.  
3. First-incomplete includes branding when due.  
4. Foundation: no JSON/back/mark-complete noise.  
5. Menu Items FAB + preview vs foundation.  
6. Review: no false feature blocker.  
7. HQ: single platform billing card; no 404 invoice/payout CTAs; franchise switch branding OK.  

---

**Last updated:** July 26, 2026 (platform billing MVP refined: one thin card; invoices = platform→franchise SaaS bills; no dual cards / no custom list required for v1)  
**Next:** W3 Review tracer; then W1 foundation chrome outcomes.
