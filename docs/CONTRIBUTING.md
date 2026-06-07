# Contributing Guide

Thank you for considering contributing to the Doughboys Pizzeria Franchise Platform!

## Code of Conduct
Be respectful, professional, and constructive. We value clear communication and collaborative problem-solving.

## Development Workflow

### 1. Branching Strategy
- Always work on a dedicated branch: `fix/<description>` or `feature/<description>`
- Example: `fix/p2.5-auth-handoff`, `feature/p3-payment-gateway`
- Never push directly to `main`

### 2. Git Hygiene (Required)
After every major change:
```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter build web --debug   # for web-app changes

Commit message format:
text<type>: <short description>

- Detailed changes
- Related ticket or issue (if any)

3. Non-Negotiable Rules

All customer data must be scoped under franchises/{franchiseId}/...
Use import 'package:shared_core/shared_core.dart' as shared;
FranchiseProvider is the single source of truth for franchise context
UiConfig for all Flutter-specific styling/types
DesignTokens for pure scalars only
No critical stubbing on core paths

4. Testing Requirements

Test on Emulator first
Final validation on physical Samsung S25 (for mobile)
Verify both web (flutter run -d chrome) and mobile flows

5. Pull Request Process

Ensure flutter analyze passes with zero issues
Update relevant READMEs or docs if architecture changes
Request review from project maintainer
Merge only after approval and successful build

6. Architecture Guidelines

shared_core/ is the single source of truth
All providers and services must respect franchise scoping
Prefer surgical, one-file-at-a-time changes during cleanup sprints

7. Contact / Questions
Reach out via GitHub issues or internal discussions.

Last Updated: June 06, 2026