# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased] - 2026-08-12
### Changed
- Phase B customization modal on `feat/customization-modal-composition-root`:
  - **B3** runtime dual-write removed (cheeses, toppings, pizza sauces, dressings, add-ons, sauce counts) — UI/submit/validation read `CustomizationController`.
  - **B4 partial** init-only dual maps removed; `PizzaSauceSelection` class removed; `sauceSplitValidationError` controller-only; `SauceSelectorGroup` map-typed.
- Authority docs updated: `STATUS.md`, `HANDOFF.md`, `docs/slices/customization-modal-decompose-v1.md`, `docs/architecture/containment-progress-2026-08-11.md`.
- **Pending:** device smoke on branch before merge to `main`.

## [Unreleased] - 2026-07-20
### Added
- Full config unification (`design_tokens.dart`, `app_config.dart`, `branding_config.dart`, `feature_config.dart`, `ui_config.dart`) into `shared_core` as SSoT.
- New authoritative document: `docs/architecture/firestore-per-franchise-config.md` (schema, migration plan, security rules, providers).
- Dynamic per-franchise config architecture with Firestore overrides.
- Updated governance docs (`AGENT_SYSTEM.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `DASHBOARDS.md`, `MOBILE_DYNAMIC.md`, `DECISIONS.md`, `CONTRIBUTING.md`).

### Changed
- All agents now reference the new config architecture and unified shared_core.
- Enhanced agent prompts (`prompts/`) with strict scope control and documentation review requirements.
- Documentation alignment across the project.

### Removed
- Outdated P1 cleanup plan and mobile file roles document (archived).

## [0.1.0] - 2025-10-29
### Added
- **Monorepo Structure** – `web-app/` + `mobile_app/`
- **Firebase Integration** – Auth, Firestore, Hosting
- **CI/CD** – GitHub Actions (web deploy + APK build)
- **Decoupled Architecture** – No admin leaks in mobile
- **AGPL-3.0 License** – Full IP protection
- **Security** – Hierarchical Firestore paths, GitHub Secrets

### Fixed
- Removed admin methods (`staff`, `audit`, `export`) from mobile
- Fixed flat Firestore collections → `franchises/{id}/...`

### Security
- Deleted `serviceAccountKey.json`
- Secrets moved to GitHub Actions

## [0.0.1] - 2025-10-01
### Added
- Initial project setup
- Flutter web + mobile scaffold
- Firebase project linked
