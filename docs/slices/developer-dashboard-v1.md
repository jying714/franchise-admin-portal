# Slice: Developer Dashboard v1

**Status**: **Locked** (D0) — ready for inventory / implementation  
**Branch**: `feat/developer-dashboard-v1`  
**Authority**: STATUS / HANDOFF / `docs/DASHBOARDS.md` §4  
**Depends on**: Platform Owner MVP; Admin ops; menu modifier epic on `main`  
**Locked**: July 28, 2026 (~19:35 CDT)

---

## 1. Problem

Developer surface already exists (`DeveloperDashboardScreen` + section widgets + DevTools group) but was deprioritized while menu/onboarding shipped. Current risks:

- Half-wired or throw-prone sections under real franchise ids
- FranchiseId edge cases (`unknown` / empty / `all`) leaking or no-op-ing incorrectly
- Multiple overlapping error-log UIs (`ErrorLogsSection`, `AdminErrorLogsScreen`, `DeveloperErrorLogsScreen`)
- Unclear MVP vs toolbox; dangerous write tools mixed with read tools under a soft “Dev Tools” label
- Impersonation needs are support/debug oriented, not permanent claim mutation in v1

Goal of this slice: **honesty, franchise hygiene, and two primary ops paths** (Error Logs + UI impersonation preview) without inventing schema, DesignTokens, or agent-orchestrator product UI.

---

## 2. Existing inventory (do not invent paths)

### Shell

| Item | Path |
|------|------|
| Screen | `web-app/lib/admin/developer/developer_dashboard_screen.dart` |
| Role gate | `roles.contains('developer')` |
| Chrome | Franchise picker, dashboard switcher, sidebar + mobile bottom nav |
| Section model | `shared.DashboardSection` list built in `_getDeveloperSections()` |

### Primary sidebar sections (`sidebarOrder` 0–6)

| Order | Key | Title | Widget path |
|-------|-----|-------|-------------|
| 0 | `overview` | Overview | `web-app/lib/widgets/developer/overview_section.dart` |
| 1 | `impersonationTools` | Impersonation Tools | `.../impersonation_tools_section.dart` |
| 2 | `errorMonitoring` | Error Logs | `.../error_logs_section.dart` |
| 3 | `featureFlags` | Feature Toggles | `.../feature_toggles_section.dart` |
| 4 | `pluginRegistry` | Plugin Registry | `.../plugin_registry_section.dart` |
| 5 | `firestoreSchema` | Schema Browser | `.../schema_browser_section.dart` |
| 6 | `auditTrail` | Audit Trail | `.../audit_trail_section.dart` |

### Dangerous group (today labeled “Dev Tools”, `sidebarOrder` ≥ 7)

| Order | Key | Title | Path |
|-------|-----|-------|------|
| 7 | `billingSubscriptionTools` | Billing Tools | `web-app/lib/admin/devtools/billing/billing_subscription_tools_screen.dart` |
| 8 | `subscriptionDevTools` | Subscription Tools | `.../subscriptions/subscription_dev_tools_screen.dart` |
| 9 | `platformFeaturePlanTools` | Platform Feature & Plan Tools | `.../platform/platform_feature_plan_tools_screen.dart` |

Group widget: `web-app/lib/admin/devtools/widgets/dev_tools_sidebar_group.dart`.

### Duplicate / adjacent error UIs (consolidate)

| File | Disposition in v1 |
|------|-------------------|
| `widgets/developer/error_logs_section.dart` | **Canonical** developer entry |
| `admin/developer/admin_error_logs_screen.dart` | Fold into section or thin wrapper; stop dual product paths |
| `admin/developer/developer_error_logs_screen.dart` | Fold into section or thin wrapper |

### Related platform helpers under developer/

- `web-app/lib/admin/developer/platform/platform_plans_section.dart`
- `web-app/lib/admin/developer/platform/franchise_subscriptions_section.dart`
- `web-app/lib/admin/developer/platform/franchise_subscription_editor_dialog.dart`

Treat as support for Dangerous tools; do not expand scope unless required for smoke.

### Backend touchpoints (read/write already exist — do not invent new collections)

| Concern | Paths |
|---------|--------|
| Franchise error logs | `franchises/{franchiseId}/error_logs` |
| Global error logs | top-level `error_logs` |
| Franchise audit | `franchises/{franchiseId}/audit_logs` |
| Global audit | top-level `audit_logs` |
| Franchise feature toggles | `franchises/{id}/config/features` |
| Global feature toggles | `config/features` |
| Menu / categories / ingredients (schema browser) | franchise subcollections per architecture |

Service: prefer existing `FirestoreService` / `AdminFirestoreService` methods (`streamErrorLogs`, `streamErrorLogsGlobal`, feature toggle getters/setters, audit streams). No new shared_core schema fields.

---

## 3. Locked product rules (do not reopen without human)

### Access

| Topic | Lock |
|--------|------|
| Role | Only users with role **`developer`** |
| Other roles | Unauthorized empty state (existing) |
| Writes | Explicit confirm on any mutation; snackbar success/failure |

### Franchise scope matrix

| Mode | Meaning | Allowed on |
|------|---------|------------|
| **Concrete franchise** | Valid non-empty id, not `unknown` / `default` | Franchise Error Logs, Schema Browser, franchise Feature Toggle **write**, Impersonation *into* a tenant |
| **Platform / `all`** | Explicit platform aggregate or picker “all” | Global Error Logs, Dangerous billing/subscription/plan tools, Audit **global** stream |
| **Invalid** | empty / `unknown` | Safe empty states; **no** global collectionGroup customer-data leaks |

**UI rule:** if a section **requires** a concrete franchise and selection is `all` / missing → empty state copy: **“Select a franchise”** (not a spinner forever, not a silent global read).

### Primary paths (both required in v1)

#### A. Error Logs (must-have)

| Rule | Lock |
|------|------|
| Single surface | One Error Logs section in developer shell |
| Source toggle | **Franchise** \| **Global** |
| Franchise mode | Requires concrete `franchiseId` → `franchises/{id}/error_logs` |
| Global mode | Top-level `error_logs`; optional filters (severity, franchiseId field on docs, date if already supported) |
| Actions (minimum) | List + filter + open detail; resolve/archive **only if** existing service methods already support without new schema |
| Dedupe | Stop shipping three parallel “product” error screens; section is SoT from developer nav |

#### B. Impersonation / role simulation (must-have) — **Phase A only**

| Rule | Lock |
|------|------|
| Depth | **UI-only preview** |
| Affordances | Franchise picker + dashboard/role preview + persistent banner **“Viewing as … (preview)”** |
| Does **not** | Mutate Firebase Auth custom claims or issue long-lived tokens |
| Purpose | Support can open HQ/Admin chrome and scoped franchise context without true permission rewrite |
| Phase B (explicit non-goal unless new slice) | Time-boxed claim override via Cloud Function, audit + hard expiry |

Rationale: v1 goals are navigation honesty and franchise context for logs/schema; permission-denied vs product-bug under real rules is a later slice.

### Feature toggles

| Scope | Lock |
|-------|------|
| Franchise `config/features` | **Write merge allowed** for `developer` only; confirm dialog + snackbar |
| Global `config/features` | **Read-only** in this slice (no platform-wide killswitch writes) |
| Invalid franchise | No write; empty / select franchise |

### Schema Browser

| Rule | Lock |
|------|------|
| Status | **Functional** (not inventory-only) |
| Scope | Concrete franchise required |
| Behavior | Browse known franchise subcollections / docs relevant to support (menu_items, categories, ingredient_metadata, config, onboarding_progress, etc.) without inventing collections |
| Safety | Read-focused; no bulk delete in v1 |

### Audit Trail

| Rule | Lock |
|------|------|
| Status | **Functional** |
| Scope | Global stream allowed in platform mode; franchise stream when concrete id selected |
| Behavior | List + filter using existing audit helpers; no new audit schema |

### Plugin Registry

| Rule | Lock |
|------|------|
| Status | **Stub entire page** |
| UI | Explicit placeholder: not implemented / deferred |
| Code | May keep file; must not pretend live plugin data |

### Dangerous tools (relabel)

| Rule | Lock |
|------|------|
| Label | Sidebar group **“Dangerous”** (replace “Dev Tools”) |
| Contents | Keep Billing / Subscription / Platform Feature & Plan tools |
| Platform mode | Allowed when franchise is `all` / platform |
| UX | Clear visual that writes are high-impact (group name is the primary signal; optional secondary warning on entry) |

### Overview

| Rule | Lock |
|------|------|
| Status | Keep; honesty only — links/counts that work or explicit empty |
| No | Fake KPI inventing platform health without real sources |

---

## 4. Architecture notes

```
DeveloperDashboardScreen
  ├─ role gate: developer
  ├─ FranchisePickerDropdown  → FranchiseProvider.franchiseId
  ├─ DashboardSwitcherDropdown (preview navigation)
  ├─ Sidebar sections 0–6
  │     ErrorLogsSection: mode Franchise|Global
  │     ImpersonationToolsSection: Phase A banner + preview only
  │     FeatureTogglesSection: franchise write / global read
  │     SchemaBrowserSection: franchise required
  │     AuditTrailSection: global or franchise
  │     PluginRegistrySection: stub
  └─ Dangerous group (≥7): billing / subscription / plan tools
```

### FranchiseProvider contract (do not regress)

- Use injected / provided `FranchiseProvider` only — **no** `FranchiseProvider()` zero-arg
- No new DesignTokens fields
- Section builders already take `franchiseId: getFranchiseOrNull(context)` — harden null/`all` handling inside each section

### Error logging from the shell

Existing section `try/catch` + `ErrorLogger.log` in `DeveloperDashboardScreen` stays; prefer fixing root causes over swallowing.

---

## 5. Workstreams

| ID | Name | Status |
|----|------|--------|
| **D0** | Docs lock (this slice + STATUS/HANDOFF/DASHBOARDS pointers) | **Done** (this file) |
| **D1** | Inventory: open every section; catalog stubs, throws, dead UI | Open |
| **D2** | FranchiseId hygiene matrix across all section builders | Open |
| **D3** | Error Logs: single surface + Franchise\|Global toggle; fold duplicate screens | Open |
| **D4** | Impersonation Phase A: preview + banner + franchise context | Open |
| **D5** | Feature toggles: franchise write merge + global read-only | Open |
| **D6** | Schema Browser functional (read) | Open |
| **D7** | Audit Trail functional (global + franchise) | Open |
| **D8** | Plugin Registry → explicit stub page | Open |
| **D9** | Relabel Dev Tools → **Dangerous**; smoke billing/subscription/plan entry | Open |
| **D10** | Acceptance smoke + STATUS/DASHBOARDS/HANDOFF close | Open |

### Suggested build order

D1 → D2 → **D3** + **D4** (primary paths) → D5 → D6 → D7 → D8 → D9 → D10

Prefer surgical PRs / commits per workstream; no multi-file “while you’re at it” outside the listed IDs.

---

## 6. Acceptance checklist

### Access & shell

- [ ] `developer` role opens dashboard; non-developer blocked
- [ ] Franchise picker changes `FranchiseProvider` and rebuilds dependent sections
- [ ] Dashboard switcher still reachable for preview navigation
- [ ] Mobile bottom nav lists sections without crash

### Franchise matrix

- [ ] Sections that require concrete franchise show **“Select a franchise”** when id is `all` / missing / invalid
- [ ] Global Error Logs and Dangerous tools usable in platform/`all` mode
- [ ] No unintended top-level customer collection reads for franchise-scoped tools

### Error Logs

- [ ] One primary Error Logs entry from developer shell
- [ ] Toggle Franchise \| Global works
- [ ] Franchise mode lists `franchises/{id}/error_logs` for a real id
- [ ] Global mode lists top-level `error_logs`
- [ ] Duplicate standalone screens not required for the happy path (folded or redirected)

### Impersonation Phase A

- [ ] Preview flow does **not** change Auth claims
- [ ] Banner **“Viewing as … (preview)”** visible while previewing
- [ ] Exit/clear preview restores normal developer chrome

### Feature toggles

- [ ] Franchise map loads; merge write with confirm + snackbar
- [ ] Global map read-only (no save control or save disabled with explanation)

### Schema / Audit / Plugin / Dangerous

- [ ] Schema Browser returns real franchise collection samples or honest empty
- [ ] Audit Trail lists global and/or franchise streams without throw
- [ ] Plugin Registry is an explicit stub (no fake plugins)
- [ ] Sidebar group labeled **Dangerous**; three tool screens open without uncaught exception

### Regression / safety

- [ ] No new shared_core model fields for this slice
- [ ] No DesignTokens invention
- [ ] No `FranchiseProvider()` zero-arg
- [ ] No menu dual-tree / modifier schema changes

---

## 7. Non-goals (explicit)

- Real claim/token impersonation (Phase B / future slice)
- Global feature toggle **writes** / platform killswitches UI
- Full agent orchestrator monitoring product
- Replacing Platform Owner billing as the primary billing UX
- Mobile customer app changes
- Hosting / Cloud Functions Node upgrades
- New Firestore collections or indexes unless proven missing for existing reads (human approval required)
- Plugin marketplace or live plugin runtime
- Bulk destructive schema tools (delete-all collections, etc.)

---

## 8. Key files (implementation targets)

**Must touch (likely)**

- `web-app/lib/admin/developer/developer_dashboard_screen.dart`
- `web-app/lib/widgets/developer/error_logs_section.dart`
- `web-app/lib/widgets/developer/impersonation_tools_section.dart`
- `web-app/lib/widgets/developer/feature_toggles_section.dart`
- `web-app/lib/widgets/developer/schema_browser_section.dart`
- `web-app/lib/widgets/developer/audit_trail_section.dart`
- `web-app/lib/widgets/developer/plugin_registry_section.dart`
- `web-app/lib/admin/devtools/widgets/dev_tools_sidebar_group.dart` (label **Dangerous**)

**Consolidate / retire dual path**

- `web-app/lib/admin/developer/admin_error_logs_screen.dart`
- `web-app/lib/admin/developer/developer_error_logs_screen.dart`

**Docs on close**

- `STATUS.md`, `HANDOFF.md`, `docs/DASHBOARDS.md` §4

**Do not invent**

- New BrandingConfig / DesignTokens members
- New menuProfile / modifierGroups fields

---

## 9. Test / smoke plan (human)

1. Sign in as developer → open Developer dashboard.
2. Sign in without developer → blocked.
3. Picker: concrete franchise → Error Logs Franchise mode shows tenant logs (or honest empty).
4. Toggle Global → top-level logs load.
5. Picker: `all` → franchise-required sections show Select a franchise; Global logs + Dangerous still open.
6. Impersonation preview → banner on; no claim change in Firebase Auth console / token.
7. Feature toggle franchise write → confirm → doc merge; global has no write.
8. Schema Browser on concrete franchise → at least one real collection list.
9. Audit Trail global + franchise → no throw.
10. Plugin Registry → stub copy only.
11. Dangerous group label + open each of three tools.

---

## 10. Exit criteria

Slice **Complete** when:

- D1–D10 checked in this file / STATUS
- Acceptance checklist green under human smoke
- STATUS active focus no longer lists Developer dashboard as open priority-1
- Merge to `main` is a **separate** human gate after smoke

---

**Bottom line:** Developer Dashboard v1 is an **honesty + hygiene** slice: unified Error Logs (franchise|global), UI-only impersonation preview, franchise feature write / global read, functional Schema + Audit, stub Plugin Registry, and **Dangerous**-labeled billing tools — all under strict franchise matrix and existing Firestore paths only.
