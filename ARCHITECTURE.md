# Architecture Documentation
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: July 19, 2026  
**Status**: Preparing for P3 – Advanced Features & Production Readiness

## 1. High-Level Overview
This is a **Flutter monorepo** consisting of:
- `shared_core` — Single source of truth for models, providers, services, configs
- `web-app` — Admin dashboards (Flutter Web)
- `mobile_app` — Customer-facing ordering app (Android + iOS, one published binary)

**Business Goal**: Scalable multi-tenant white-label platform for restaurants/franchises with rapid, AI-accelerated onboarding and low-cost operation.

## 2. Core Principles (Non-Negotiable)
- **Franchise Scoping**: All customer data under `franchises/{franchiseId}/...`
- **Hybrid Single/Multi-Location**: Automatic UI simplification when `location_ids.length === 1`
- **Dynamic Everything**: Branding, theming, UI components, features driven by configs + FeatureGate
- **Shared Core First**: All business logic lives in `shared_core`
- **Small, Reviewable Changes**: Human review on every PR (especially payments, auth, security)
- **Human-Readable Code**: Clear names + inline "why" comments

## 3. Dashboard Roles & Purposes
- **Platform Owner**: Platform-level analytics, payments, subscriptions, error management, developer tools
- **HQ Owner / Franchise Owner**: Franchise management, design & branding, menu, orders, staff, analytics for their locations
- **Admin / Staff**: Location-specific operations (menu updates, orders, kitchen)
- **Developer**: Assisted onboarding, error debugging, simulation of other roles

**Design & Branding Page** (HQ Owner dashboard):
- Live preview simulator (mobile + web views)
- Edit design tokens, colors, fonts, logos
- Warning for non-developer users
- Franchise-scoped Firestore storage

## 4. Data Model & Firestore Structure
- Root: `franchises/{franchiseId}`
- Subcollections for menu, orders, categories, configs, etc.
- Location support via `location_ids` array and `franchise_locations`
- Configs stored under `franchises/{franchiseId}/config/...` (branding, ui, features)

## 5. State Management & Providers
- Riverpod + Provider pattern
- `FranchiseProvider`: Central source for current franchise, branding, location
- `AdminUserProvider`: Role and permissions
- FeatureGate for conditional features

## 6. Mobile App Architecture
- One published app serving all franchises
- Dynamic UI based on `restaurantType`, configs, and FeatureGate
- Transition from pizzeria-hardcoded to fully generic
- Offline support (menu cache + order queue)
- Deep linking / QR for franchise claiming

## 7. Agent Workflow & Guardrails (for multi-agent development)
- Orchestrator coordinates specialized agents
- Human review on all changes (especially money/security)
- Small PRs with clear acceptance criteria
- Always respect shared_core, hybrid logic, dynamic configs

## 8. Tech Stack
- Flutter (Web + Mobile)
- Firebase (Firestore, Auth, Functions, Hosting)
- Riverpod, Provider, FeatureGate
- Stripe (future)
- Docker + local LLMs on MINISFORUM AI X1 Pro-470 (64GB)

## 9. Future-Proofing
- POS hardware abstractions (printers, terminals)
- Plugin/extension system
- White-label scalability
- Comprehensive testing & CI/CD

---