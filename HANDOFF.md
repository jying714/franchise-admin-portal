# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 30, 2026 (~21:10 CDT — pos_app scaffold PASS; plan Phases 0–14 locked)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/pos-app-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/plans/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5 + wings/calzone, mobile design tokens, developer dashboard, customer franchise context (11), Stripe checkout (12), mobile+web residual polish.

**Active branch `feat/pos-app-v1`:**

| Item | State |
|------|--------|
| Decision 14 product lock | Done |
| `pos_app` Flutter create + user feature tree | **PASS** |
| Development plan Phases 0–14 | **Documented** → `docs/plans/pos-app-v1-development-plan.md` |
| Phase 1 shared_core foundation | **Next** |
| Phase 2 PIN shell | After Phase 1 |

**Superseded:** `kitchen-ops-v1` pure kitchen binary — do not implement.

**Hard release gate:** Thin POS + customer website + polished mobile + web.

---

## 2. POS development order (do not invent a different sequence)

Full plan: **`docs/plans/pos-app-v1-development-plan.md`**.

Summary:

0. Scaffold (**done**)  
1. shared_core: order source/states, staff PIN/permissions, drivers/waitresses, POS settings, table layout, print job, rules  
2. PIN session + franchise lock + permissions  
3. Home + open-order board  
4. Carry-out order entry + modifiers  
5. Payments (cash + card-present + drawer + splits + discount + manager void)  
6. Dine-in table map (web editor + POS consume)  
7. Delivery + required driver assign  
8. Staff/driver/waitress ops UI  
9. Large-order hold + 86 + allergens  
10. Print pipeline  
11. Incoming online orders auto-print + shared list  
12. Settings panel  
13. Offline cash-only + honesty  
14. Pilot QA → polished MVP

**Next single step:** Phase 1.1–1.3 in shared_core (order `source`, station statuses, staff PIN/permissions) + rules.

---

## 3. Locks (do not regress)

- Station = **`pos_app` only** — not a kitchen-only app  
- shared_core owns models; POS owns tablet UX + hardware adapters  
- No second menu modifier schema  
- No silent default tenant; franchise must be bound  
- Manager-only void/refund/86/approve/settings + forced re-PIN  
- Order `source` on every order  
- Offline = cash only  

---

## 4. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (Decision **14**)  
- `docs/slices/pos-app-v1.md`  
- **`docs/plans/pos-app-v1-development-plan.md`** ← full phase plan  
- `docs/slices/stripe-checkout-v1.md` (COMPLETE)  
- `docs/slices/customer-franchise-context-v1.md` (COMPLETE)  
- `docs/slices/kitchen-ops-v1.md` (superseded)

---

**Bottom line:** Scaffold is up. Execute Phase 1 shared domain, then Phase 2 PIN shell. Do not jump to payments or table map first.
