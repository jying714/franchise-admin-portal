# Customer Website (`customer_web`) — Development Plan

**Phases 0–12 → polished MVP (hard-release gate)**  
**Phases 13–18 → full mobile_app parity (post-MVP)**  

**Status (2026-08-02):** Phases **0–11 effectively COMPLETE** on `feat/customer-website-v1` (vertical path + Phase 4b pricing + shell/account chrome). Phase **12** polish + **merge** remain for hard-release close. Phases **13–18** are the mobile parity expansion after MVP is on `main`.

**Authority:** Decision **11** · **12** · **14** · `docs/slices/customer-website-v1.md` · `STATUS.md` · `HANDOFF.md` · this plan  
**App path:** `customer_web/` (top-level Flutter web target)  
**Live storefront:** https://franchise-storefront.web.app · URL pattern `/f/{franchiseId}`  
**Depends on:** `packages/shared_core`, Stripe Connect (mobile patterns), `franchises/{id}/config/store_ops`  
**Branch:** `feat/customer-website-v1`

---

## Guiding rules (non-negotiable)

1. **One app, one session franchise** — never multi-franchise cart merge.  
2. **No second menu / modifier tree** — reuse `menuProfile` + shared models exactly as mobile/POS.  
3. **Signed-out browse only**; add-to-cart / cart / checkout require Firebase Auth (guest cart stays deferred until an explicit Decision).  
4. **Order `source: 'web'`** on every new order; POS open board must see it.  
5. **`store_ops`** is the single source of truth for tax + open/closed hours.  
6. **Fail closed** on card pay when `paymentsEnabled` is false.  
7. **Admin isolation** — zero customer routes inside `web-app`.  
8. **Hosting** is target `storefront` (site `franchise-storefront`), not the Admin shell.  
9. Schema / payments / Hosting changes require **human review**.  
10. Prefer surgical reuse of mobile patterns; adapt only for web layout and Stripe **web**.  
11. **Pricing:** option `upcharge` / `upchargeBySize` when set; else selected `SizeData.toppingPrice` × paid add-ons + `SizeData.basePrice` (Doughboys salad/pizza add-on pattern).

---

## Phase summary

| Phase | Focus | Target outcome | Status |
|------|--------|----------------|--------|
| 0 | Scaffold + Firebase + shared_core | Chrome runs with providers | **COMPLETE** |
| 1 | Router + franchise bind | `/f/{id}` binds + branding | **COMPLETE** |
| 2 | Live branding shell | Franchise-driven ThemeData | **COMPLETE** |
| 3 | Signed-out menu browse | Categories + items | **COMPLETE** |
| 4 | Item customization + **4b pricing** | menuProfile UX + correct unit price | **COMPLETE** |
| 5 | Auth | Google + email; gate cart/checkout | **COMPLETE** |
| 6 | Cart | Add/remove/qty steppers; customizations visible | **COMPLETE** |
| 7 | Checkout + Stripe web | store_ops, CardField, Connect PI | **COMPLETE** |
| 8 | Order + confirmation | `source: 'web'`; POS visibility | **COMPLETE** |
| 9 | Account / history | My orders list | **COMPLETE** |
| 10 | HQ storefront URL + QR | Owner HQ card copy/open/QR | **COMPLETE** |
| 11 | Hosting + deploy | Target `storefront` live | **COMPLETE** |
| 12 | Polish + smoke + close | Acceptance green; merge | **IN PROGRESS** |
| 13 | Directory / change restaurant | Mobile-parity franchise entry | **Open** (parity) |
| 14 | Delivery + address book | If mobile offers delivery | **Open** (parity) |
| 15 | Promos + tips + fees | Mobile checkout parity | **Open** (parity) |
| 16 | Favorites + profile | Mobile account parity | **Open** (parity) |
| 17 | Loyalty + rewards | Mobile loyalty parity | **Open** (parity) |
| 18 | Support chat + residual UX | Mobile chat + polish | **Open** (parity) |

### Milestone tags

| Tag | Phases | Status |
|-----|--------|--------|
| **cw-m1** | 0–2 shell + bind | **Reached** |
| **cw-m2** | 3–4 browse + customize | **Reached** |
| **cw-m3** | 5–6 auth + cart | **Reached** |
| **cw-m4** | 7–8 checkout + order | **Reached** |
| **cw-m5** | 10–11 HQ + Hosting | **Reached** |
| **cw-m6** | 9 + 12 polished MVP | **Near** (12 open) |
| **cw-m7** | 13–18 full mobile parity | **Not started** |

---

## Completed work log (2026-08-02)

### Phases 0–2
- `customer_web` Flutter web app; `shared_core` path dep; Firebase; MultiProvider (`FranchiseProvider`, `FirestoreService`, `StreamProvider<User?>`).
- GoRouter: `/`, `/f/:franchiseId`; `_FranchiseGate` + `FranchiseBind.bindById`.
- Path cold-load: `web/index.html` path→hash bootstrap; landing post-frame bind; GoRouter redirect.
- `BrandingShell` + `themeFromFranchise` from franchise primary/secondary/logo/name.

### Phases 3–4
- `MenuBrowseScreen` category grid; `MenuItemDetailScreen` sizes + `effectiveModifierGroups`.
- **Phase 4b:** unit price = `SizeData.basePrice` + selected option deltas; deltas from `upcharge`/`upchargeBySize` **or** `SizeData.toppingPrice`; `maxFree` respected; `List<Customization>` written on `addToCart`; min-group validation.

### Phases 5–6
- Sign-in (Google + email); auth gate on add-to-cart / cart / checkout.
- Cart: line price, customization summary, qty +/−, remove; franchise-scoped via `FirestoreService`.

### Phases 7–8
- Checkout: `store_ops` tax/hours, CardField + `createOrderPaymentIntent`, fail-closed on payments, `source: 'web'`.
- Order confirmation screen; POS open board visibility verified in smoke.

### Phases 9–11
- **My orders** (`OrderHistoryScreen`) from account menu.
- HQ `StorefrontLinkCard`: copy, open, QR (`qr_flutter`).
- Hosting site `franchise-storefront`; `firebase.json` + `.firebaserc` targets; deploy workflow; Auth authorized domains; `--pwa-strategy=none` recommended.

---

## Phase 12 — Polish, residual, acceptance, close (current)

### Still required for “polished MVP” close

- [ ] Responsive breakpoints (phone / tablet / desktop) for menu grid + checkout form.  
- [ ] Loading / error / empty states audit (no silent failures).  
- [ ] Honest closed-store + payments-not-set-up messaging consistency.  
- [ ] Deep-link resilience (reload on bound path restores franchise).  
- [ ] Stripe test matrix: success, declined, `paymentsEnabled=false`.  
- [ ] POS dual-path smoke: mobile + web orders both actionable.  
- [ ] Optional: order detail read-only from history (expand list row).  
- [ ] CI: `deploy-storefront.yml` secret `STRIPE_PK_TEST` verified on Actions.  
- [ ] Update slice → **COMPLETE**; STATUS/HANDOFF/ROADMAP merge note.  
- [ ] **Human merge** `feat/customer-website-v1` → `main`; delete feature branch after green smoke.

### MVP acceptance (slice)

- [x] Chrome + Firebase + shared_core  
- [x] `/f/{franchiseId}` binds + branding + menu  
- [x] Signed-out browse; auth on cart/checkout  
- [x] Checkout `source: 'web'`; POS sees order  
- [x] store_ops hours/tax gate  
- [x] HQ URL + QR  
- [x] Hosting separate from Admin  
- [x] Phase 4b pricing + cart fidelity  
- [x] Shell cart + sign-in/out + order history  
- [ ] Phase 12 polish checklist + merge  

**Exit criteria for hard-release (website):** Phase 12 checklist green + merge to `main`.

---

## Phases 13–18 — Full mobile_app parity (post-MVP)

> Scope expansion beyond original v1 non-goals. Execute **after** Phase 12 merge. Each phase reuses mobile `shared_core` APIs; web UI only.

### Phase 13 — Directory / change restaurant

**Goal:** Mobile-parity entry when no franchise or user wants to switch.  
**Work:** Franchise directory or search; “Change restaurant” in shell; cart-clear confirm on switch (Decision 11). Optional QR scan helper for desktop (paste URL).  
**Exit:** User can leave bound franchise and bind another without hard-refresh hacks.

### Phase 14 — Delivery + addresses

**Goal:** If mobile offers delivery for the franchise, web matches.  
**Work:** Delivery type picker; address book via `FirestoreService` address APIs; delivery fee from same rules as mobile; outside-delivery-area honesty. Pickup remains default.  
**Exit:** Delivery order places with address + fee; POS shows delivery type.

### Phase 15 — Promos, tips, fees

**Goal:** Checkout totals parity with mobile.  
**Work:** Promo code apply (existing promo collections); tip selector if mobile has it; any service fees already modeled — no invented fee fields.  
**Exit:** Same cart + promo + tip → same total formula as mobile for a given franchise.

### Phase 16 — Profile + favorites

**Goal:** Account beyond order list.  
**Work:** Profile display/edit (name/phone as mobile allows); favorite menu items; favorite orders if mobile exposes them.  
**Exit:** Favorites toggle on item; favorites list reachable from account menu.

### Phase 17 — Loyalty + rewards

**Goal:** Mobile loyalty parity when franchise has loyalty enabled.  
**Work:** Points balance read; redeem flows already in `FirestoreService.claimReward` / loyalty maps; feature-toggle gated.  
**Exit:** Loyalty UI appears only when enabled; redeem updates balance.

### Phase 18 — Support chat + residual mobile UX

**Goal:** Close remaining customer mobile features appropriate for web.  
**Work:** Support chat (`createOrGetUserChat` / messages) if product wants web chat; scheduled orders only if still product-active; language/l10n if mobile ships multi-locale; accessibility + SEO meta per franchise.  
**Exit:** Feature parity matrix vs `mobile_app` is checked item-by-item and closed or explicitly deferred with Decision.

---

## Mobile parity matrix (tracking)

| Mobile capability | Web status |
|-------------------|------------|
| Franchise bind (QR / path) | **Done** |
| Live branding | **Done** |
| Menu browse | **Done** |
| Customization + size/topping pricing | **Done** (4b) |
| Auth (Google + email) | **Done** |
| Cart + qty | **Done** |
| Checkout + Connect | **Done** |
| store_ops hours/tax | **Done** |
| Order history | **Done** (list) |
| HQ share URL/QR | **Done** |
| Order detail from history | Phase 12 optional |
| Change restaurant / directory | Phase 13 |
| Delivery + addresses | Phase 14 |
| Promos / tips | Phase 15 |
| Profile / favorites | Phase 16 |
| Loyalty | Phase 17 |
| Support chat | Phase 18 |
| Guest cart | Deferred (Decision required) |
| Push / post-order survey | N/A or Phase 18 residual |
| Geo directory radius | Deferred unless product prioritizes |

---

## Explicitly deferred (unless Decision reopens)

- Per-franchise Hosting projects  
- Guest cart / guest checkout (without a new Decision)  
- Second modifier or menu schema  
- Stripe Terminal / card-present  
- Live delivery tracking map  

---

## Ops cheat sheet

```powershell
# Local
cd C:\projects\franchise-admin-portal\customer_web
flutter run -d chrome --dart-define=STRIPE_PK=pk_test_...
# Open: http://localhost:PORT/#/f/doughboyspizzeria

# Deploy
flutter build web --release --pwa-strategy=none --dart-define=STRIPE_PK=pk_test_...
cd ..
firebase deploy --only hosting:storefront
```

**Auth:** Firebase authorized domains must include `franchise-storefront.web.app`.  
**Pricing example (Antipasta):** Small base 8.45 + N×0.85; Large 9.99 + N×1.15.

---

## Recommended next actions

1. Finish **Phase 12** polish checklist + dual POS smoke.  
2. Human merge `feat/customer-website-v1` → `main`.  
3. Only then schedule **Phases 13–18** by product priority (directory → delivery → promos → favorites → loyalty → chat).

This plan stays sequential: **MVP close (12) before parity expansion (13–18)** so the hard-release gate is not blocked by loyalty/chat scope.
