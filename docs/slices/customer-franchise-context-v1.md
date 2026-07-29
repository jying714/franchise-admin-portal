# Slice: Customer Franchise Context v1

**Status**: **Locked** (product approved July 29, 2026 — implementation open)  
**Branch**: TBD (`feat/customer-franchise-context-v1` when work starts)  
**Authority**: Decision **11** · STATUS · HANDOFF · this file  
**Depends on**: FranchiseProvider, QR/deep link foundations, mobile tokens on `main`  
**Pilot**: Real franchise + mock seeded franchise (both directory-listable)

---

## 1. Problem

Customer app can bind a franchise via QR/deep link foundations and holds `selectedFranchiseId`, but lacks a **complete multi-tenant product path**:

- No reliable **cold start** without a hard-coded default trap
- No first-class **switch restaurant** for signed-in users (QR-only is insufficient)
- No **directory** for signed-out / App Store open / second-tenant QA
- Unclear **cart policy** across franchise changes
- Signed-out **browse vs checkout** rules not productized

---

## 2. Locks (Decision 11)

| Topic | Lock |
|--------|------|
| Binary | Hybrid multi-tenant; session = one `franchiseId` |
| Branding | Follows active franchise after bind |
| Acquisition | QR/SMS/links **primary**; directory **required foundation** |
| Bind | One pipeline for link, QR, directory, recents, switcher |
| Signed-out | Menu + cart OK; **checkout requires auth** |
| Cart switch | Confirm → clear cart → switch |
| Geo | Out of v1 |
| Guest pay | Out of v1 |

---

## 3. Workstreams

| ID | Deliverable | Status |
|----|-------------|--------|
| **CF0** | Docs lock (this file + Decision 11) | **Done** |
| **CF1** | Cold-start rules: deep link > stored/recents > directory empty state | Open |
| **CF2** | Harden QR + App Links / Universal Links (cold + warm) | Open |
| **CF3** | Recents (local, max N) on successful bind | Open |
| **CF4** | Signed-in Change restaurant sheet: current · recents · my locations · directory · scan | Open |
| **CF5** | Cart non-empty switch: confirm + clear + switch | Open |
| **CF6** | Signed-out browse; auth gate at checkout | Open |
| **CF7** | Directory foundation: listed franchises; name/city search; same bind pipeline | Open |
| **CF8** | Mock franchise seeded + listed; real franchise list flag when ready | Open |
| **CF9** | Post-switch: branding stream, menu scope, navigate MainMenu root | Open |
| **CF10** | Acceptance smoke + STATUS close | Open |

---

## 4. Directory data (intent)

- Only franchises with a **list/public** flag (e.g. `listedInDirectory == true`) and safe public fields (name, city, logo, id).
- Do not expose admin-only or PII in directory queries.
- Mock + real both appear when flagged.

---

## 5. Acceptance (implementation)

- [ ] Cold start without link shows directory or choose state (not wrong silent tenant only)
- [ ] QR/SMS link binds correct franchise and branding
- [ ] Directory search + open uses same bind as link
- [ ] Recents update after bind
- [ ] Switcher works signed-in; cart clear confirmed when needed
- [ ] Signed-out can browse and cart; checkout forces sign-in
- [ ] Mock and real franchises switchable in QA
- [ ] No cross-franchise cart merge

---

## 6. Out of scope

- Map/geo radius  
- Guest checkout without account  
- Multi-location-within-one-franchise store picker (ops Decision 1 refinement)  
- Stripe PaymentIntent (see `stripe-checkout-v1.md`)  

---

## 7. Bottom line

Ship **link-primary** pilots with a **real directory foundation** and **first-class franchise switch**, session-scoped to one `franchiseId`, with safe cart clearing and signed-out browse until pay.
