# Firestore Service Split & Mobile Ordering Flow Remediation Plan
**Date**: May 30, 2026  
**Architect**: Senior Flutter/Firebase (Grok)  
**Status**: Option B Complete | P1 Migration Cleanup In Progress

## Executive Summary (Updated)
The Firestore service split has been successfully executed as part of Option B stabilization. The architecture is now clean, with a 3-tier structure fully in place and the mobile ordering flow stable on Samsung S25.

**Key Achievements (May 28–30, 2026)**:
- FranchiseProvider unification complete (local wrapper deleted, shared_core is single source of truth).
- ~41 direct src/ imports eliminated across 6 batches.
- Duplicated models cleaned (Address, Banner, Category, MenuItem, Order, FeedbackEntry, ScheduledOrder, etc. moved to shared_core).
- FirestoreServiceImpl hardened (all fallback logic removed).
- End-to-end ordering flow (Login → Franchise Init → Menu → Category → Customization → Cart → Checkout → Confirmation) is stable and device-tested.
- ScheduledOrdersScreen migrated and working.
- Git hygiene maintained with multiple clean commits/pushes on `fix/core-flow-stabilization-phase1`.

**Remaining Work**: Minor duplicated widgets, profile/loyalty polish, log spam reduction, and final model/widget consolidation before moving to P2 (White-Label).

## Current Architecture (Updated – May 30, 2026)

### 1. FirestoreService Landscape
- **Abstract (shared_core)**: Comprehensive contract with all customer + admin methods.
- **Tier 1: Lightweight Customer Impl** (`shared_core/src/core/services/firestore_service_impl.dart`): Full implementation for mobile flows (cart, orders, scheduled, favorites, loyalty, feedback, chat, menu, categories, banners, etc.). Franchise-scoped paths enforced. No fallbacks.
- **Tier 2: Admin Heavy** (`web-app`): Full admin methods (payouts, platform invoices, tax, detailed staff, error logs, etc.) built on top of the lightweight impl where possible.
- **Mobile**: All screens now use `shared.FirestoreService` via Provider. No local service files.

### 2. Mobile Ordering Flow State
- Fully functional and device-tested on Samsung S25.
- Cart, customization, checkout, confirmation all working with real-time updates.
- Franchise ID propagation reliable (no more "unknown"/"default" spam).
- Models (Order, ScheduledOrder, MenuItem, etc.) now come exclusively from shared_core.

### 3. Model Consolidation (Completed)
- All core models live in `shared_core`.
- Local mobile duplicates deleted or turned into thin extensions (User).
- FavoriteOrder, Loyalty, LoyaltyReward moved to shared_core.

## Recommended Next Steps (P1 Remaining)

**Phase 1.5: Final Duplicated Widgets Cleanup (est. 6-8 hrs)**
- Address remaining duplicated widgets (customization_modal, banner_carousel, category_card, promo_banner_card, feedback_submission_dialog, etc.).
- Move any truly shared UI logic to shared_core or keep mobile-specific in mobile_app.

**Phase 1.6: Polish & Debt Paydown (est. 8-10 hrs)**
- Profile screen + order history / loyalty foundations.
- Reduce remaining log spam and temporary debug prints.
- Full regression test on Samsung S25.
- Stub any non-core screens if needed.

**Once P1 complete → Move to P2 (White-Label & Scalability)**

## Open Questions / Notes
1. Any remaining duplicated widgets you want prioritized?
2. Preference on Loyalty/Favorites model refinements?
3. Ready to begin final widget cleanup batch?

**This plan is now a living reference.** Option B is closed. We are deep into P1 cleanup with strong momentum.