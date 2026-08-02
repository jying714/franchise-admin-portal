# Slice: Customer Website v1 (`customer_web`)

**Status**: **Vertical slice PASS** (2026-08-02) on `feat/customer-website-v1` — Hosting live; HQ copy/open/QR  
**App path**: `customer_web/` (top-level Flutter **web** target; sibling to `mobile_app`, `pos_app`, `web-app`)  
**Authority**: Decision **11** (franchise bind) · Decision **12** (Connect) · Decision **14** (hard release gate) · STATUS · HANDOFF · this file  
**Depends on**: shared_core menu/modifiers/branding; franchise-scoped orders; Stripe Connect checkout patterns from mobile  

**Live storefront:** https://franchise-storefront.web.app  
**URL pattern:** `https://franchise-storefront.web.app/f/{franchiseId}`

---

## 1. Problem

Hard product release requires a **customer-facing ordering website** in addition to mobile + thin POS + HQ/Admin. Guests need a shareable https link (QR / SMS / onboarding) that opens a franchise-branded menu, checkout, and pay flow without installing the app.

---

## 2. Product locks

| Lock | Choice |
|------|--------|
| App shape | **One** Flutter web app (`customer_web`), not one static site per franchise |
| Tenancy | Session = one `franchiseId` (Decision 11 parallel) |
| Primary entry | `/f/{franchiseId}` on shared Hosting site |
| Hosting | Target **`storefront`** → site id `franchise-storefront`; Admin stays target **`admin`** |
| Browse | Signed-out **menu browse** allowed |
| Cart / checkout | **Auth required** (Google + email; guest cart deferred) |
| Pay | Franchise **Stripe Connect** (Decision 12); order `source: 'web'` |
| Hours / tax | `franchises/{id}/config/store_ops` — same rules as mobile |
| Menu / branding | Read existing franchise config — **no second menu tree** |
| HQ publish | Owner HQ **StorefrontLinkCard**: copy, open, QR (no per-franchise Hosting project) |
| Admin isolation | **Not** routes inside `web-app` admin shell |
| PWA | Prefer `flutter build web --pwa-strategy=none` for storefront |

---

## 3. Repo structure (implemented)

```text
customer_web/
  lib/
    main.dart              # Firebase, providers, Stripe PK dart-define
    app.dart               # MaterialApp.router + live theme
    core/                  # router, franchise_bind, constants, app_local_storage
    features/
      menu/                # browse + item detail
      auth/                # Google + email
      cart/
      checkout/            # store_ops + CardField + createOrderPaymentIntent
      orders/              # confirmation
    widgets/               # branding_shell, menu_item_card
  web/index.html           # Stripe.js + path→hash bootstrap for /f/{id}
web-app/.../owner_hq_dashboard_screen.dart   # StorefrontLinkCard
firebase.json              # hosting targets admin + storefront
.firebaserc                # target → site mapping
.github/workflows/deploy-storefront.yml
```

---

## 4. Acceptance (MVP)

- [x] `customer_web` runs on Chrome with Firebase + `shared_core`
- [x] `/f/{franchiseId}` binds franchise and loads branding + menu (desktop + mobile QR)
- [x] Signed-out browse; auth gate on cart/checkout
- [x] Checkout creates order with `source: 'web'`; POS open board sees it
- [x] In-hours path; outside hours / closed day blocks place
- [x] HQ exposes storefront URL + QR (dashboard card)
- [x] Hosting target for customer site (separate from Admin shell)

### Residual (post vertical slice)

- [ ] Phase 4b: modifier selections → cart `customizations` + upcharge in line price (size may still be specialInstructions)
- [ ] Optional custom domain map (CNAME → same Hosting site; hostname→franchiseId)
- [ ] Merge to `main` + Hosting CI secret `STRIPE_PK_TEST` verified on Actions
- [ ] Docs / hard-release checklist sign-off

---

## 5. Out of scope for v1

- Per-franchise Hosting projects  
- Guest cart  
- Second modifier/menu schema  
- Full mobile feature parity (loyalty, chat, etc.) on day one  

---

## 6. Ops notes

```powershell
# Local
cd customer_web
flutter build web --release --pwa-strategy=none --dart-define=STRIPE_PK=pk_test_...
cd ..
firebase deploy --only hosting:storefront
```

Firebase Auth → Authorized domains must include `franchise-storefront.web.app`.

---

## 7. Bottom line

**Vertical slice is live.** One storefront Hosting deployment, franchise path bind, Connect pay, HQ QR. Merge when human gates; residual is cart modifier fidelity and optional custom domains—not a second app.
