# Slice: HQ Design & Branding v1

**Status:** Complete (v1) — July 24, 2026  
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
| Write path | **None yet** — no branding save API (v1.1 later) |
| Dashboard card | Inline on `OwnerHQDashboardScreen` — name, logo (when URL), primary/secondary swatches + **Open Design & Branding** CTA |
| Screen | `web-app/lib/admin/hq_owner/screens/design_branding_screen.dart` |
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

### 3.1 Dashboard card (landed)

**File:** `web-app/lib/admin/hq_owner/owner_hq_dashboard_screen.dart`

- Title “Live Branding Preview” + palette icon
- Live app name (`DesignTokens.currentAppName`)
- Logo when `DesignTokens.currentLogoUrl` non-null/non-empty
- Primary / secondary swatches from live Color getters
- Button **Open Design & Branding** → `Navigator.push` + `MaterialPageRoute` → `DesignBrandingScreen`

### 3.2 Design & Branding screen (landed)

**Path:** `web-app/lib/admin/hq_owner/screens/design_branding_screen.dart`

- AppBar title **Design & Branding**; Back → pop to Owner HQ
- Franchise context label from `FranchiseProvider.franchiseId`
- Live preview: draft-driven name, logo Image + fallback, swatches, hex labels
- Draft form: app name, logo URL, primary hex, secondary hex (local State only)
- Save → SnackBar **“Save not wired yet”**; Cancel → reset drafts to live values

---

## 4. Persistence policy

| Stage | Behavior |
|-------|----------|
| **v1 (complete)** | Local draft state drives screen preview. Save shows snackbar only. **No write.** |
| **v1.1 (follow-up)** | Real write to existing `franchises/{id}` branding keys only, then `setBrandingFromFranchiseDoc` + rebuild. Human-designed; no new collections. |

Read remains: existing bootstrap fetch + `setBrandingFromFranchiseDoc`.

---

## 5. Navigation policy

- **Do not** register this screen in `section_registry.dart` (Admin-only).
- **Do** open via `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DesignBrandingScreen()))` from the dashboard card.
- Named route / Quick Links entry = optional later after HQ route table is cleaned up.
- Back always returns to Owner HQ dashboard for this entry path.

---

## 6. Implementation order

| Step | Who | Work | Status |
|------|-----|------|--------|
| **S0** | Human / Grok | Docs locked | Done |
| **S1** | Human / Grok | Screen shell | Done |
| **S2** | Human / Grok | Card CTA | Done |
| **S3** | Human | Franchise context | Done |
| **S4** | Human / Grok | Live preview | Done |
| **S5** | Human / Grok | Draft fields + Stateful | Done |
| **S6** | Human / Grok | Save snackbar + Cancel | Done |
| **S7** | Human | Smoke | Done |
| **S8** | Later | v1.1 persistence | Open |

---

## 7. Explicit out of scope (v1)

- Firestore branding writes
- Logo file upload / Storage
- App chrome mock
- Multi-brand editor
- Admin `section_registry` entry
- Mobile app Design & Branding UI
- New DesignTokens / BrandingConfig fields
- Color picker UI (downstream of v1.1)
- Fixing all `/hq/*` `onGenerateRoute` paths (optional follow-up)

---

## 8. Acceptance checklist

- [x] Card still shows name, logo (if any), primary/secondary
- [x] **Open Design & Branding** opens new screen
- [x] Back returns to Owner HQ dashboard
- [x] Screen shows franchise context for selected franchise
- [x] Preview shows name, logo image or fallback, swatches, hex labels
- [x] Draft fields update on-screen preview only
- [x] Save shows **“Save not wired yet”** and writes nothing
- [x] No new config class fields; no new Firestore paths
- [x] STATUS.md checkboxes updated when landed

---

**Last updated:** July 24, 2026 (v1 complete)
