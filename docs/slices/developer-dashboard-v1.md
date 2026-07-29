# Slice: Developer Dashboard v1

**Status**: **COMPLETE** (D0–D10 product + docs)  
**Branch**: `feat/developer-dashboard-v1`  
**Authority**: STATUS / HANDOFF / `docs/DASHBOARDS.md` §4  
**Depends on**: Platform Owner MVP; Admin ops; menu modifier epic on `main`  
**Locked**: July 28, 2026 (~19:35 CDT)  
**Completed**: July 28, 2026 (~22:40 CDT)

---

## 1. Problem

Developer surface already existed (`DeveloperDashboardScreen` + section widgets + DevTools group) but was deprioritized while menu/onboarding shipped. Risks addressed in this slice:

- Half-wired / mock sections under real franchise ids
- FranchiseId edge cases (`unknown` / empty / `all`)
- Overlapping error-log UIs (section is primary SoT from developer nav)
- Dangerous write tools mixed under soft “Dev Tools” label
- Impersonation needs support/debug oriented (UI preview only in v1)

---

## 2. Locked product rules (summary)

| Topic | Lock |
|--------|------|
| Role | `developer` only |
| Error Logs | Franchise \| Global; real streams; Timestamp normalize; `error_logs` + `public_error_logs` |
| Impersonation | Phase A UI-only preview + banner; **no** claim mutation |
| Feature toggles | Franchise write merge + confirm; global **read-only** |
| Schema Browser | Functional raw inventory; concrete franchise required |
| Audit Trail | Functional; Franchise \| Global streams |
| Plugin Registry | Explicit stub page |
| Dangerous group | Label **Dangerous** (was Dev Tools) |
| Franchise matrix | Concrete vs platform/`all` empty states |

Rules note: add `match /public_error_logs/{docId}` with same access as `error_logs` if not already deployed.

---

## 3. Workstreams

| ID | Name | Status |
|----|------|--------|
| **D0** | Docs lock | **Done** |
| **D1** | Inventory sections | **Done** |
| **D2** | FranchiseId hygiene (inline per section) | **Done** |
| **D3** | Error Logs unified + Franchise\|Global | **Done** |
| **D4** | Impersonation Phase A | **Done** |
| **D5** | Feature toggles franchise write / global read | **Done** |
| **D6** | Schema Browser functional | **Done** |
| **D7** | Audit Trail functional | **Done** |
| **D8** | Plugin Registry stub | **Done** |
| **D9** | Relabel Dev Tools → Dangerous | **Done** |
| **D10** | Acceptance + docs close | **Done** |

---

## 4. Acceptance checklist

### Access & shell

- [x] `developer` role opens dashboard; non-developer blocked
- [x] Franchise picker drives section franchiseId
- [x] Dashboard switcher reachable

### Franchise matrix

- [x] Concrete-required sections show **Select a franchise** when id is `all` / missing / invalid
- [x] Global Error Logs / Audit / Dangerous usable without forcing a fake tenant

### Error Logs

- [x] Primary section from developer shell
- [x] Toggle Franchise \| Global
- [x] Franchise mode → `franchises/{id}/error_logs`
- [x] Global mode → `error_logs` + `public_error_logs` (normalize Timestamps; soft-skip bad docs)

### Impersonation Phase A

- [x] Preview does **not** change Auth claims
- [x] In-section banner **Viewing as … (preview)**
- [x] Exit preview clears state

### Feature toggles

- [x] Franchise load + merge write with confirm + snackbar
- [x] Global read-only

### Schema / Audit / Plugin / Dangerous

- [x] Schema Browser raw collection samples (no model parse crashes)
- [x] Audit Trail global + franchise streams
- [x] Plugin Registry explicit stub
- [x] Sidebar group labeled **Dangerous**

### Safety

- [x] No new shared_core model fields for this slice
- [x] No DesignTokens invention
- [x] No `FranchiseProvider()` zero-arg
- [x] No menu dual-tree / modifier schema changes

---

## 5. Key implementation files

- `web-app/lib/admin/developer/developer_dashboard_screen.dart` (Dangerous label)
- `web-app/lib/widgets/developer/error_logs_section.dart`
- `web-app/lib/widgets/developer/impersonation_tools_section.dart`
- `web-app/lib/widgets/developer/feature_toggles_section.dart`
- `web-app/lib/widgets/developer/schema_browser_section.dart`
- `web-app/lib/widgets/developer/audit_trail_section.dart`
- `web-app/lib/widgets/developer/plugin_registry_section.dart`
- `packages/shared_core/lib/src/core/services/firestore_service_impl.dart` (error log normalize + dual collection stream)

---

## 6. Non-goals (still out)

- Real claim/token impersonation (Phase B)
- Global feature toggle writes
- Fold/delete of legacy error log screens (optional residual)
- Shared helper extraction for `isConcreteFranchiseId`
- Overview KPI rewrite
- Plugin marketplace

---

## 7. Exit criteria

- [x] D1–D10 Done in this file / STATUS
- [x] Human smoke green on primary paths (Error Logs, Schema, Toggles, Audit, Plugin stub, Dangerous)
- [ ] Merge to `main` — **separate human gate**

**Bottom line:** Developer Dashboard v1 is **complete** as an honesty + hygiene slice: unified Error Logs, UI-only impersonation, franchise feature write / global read, functional Schema + Audit, stub Plugin Registry, Dangerous-labeled tools — existing Firestore paths only.
