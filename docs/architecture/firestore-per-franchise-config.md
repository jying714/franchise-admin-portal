# Firestore Per-Franchise Config Architecture (P3 White-Label)

**Status**: Living Document  
**Owner**: AI Agents + Human Architect  
**Last Updated**: 2026-07-20

**Goal**: All branding, UI, design tokens, app config, and feature toggles are fully white-label / franchise-scoped, editable from the web admin portal, and loaded dynamically in mobile + web apps with strong defaults from `shared_core`.

This document is the **single source of truth** for any LLM agent working on config-related tasks. Do not deviate from the structure, naming, or rules defined here.

## 1. Target Firestore Schema (Exact)

```text
franchises/{franchiseId}
├── config
│   ├── app_config          ← Document (AppConfig values)
│   ├── ui_config           ← Document (merged UiConfig + DesignTokens + BrandingConfig)
│   ├── features            ← Document (FeatureConfig - already exists)
│   └── settings            ← Optional: global franchise settings (billing tier, etc.)
├── branding                ← Legacy collection (phase out)
└── ui                      ← Legacy collection (phase out)

Exact Document Schemas
franchises/{franchiseId}/config/app_config
JSON{
  "apiBaseUrl": "https://api.franchisehq.io",
  "deepLinkScheme": "fhq",
  "deepLinkHost": "f",
  "webDeepLinkHost": "franchisehq.io",
  "isProduction": true,
  // any other AppConfig fields
}
franchises/{franchiseId}/config/ui_config (Main Document)
JSON{
  "primaryColorHex": "#E31837",
  "secondaryColorHex": "#FFD700",
  "accentColorHex": "#E31837",
  "warningColorHex": "#FF9800",
  "errorColorHex": "#F44336",
  "successColorHex": "#4CAF50",
  "backgroundColorHex": "#F9F9F9",
  "surfaceColorHex": "#FFFFFF",
  "textColorHex": "#212121",
  // ... ALL fields from DesignTokens + BrandingConfig + UiConfig
  "logoMain": "https://firebasestorage.googleapis.com/.../logo.png",
  "currentAppName": "Doughboys Pizzeria - Lexington",
  "showLogoInAppBar": false,
  "bannerOverlayAlpha": 128,
  "cardRadius": 8.0,
  // ... full exhaustive list of every token
}
franchises/{franchiseId}/config/features (Existing)
Already defined in FeatureConfig.
```

## 2. Migration Plan (Exact Steps)
Phase 0 (Completed): Unified configs in shared_core.
Phase 1 (Backend):

Create config subcollection under every franchise document.
Migrate existing global config into per-franchise documents using a one-time Cloud Function.
New franchises get default config copied from a global_defaults document or shared_core constants.

Phase 2 (Client):

FranchiseProvider listens to all three config documents.
UiConfig, DesignTokens, BrandingConfig, AppConfig read merged values from provider.
Fallback order: Firestore → shared_core defaults.

Phase 3 (Admin):

Build config editors in web-app.

Phase 4 (Cleanup):

Remove legacy global documents and local delegation files.

## 3. Security Rules (Exact)
JavaScriptrules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /franchises/{franchiseId}/config/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                    (isPlatformOwner(request.auth.uid) ||
                     request.auth.uid in get(/databases/$$   (database)/documents/franchises/   $$(franchiseId)).data.allowedAdmins);
    }
  }
}

## 4. Provider & Loading Logic (Exact)
FranchiseProvider must:

Listen to franchises/{id}/config/ui_config, app_config, features.
Merge into internal state.
Notify listeners on change.
Provide getters used by UiConfig, DesignTokens, etc.

shared_core must expose a ConfigService for loading/saving.

## 5. Image Handling (Logos, Banners, etc.)

Upload to franchises/{franchiseId}/assets/branding/...
Store download URL in ui_config document.
Never store raw file paths.

## 6. Fallback & Default Rules (Strict)

Always fall back to shared_core constants if Firestore field missing or null.
Web and mobile use identical fallback logic unless explicitly overridden in delegation layer.
Global fields (apiBaseUrl, core auth rules) remain in app_config or root.

## 7. Non-Negotiable Rules for All Agents

Never hardcode colors, logos, or tokens outside shared_core or Firestore config.
All new UI code must go through UiConfig / DesignTokens.
Every franchise must have a complete ui_config document.
Maintain backward compatibility during transition (delegation layers stay until Phase 4).

## This document is now the authoritative reference. Any LLM agent must read it before working on config, UI, or branding tasks.