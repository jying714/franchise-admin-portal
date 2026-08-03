# Home Page Composition Engine v1 — Wave 2 (Deferred)

**Status:** **Locked deferred** (2026-08-03) — do not implement until Wave 1 shell + widgetized home ship  
**Authority:** STATUS · HANDOFF · `docs/plans/customer-web-storefront-shell-v1.md` · this plan  
**Surfaces:** `customer_web` home first · **mobile home post-MVP** · HQ Website studio

---

## 1. Product statement

> Franchise owners compose the **homepage** from a **closed catalog of pre-built widgets** (add / remove / reorder / edit props), with **live preview** in HQ, without arbitrary HTML/CSS/JS that can damage quality or platform reputation.

This is a **homepage engine**, not a general website builder. Templates and mobile apply **after** the engine works on web.

---

## 2. Locks

| ID | Lock |
|----|------|
| E1 | **Closed widget catalog** — platform ships types; owners fill props |
| E2 | **Add / remove / reorder** persisted on franchise config |
| E3 | **Shared schema**; **separate renderers** per surface (web vs mobile) |
| E4 | HQ: **split pane** — form/list left, live preview right |
| E5 | **Draft → Preview → Publish** (no silent live-only edits) |
| E6 | Design tokens / branding colors; validation (lengths, images); optional spellcheck later |
| E7 | **No** free-form HTML, custom JS, or unconstrained absolute layout |
| E8 | **Templates** = starter `widgets[]` packs — **post-MVP** |
| E9 | **Mobile composition** — same principle **post-MVP**; order-biased defaults; not 1:1 web layout |
| E10 | New visual needs → **new widget type** in a product release |

---

## 3. Conceptual model

```text
franchises/{id}/config/storefront  (published)
franchises/{id}/config/storefront_draft  (optional draft)

widgets: [
  { id, type, sortOrder, enabled, props: { ... } },
  ...
]
```

**Renderer (web):** `for w in enabled.sorted → WebHomeWidget(type, props)`  
**Renderer (mobile, later):** same list or filtered list → `MobileHomeWidget(type, props)`  
**HQ preview:** same web renderer in a sized box (mobile/desktop width toggle).

Illustrative catalog: Hero, Story/Rich text, Image, CTA band, Hours (bound to store_ops), Map, Gallery, Featured items, FAQ, Contact strip, Spacer.

---

## 4. HQ Website studio (target UX)

```text
┌─────────────────────┬──────────────────────────┐
│ Section list + add  │ Live storefront preview  │
│ Drag reorder        │ (shared web widgets)     │
│ Selected props form │ Device width toggle      │
│ Publish / discard   │                          │
└─────────────────────┴──────────────────────────┘
```

Replaces “fields only” Website panel as the long-term control surface; current field editors remain until this ships.

---

## 5. Integrity (reputation)

- Prop schemas per type; reject unknown types on read (skip or fallback)  
- Max section count; soft-required Hero  
- Contrast / empty-state warnings at publish (optional v1)  
- Map only via approved embed/address path  
- Platform footer / legal minimums if product requires them  

---

## 6. Sequencing

| Phase | Work |
|-------|------|
| **Wave 1** | Public shell + section **widgets in code** (no CRUD yet) |
| **Wave 2** | Persist `widgets[]`, HQ CRUD + preview, draft/publish |
| **Post-MVP** | Templates; mobile renderer + optional per-platform visibility |

---

## 7. Explicit non-goals

- Multi-page free-form site tree (beyond home + simple Story/Contact)  
- Owner-uploaded CSS/JS  
- Pixel-identical web and mobile homes  
- Building Wave 2 before Wave 1 acceptance  

---

## 8. Acceptance (when Wave 2 is built)

- [ ] Owner adds/removes/reorders catalog widgets; publish updates live home  
- [ ] Preview matches live within token/layout rules  
- [ ] Invalid props cannot publish  
- [ ] Mobile plan documented; implementation may lag  

---

**End of deferred engine plan.**
