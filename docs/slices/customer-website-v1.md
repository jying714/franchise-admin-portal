# Slice: Customer Website v1 (`customer_web`)

**Status**: **Scaffold / structure started** (2026-08-01) — product implementation **not started**  
**App path**: `customer_web/` (top-level Flutter **web** target; sibling to `mobile_app`, `pos_app`, `web-app`)  
**Authority**: Decision **11** (franchise bind) · Decision **12** (Connect) · Decision **14** (hard release gate includes customer website) · STATUS · HANDOFF · this file  
**Depends on**: shared_core menu/modifiers/branding; franchise-scoped orders; Stripe Connect checkout patterns from mobile  

---

## 1. Problem

Hard product release requires a **customer-facing ordering website** in addition to mobile + thin POS + HQ/Admin. Guests need a shareable https link (QR / SMS / onboarding) that opens a franchise-branded menu, checkout, and pay flow without installing the app.

---

## 2. Product locks (intent)

| Lock | Choice |
|------|--------|
| App shape | **One** Flutter web app (`customer_web`), not one static site per franchise |
| Tenancy | Session = one `franchiseId` (Decision 11 parallel) |
| Primary entry | Path bind e.g. `/f/{slug}` → franchise (exact host TBD: e.g. `order.franchisehq.io`) |
| Browse | Signed-out **menu browse** allowed |
| Cart / checkout | **Auth required** (guest cart deferred) |
| Pay | Franchise **Stripe Connect** (Decision 12); order `source: 'web'` |
| Hours | `franchises/{id}/config/store_ops` — same open/closed rules as mobile |
| Menu / branding | Read existing franchise config — **no second menu tree** |
| Onboarding | On successful publish gates, HQ writes stable `storefrontUrl` (+ QR); not a new Hosting site per franchise |
| Admin isolation | **Not** routes inside `web-app` admin shell |

---

## 3. Repo structure

```text
customer_web/           # Flutter web (`flutter create --platforms=web`)
  lib/
    main.dart           # from flutter create
    app.dart
    core/               # router, franchise_bind, constants
    features/           # landing, home, menu, cart, checkout, auth, orders, account
    widgets/            # branding_shell, grids, cards, customization
  web/
packages/shared_core/   # domain (shared)
web-app/                # HQ writes storefrontUrl on publish (later)
docs/slices/customer-website-v1.md
scripts/scaffold_customer_web.ps1   # empty placeholder tree helper
```

Scaffold helper (placeholders only, no logic):

```powershell
cd C:\projects\franchise-admin-portal
powershell -ExecutionPolicy Bypass -File .\scripts\scaffold_customer_web.ps1
```

---

## 4. Acceptance (MVP — not yet done)

- [ ] `customer_web` runs on Chrome with Firebase + `shared_core`
- [ ] `/f/{slug}` (or locked equivalent) binds franchise and loads branding + menu
- [ ] Signed-out browse; auth gate on cart/checkout
- [ ] Checkout creates order with `source: 'web'`; POS open board sees it
- [ ] In-hours → kitchen path; outside hours / closed day blocks place
- [ ] HQ onboarding/publish exposes `storefrontUrl` + QR
- [ ] Hosting target for customer site (separate from Admin `franchisehq.io` shell)

---

## 5. Out of scope for v1

- Per-franchise Hosting projects  
- Guest cart  
- Second modifier/menu schema  
- Full mobile feature parity (loyalty, chat, etc.) on day one  

---

## 6. Bottom line

**Next hard-release epic.** Structure and slice are in place; wire `shared_core`, router bind, menu, auth, checkout next. Keep Admin (`web-app`) and storefront (`customer_web`) separate deploys/shells.
