# Contributing Guide

Thank you for contributing to the Doughboys Pizzeria Franchise Platform!

## Code of Conduct
Be respectful, professional, and constructive. We value clear communication, collaboration, and high code quality.

## Development Workflow

### 1. Branching Strategy
- Always work on a dedicated branch: `feature/<description>` or `fix/<description>`
- Example: `feature/hybrid-location-support`, `fix/mobile-dynamic-ui`
- Never push directly to `main`

### 2. Git Hygiene (Required)
After every major change run:
```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter build web --debug   # for web-app changes
flutter build apk --debug   # for mobile changes
3. Non-Negotiable Architecture Rules

All customer data must be scoped under franchises/{franchiseId}/...
shared_core is the single source of truth for models, providers, services, and configs
Use import 'package:shared_core/shared_core.dart' as shared;
FranchiseProvider is the central state manager for franchise context, branding, and hybrid single/multi-location logic
Dynamic theming, FeatureGate, and config-driven UI are mandatory
Human-readable names + inline "why" comments required
Config changes must follow /docs/architecture/firestore-per-franchise-config.md
Human approval required for payments, auth, security, Firestore schema, and major architecture changes

4. Multi-Agent Development

Orchestrator coordinates specialized agents (Mobile + Shared Core, Web Frontend, Backend, etc.)
Every agent follows the constitution in their prompt files (prompts/)
Human review on every PR
Maintain HANDOFF.md for context between agents

5. Testing Requirements

Run flutter analyze and all relevant tests
Test on emulator first
Final validation on physical devices (Samsung S25 for Android, iPhone 15 for iOS)
Verify hybrid single/multi-location flows and dynamic UI

6. Pull Request Process

Ensure flutter analyze passes with zero issues
Update relevant documentation (ARCHITECTURE.md, DASHBOARDS.md, MOBILE_DYNAMIC.md, ROADMAP.md, DECISIONS.md, etc.)
Request review from project maintainer
Merge only after approval and successful builds

7. Documentation

Keep ARCHITECTURE.md, DASHBOARDS.md, MOBILE_DYNAMIC.md, ROADMAP.md, and DECISIONS.md up to date
All major decisions should be recorded in DECISIONS.md

8. Questions / Help

Open a GitHub issue or use internal discussions
For agent-related work, refer to prompt files in prompts/

Last Updated: July 20, 2026