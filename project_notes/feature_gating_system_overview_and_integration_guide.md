# 🔒 Feature Gating System: Overview & Integration Guide

This document outlines the purpose, usage, and relationships of the newly introduced feature gating files used across the Franchise Admin Portal. These tools support modular feature visibility and enablement across UI elements, onboarding workflows, and upsell prompts.

---

## 📂 Files & Purpose

### 1. `enum_platform_features.dart`

**Location**: `lib/core/constants/`

Defines a type-safe `enum PlatformFeature` for managing all platform-wide feature modules, such as `inventory`, `mobile_ordering`, `loyalty`, etc. Includes a `.key` extension to convert enum values into Firestore-style `snake_case` strings.

**Use this when**:

* You want to avoid hardcoding strings.
* You need clean mapping from enums to Firestore keys.

---

### 2. `feature_extensions.dart`

**Location**: `lib/core/extensions/` *(recommended)*

Provides convenient `BuildContext` extensions to check feature availability without boilerplate:

* `context.hasFeature('inventory')`
* `context.isFeatureEnabled('inventory')`

**Use this when**:

* You want to perform lightweight checks without widgets.
* You’re inside UI or routing logic and need instant feature reads.

---

### 3. `feature_gate.dart`

**Location**: `lib/widgets/devtools/`

The core UI feature gating wrapper. Conditionally renders or restricts widgets based on enabled feature modules or subfeatures. Supports 3 fallback styles:

* `hidden` – completely hides gated content.
* `dimmed` – greys out content and disables interaction.
* `lockedBanner` – overlays upsell messaging and lock icon.

**Use this when**:

* Gating dashboard cards, tabs, or forms based on plan tier.
* Gating onboarding steps based on selected features.

---

### 4. `feature_gate_wrapper.dart`

**Location**: `lib/widgets/devtools/`

Simplified wrapper over `FeatureGate`, exposing the same API but allowing for:

* Cleaner integration syntax.
* Easier refactoring (e.g., switching fallback types in one line).

**Use this when**:

* Replacing many hardcoded `FeatureGate`s in a screen.
* Rapidly scaffolding feature-based sections.

---

### 5. `feature_gate_banner.dart`

**Location**: `lib/widgets/devtools/`

A specialized wrapper for gating visual sections using a semi-transparent lock overlay. Keeps content visible but inaccessible, with upgrade prompts.

**Use this when**:

* You want to upsell locked features.
* You want the user to visually discover premium modules.

**Avoid when**:

* You need zero layout impact.

---

### 6. `feature_lock_overlay.dart`

**Location**: `lib/widgets/devtools/`

A reusable overlay widget used by `feature_gate_banner` and `FeatureGate` when `fallbackStyle = lockedBanner`. Centralizes lock icon + upgrade button UI.

**Use this when**:

* Overlaying lock messaging over section cards or disabled areas.

---

### 7. `feature_guard.dart`

**Location**: `lib/utils/`

Declarative `StatelessWidget` for hiding or replacing content based on feature status. Renders either `child` or `fallback`.

**Use this when**:

* Gating layout elements (buttons, sections) from scratch.
* Building widgets that dynamically reflect feature plans.

**Not for**:

* Upsell overlays. Use `FeatureGate` for those.

---

### 8. `feature_guard_wrapper.dart`

**Location**: `lib/utils/`

Optional wrapper for simplifying usage of `FeatureGuard`. Aligns with the same logic and naming patterns as `FeatureGateWrapper`, but for full-content replacement scenarios.

**Use this when**:

* Wrapping text, buttons, or custom widgets that have simpler fallback logic.

---

### 9. `feature_toggle_scaffold.dart`

**Location**: `lib/admin/devtools/` *(or onboarding config folder)*

Visual toggle list of all `PlatformFeature` modules with adaptive `SwitchListTile`s. Intended for onboarding configuration or platform developer tools.

**Use this when**:

* Onboarding franchises into their feature setup.
* Debugging what modules are enabled/disabled.

---

## 🔗 Common Integration Pattern

```dart
FeatureGate(
  module: PlatformFeature.inventory.key,
  fallbackStyle: FeatureFallbackStyle.lockedBanner,
  lockedMessage: 'Upgrade to enable Inventory Management.',
  onTapUpgrade: () => context.pushNamed('/platform/plans'),
  child: InventoryCard(),
)
```

---

## 🚀 Next Steps

* Integrate feature toggle config with Firestore `/franchise_features`.
* Build dev-only screen to inspect all franchise plans + feature state.
* Wire these into onboarding flow to dynamically hide or show modules.

---