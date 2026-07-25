# Slice: HQ Design & Branding v1

**Status:** Locked — July 24, 2026  
**Branch:** `feat/onboarding-4step`  
**Authority:** This file + `docs/DECISIONS.md` Decision 8 + `STATUS.md`  
**Owner surface:** HQ Owner only (`OwnerHQDashboardScreen`)

---

## 1. Product intent

HQ Owner manages **franchise branding** for the **selected franchise** (customer-facing brand signals: name, logo, primary/secondary colors).

This is **not** a general “restyle the entire admin portal” tool. Authenticated web themes already consume live `DesignTokens.primaryColor` / `secondaryColor`, so franchise colors affect HQ chrome too — that is expected franchise-scoped theming, not a separate admin-only theme editor.

**Success (v1):**  
HQ Owner sees the existing live branding card on the dashboard; **Open Design & Branding** opens a dedicated screen for the **selected franchise** with live preview (name, logo image with fallback, primary/secondary + hex), draft fields for those values, franchise context label, Back, and a **Save** control that shows snackbar **“Save not wired yet”** and does **not** write Firestore.

---

## 2. Ground truth (do not regress)

| Fact | Detail |
|------|--------|
| Live web path | `FranchiseProvider` → `DesignTokens.setFranchiseProvider` → `DesignTokens.primaryColor` / `secondaryColor` / `currentAppName` / `currentLogoUrl` |
| Read path | `franchises/{id}` → `setBrandingFromFranchiseDoc` (keys: `primaryColorHex`, `secondaryColorHex`, nested `branding.*`, `appName`/`name`, `logoUrl`/`logo`) |
| Write path | **None yet** — no branding save API |
| Dashboard card | Inline on `OwnerHQDashboardScreen` — name, logo (when URL), primary/secondary swatches |
| `section_registry.dart` | **Admin sidebar only** — not used by HQ Owner |
| HQ routing | HQ home is `OwnerHQDashboardScreen`; `onGenerateRoute` collapses many `hq*` names back to that dashboard |

**Hard stops**

- No new fields on `BrandingConfig` / `DesignTokens` / `AppConfig` / `FeatureConfig`
- No new Firestore collections or paths in v1
- No invented `FranchiseProvider()` zero-arg / `FirestoreService.collection`
- Prefer existing getters only; stop and ask human if a required UI need has no matching getter
- No multi-brand editing in this slice
- Agents: path allowlist; quote-first; no multi-file “while you’re at it”

---

## 3. Surfaces

### 3.1 Dashboard card (keep content; add CTA)

**File:** `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart` (inline card today)

**Keep showing (same as today)**

- Title “Live Branding Preview” + palette icon
- Live app name (`DesignTokens.currentAppName`)
- Logo when `DesignTokens.currentLogoUrl` non-null/non-empty (existing `Image.network`)
- Primary / secondary swatches from live Color getters

**Add**

- Button label: **Open Design & Branding**
- On pressed: `Navigator.push` + `MaterialPageRoute` → new Design & Branding screen (not `section_registry`; not relying on coarse `/hq/*` `onGenerateRoute`)

Optional later: extract card to `web-app/lib/admin/hq_owner/widgets/live_branding_preview_card.dart`.

### 3.2 Design & Branding screen (new)

**Proposed path:** `web-app/lib/admin/hq_owner/screens/design_branding_screen.dart`

**Chrome**

- AppBar title: **Design & Branding**
- Leading **Back** → `Navigator.pop` to Owner HQ dashboard
- Franchise context label: selected franchise id (and name if already available from existing provider surfaces — no new fields)

**Layout sections (v1)**

1. **Live preview** (must)
   - App name
   - **Logo image** when draft/live URL is non-empty; **fallback** placeholder (icon + “No logo”) when missing/failed load
   - Primary + secondary color swatches
   - Hex labels under colors (from existing `FranchiseProvider.currentPrimaryColorHex` / `currentSecondaryColorHex` or draft hex strings — never treat hex as `Color` on DesignTokens)

2. **Draft form** (must) — local `State` only; drives on-screen preview
   - App name text field
   - Logo **URL** text field (upload UI = later)
   - Primary color control (hex text field and/or simple control; draft only)
   - Secondary color control (same)

3. **Actions** (must)
   - **Save / Apply** — **enabled**; on press: SnackBar **“Save not wired yet”**; **no Firestore write**
   - **Cancel** — discard local draft and/or pop (exact UX: prefer discard draft + stay, or pop — implementer may use Back for leave and Cancel for reset draft)

4. **App chrome mock** — **later** (out of v1)

---

## 4. Persistence policy

| Stage | Behavior |
|-------|----------|
| **v1 (this slice)** | Local draft state drives screen preview. Save shows snackbar only. **No write.** |
| **v1.1 (follow-up)** | Real write to existing `franchises/{id}` branding keys only, then `setBrandingFromFranchiseDoc` + rebuild. Human-designed; no new collections. |

Read remains: existing bootstrap fetch + `setBrandingFromFranchiseDoc`.

---

## 5. Navigation policy

- **Do not** register this screen in `section_registry.dart` (Admin-only).
- **Do** open via `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DesignBrandingScreen()))` from the dashboard card.
- Named route / Quick Links entry = optional later after HQ route table is cleaned up.
- Back always returns to Owner HQ dashboard for this entry path.

---

## 6. Implementation order (human / Grok shell → agents)

| Step | Who | Work |
|------|-----|------|
| **S0** | Human / Grok | Docs locked (this file, Decision 8, STATUS) |
| **S1** | Human / Grok | New empty `design_branding_screen.dart` — Scaffold, AppBar, Back, placeholder body |
| **S2** | Human / Grok | Card button **Open Design & Branding** → push screen |
| **S3** | Agent-eligible | Franchise context label on screen |
| **S4** | Agent-eligible | Live preview block (name, logo+fallback, swatches, hex) from live tokens / provider |
| **S5** | Agent-eligible | Draft fields (name, logo URL, primary/secondary) wired to local state + preview |
| **S6** | Agent-eligible | Save → SnackBar “Save not wired yet”; Cancel/reset draft |
| **S7** | Human | Smoke on device/emulator; STATUS checkboxes |
| **S8** | Later | v1.1 persistence write path |

Agents remain proposal-only; path allowlist; one region (or rare dual-edit) per task after shell exists.

---

## 7. Explicit out of scope (v1)

- Firestore branding writes
- Logo file upload / Storage
- App chrome mock
- Multi-brand editor
- Admin `section_registry` entry
- Mobile app Design & Branding UI
- New DesignTokens / BrandingConfig fields
- Fixing all `/hq/*` `onGenerateRoute` paths (optional follow-up)

---

## 8. Acceptance checklist

- [ ] Card still shows name, logo (if any), primary/secondary
- [ ] **Open Design & Branding** opens new screen
- [ ] Back returns to Owner HQ dashboard
- [ ] Screen shows franchise context for selected franchise
- [ ] Preview shows name, logo image or fallback, swatches, hex labels
- [ ] Draft fields update on-screen preview only
- [ ] Save shows **“Save not wired yet”** and writes nothing
- [ ] No new config class fields; no new Firestore paths
- [ ] STATUS.md checkboxes updated when landed

---

**Last updated:** July 24, 2026
