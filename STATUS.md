# STATUS.md — Live Project Snapshot

**Last Updated**: August 3, 2026 (~00:45 CDT — MVP-Ops inventory + staff/labor cutover gates locked)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch (active work)**: **`main`**  
**Main**: HQ · customer_web parity · POS software pilot · mobile  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| Order path (web/mobile/POS software) | **On main** |
| Storefront shell Wave 1 | **Locked — next guest-facing build** |
| Home composition engine Wave 2 | **Deferred** |
| **Inventory v1 (MVP-Ops)** | **Locked plan — Owner.com hard cutover gate** |
| **Staff/labor v1 (MVP-Ops)** | **Locked plan — greenfield; cutover gate** |
| POS hardware · iOS Mac | **In transit** |

---

## Owner.com cutover gates (Doughboys)

**Soft release:** POS parallel with current terminal/Owner.com OK while gaps exist.  
**Hard swap** (manager bar) requires:

| Gate | Plan | Minimum |
|------|------|---------|
| **Inventory** | `docs/plans/mvp-ops-inventory-v1.md` | Enabled item/ingredient qty; 0 → not sellable all channels; sale decrement; void restore; HQ adjust |
| **Staff/labor** | `docs/plans/mvp-ops-staff-labor-v1.md` | Schedule + **print**; **clock in/out**; **hours summary**; per-employee paperwork |

Order/pay/ticket already largely satisfied for soft parallel.

---

## Decision locks (storefront)

| Wave | Plan | State |
|------|------|--------|
| 1 Shell + nested UX + section home | `docs/plans/customer-web-storefront-shell-v1.md` | Next guest track |
| 2 Composition engine / HQ studio | `docs/plans/home-page-composition-engine-v1.md` | Deferred |

---

## customer_web parity core

On **main**: pizza/wings customize, cart edit via `cartItemKey`, checkout delivery + `customerPhone`.

---

## Next product focus (parallel tracks)

| Track | Focus |
|-------|--------|
| **A – Guest** | Storefront shell Wave 1 |
| **B – Ops cutover** | Inventory v1 → Staff/labor v1 (schedule, clock, hours, print) |
| **C – Hardware** | Terminals + iOS when devices arrive |
| **D – Growth** | Promos, push/SMS, loyalty, upsells — after soft stability |

**Decision locks:** 11 / 12 / 14 + storefront waves + MVP-Ops gates above.

---

**Update this file after significant sessions.**
