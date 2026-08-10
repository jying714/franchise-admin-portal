# Slice: Bounded-context repositories v1

**Status:** A1 COMPLETE on `feat/bounded-context-repos-v1` (menu + category façade; ingredients still deferred)  
**Authority for:** Phase A of the god-object containment plan  
**Branch:** `feat/bounded-context-repos-v1` (merge to `main` when ready)  
**Related:** `docs/slices/customization-modal-decompose-v1.md`, `STATUS.md`, `HANDOFF.md`, `orchestrator/SCOPE_CARD.md`

---

## 1. Problem (measured on main)

| Artifact | Size | Reality |
|----------|------|---------|
| `packages/shared_core/lib/src/core/services/firestore_service.dart` | 27 450 bytes | Single abstract class, **267** abstract methods spanning menu, orders/cart, inventory, promos, banners, error logs, audit, payouts, invoices, platform billing, support, tax, onboarding, invitations, analytics, staff, feedback, feature toggles, schema helpers, etc. |
| `packages/shared_core/lib/src/core/services/firestore_service_impl.dart` | 124 175 bytes | Documented as **lightweight** customer/mobile + common logic. Pure-admin methods throw `UnimplementedError` (132 occurrences). |
| `web-app/lib/core/services/admin_firestore_service.dart` | 87 925 bytes | Extends `shared.FirestoreServiceImpl` and owns the heavy admin paths. |

**Already-present bounded escapes (do not re-invent):**

- `packages/shared_core/lib/src/core/services/pos_firestore_service.dart` — staff / drivers / waitresses / print_jobs / pos_settings / table_layout. Comment: “Does not replace FirestoreService; station code should prefer this for POS paths.”
- `packages/shared_core/lib/src/core/services/labor_firestore_service.dart` — shifts + time_entries.
- `packages/shared_core/lib/src/core/services/inventory_ledger.dart`
- `packages/shared_core/lib/src/core/services/promo_pricing.dart` + `promo_service.dart`
- Other focused services (franchise_onboarding, franchise_subscription, etc.)

The concentration still forces every menu or order change through the same abstract + façade surface, blocks safe parallel work, and is the root cause of many SCOPE_CARD / hard-ban hits.

---

## 2. Goal (zero behavior change)

Extract repository interfaces + concrete Firestore implementations **behind** the existing `FirestoreService` / `FirestoreServiceImpl` façade.

- Every public method signature currently used by call sites remains.
- Old call sites continue to compile and run unchanged until they are migrated one surface at a time.
- New code and agent tasks target the focused repository.
- After a context is fully migrated and smoke-tested, the forwarded methods may be marked `@Deprecated` and later removed.

**No schema changes. No Firestore path changes. No new fields on models or providers protected by SCOPE_CARD.**

---

## 3. Target layout

```text
packages/shared_core/lib/src/core/repositories/
├── menu_repository.dart                 # abstract
├── menu_firestore_repository.dart       # concrete
├── order_repository.dart
├── order_firestore_repository.dart
├── config_repository.dart
├── config_firestore_repository.dart
├── inventory_repository.dart
├── inventory_firestore_repository.dart
├── labor_repository.dart                # formalize existing LaborFirestoreService surface
└── labor_firestore_repository.dart
```

Optional later (only when needed): `platform_billing_repository.dart`, `audit_repository.dart`, etc.

`PosFirestoreService` and `LaborFirestoreService` already exist as concrete classes. Formalize them behind (or as) the repository interfaces; do not duplicate their logic.

---

## 4. Method ownership (initial inventory from abstract)

### MenuRepository (first extract — Phase A1)

Owned concerns (non-exhaustive, taken from live abstract signatures):

```text
addMenuItem / updateMenuItem / deleteMenuItem
getMenuItems / getMenuItemsOnce / getMenuItemsByIds / fetchMenuItemsOnce
getMenuItemsByCategory / getMenuItemById
saveMenuItems / reorderMenuItems
getCustomizationGroups / getPreselectedCustomizations
fetchCategories / saveCategory / addCategory / updateCategory / deleteCategory
getCategories (stream)
getCategorySchema / getAllCategorySchemaIds
Ingredient metadata + type CRUD / batch / template import
getAllIngredientMetadata / getIngredientMetadataByIds / getIngredientMetadataMap
saveIngredientMetadata / saveIngredientMetadataBatch / delete… / replace…
getAllergensForIngredientIds / getAllergensForCustomizations
getIngredientTypes / getIngredientMetadata (streams)
Favorites menu-item streams/add/remove (customer)
```

### OrderRepository

```text
addOrder / updateOrderStatus / refundOrder
getAllOrdersStream / getOrders / getOrdersForUser
getCart / updateCart / addToCart / removeFromCart / clearCart / getCartItemCountStream
Scheduled order CRUD
Favorite orders
hasOrderFeedback / submitOrderFeedback
getTotalOrdersTodayCount / getTotalOrdersForPeriod
```

Cart remains modeled via `Order` with status `'cart'` (existing comment in abstract). No new Cart model in this slice.

### ConfigRepository

```text
Franchise feature toggles (get / set / stream / updateFeatureToggle)
Franchise profile / business hours
getFranchiseInfo / franchise list helpers that are config-shaped
storefront / store_ops / pos_settings / table_layout / ui_config access patterns
```

Branding live values continue to be applied through `FranchiseProvider.setBrandingFromFranchiseDoc` / `applyBrandingFromInfo`. ConfigRepository supplies the raw maps; it does not replace `FranchiseProvider`.

### InventoryRepository / LaborRepository

Formalize the surfaces already implemented in `inventory_ledger.dart` and `LaborFirestoreService`. Do not re-implement; wrap or promote.

---

## 5. Façade rules (non-negotiable)

1. `FirestoreService` (abstract) keeps every existing method signature for at least one release after the corresponding repository lands.
2. `FirestoreServiceImpl` (lightweight) and `AdminFirestoreService` become thin forwards for extracted methods.
3. DI continues via existing MultiProvider / service-locator patterns. No new global registry.
4. Call-site migration is per-surface and per-method group. Prefer read paths first, write paths second.
5. Soft-release order path (mobile / customer_web / POS) must remain green after every PR.

---

## 6. Phased execution

| Phase | Work | Success gate |
|-------|------|--------------|
| **A0** | Stubs + this slice | Docs |
| **A1** | MenuRepository + MenuFirestoreRepository + façade (menu items + categories) | **DONE on branch** |
| **A2** | ConfigRepository + façade | Branding / toggles / storefront |
| **A3** | OrderRepository + façade | Order path smoke |
| **A4** | InventoryRepository + LaborRepository formalization | 86 + clock |
| **A5** | Remaining contexts as needed | Per-context smoke |

---

## 7. Agent / human workflow constraints

- One bounded context (or one natural method group) per PR / agent task.
- Quote exact first 8–12 lines of the real source being moved.
- No new fields, getters, or methods on `MenuItem`, `FranchiseProvider`, `DesignTokens`, `BrandingConfig`, `FeatureConfig`.
- No invented Firestore paths.

---

## 8. Explicit non-goals

- Big-bang deletion of `FirestoreService`.
- New Cart model (keep Order-as-cart).
- Schema or collection path changes.
- Moving pure domain pricing (see `customization-modal-decompose-v1`).
- Changing `PosFirestoreService` / `LaborFirestoreService` call sites until formalized.
- Any user-visible behavior change.

---

## 9. Smoke checklist (per context cut-over)

**Menu (A1)**  
- HQ: list, search, open editor, save, delete, reorder.  
- Mobile: category → items → open customization.  
- customer_web: menu load + Modern template.  

**Config (A2)**  
- HQ Design & Branding live preview.  
- Feature toggle change reflected.  
- Storefront template switch.  

**Order (A3)**  
- Mobile / customer_web: add to cart → checkout → Stripe or cash.  
- POS: open board, status transitions, delivery close-out path.  

**Inventory / Labor (A4)**  
- 86 / restock.  
- Clock-in / clock-out / schedule print.  

---

## 10. Locks

- Human remains the merge gate.
- Soft parallel / manager burn-in order path stays green.
- Existing specialized services are the pattern to expand, not replace.
- `FranchiseProvider` remains the runtime franchise + branding context holder.

**Last updated:** 2026-08-10  
**Done on branch:** `MenuRepository` + `MenuFirestoreRepository`; menu item CRUD + `getMenuItemsByCategory` + category fetch/stream/add/update/delete façade on `FirestoreServiceImpl`; barrel exports. Admin `deleteMenuItem` uses shared repo; Admin `addCategory` left as-is (non-equivalent merge/sortOrder/id generation).

**Next:** A1.4 ingredients optional, or A2 ConfigRepository, or merge after burn-in confidence. Primary product focus remains manager burn-in.
