# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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

---

## [0.0.1] - 2025-10-01
### Added
- Initial project setup
- Flutter web + mobile scaffold
- Firebase project linked