# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — polish-v1 decisions locked)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent (full for status/planning; short excerpt in minimal coding mode).

---

## Current Phase

**Phase 1 – Agent Hardening → Core Config Scoping & Dynamic Branding**

Phase 0 complete (July 23, 2026).

### A. Agent hardening

- [x] Soften over-refusal, validator, SCOPE_CARD, hard bans, path allowlist, auto-reject, `no_change`, `/metrics`
- [x] Multi-file parse/apply; xAI-first mode; quote-first lessons (July 25)
- [ ] Optional model A/B; structured unified-diff; empty-file full-file apply; validator honor `max_regions`

### B. Product — Core config scoping & dynamic branding

**Live franchise branding + single provider (July 26) — COMPLETE**

- [x] FranchiseProvider ChangeNotifier; branding setters `_bumpConfig()` / `notifyListeners`
- [x] Single web FranchiseProvider at app root (no authenticated duplicate)
- [x] Picker doc load + stale-response guard; `setFranchiseId` clears prior branding map
- [x] MaterialApp + HQ AppBar live primary; DesignTokens bridge

**Design & Branding screen v1/v1.1** — COMPLETE (Save + draft resync). Color picker downstream.

**Onboarding host migration** — COMPLETE (HQ sole host).

**Menu Items v1** — COMPLETE — `docs/slices/hq-onboarding-menu-items-v1.md`

### Active slice: `docs/slices/hq-onboarding-hq-polish-v1.md`

**Locked decisions (July 26):**

| Topic | Decision |
|-------|----------|
| Branding in onboarding | **New step** between Feature Setup and Foundation; section + progress key **`onboarding_design_branding`** |
| Foundation tab Mark complete | **Remove** |
| Billing summary vs Invoices | **Merge** to one **Billing & invoices — In development** card |

**Product key order (target):**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Workstreams still open:** W3 Review false positive; W1 foundation chrome; W2 FAB/preview parity; W6 branding step wiring; W4 feature in-dev; W5 HQ dashboard honesty.

**Ground truth (do not regress):**

- One web FranchiseProvider at root only
- No new DesignTokens/BrandingConfig fields
- Progress path `franchises/{id}/onboarding_progress/progress`
- Do not invent alternate branding progress key names
- Menu delete = `deleteMenuItem` / `deleteMenuItemAndPersist`
- Agent mode: xAI primary

---

## Target workflow

1. Agent proposes → human `/approve` → `/approve confirm` → human git  
2. Never Firestore/production from agents  
3. HARD BAN / `after parsed: no` → reject  

**Update this file after significant sessions.**
