# Slice: Kitchen Ops v1

> **SUPERSEDED (July 30, 2026)**  
> Product direction changed under **Decision 14**. A standalone thin Kitchen management app will not be shipped.  
> Station surface is now the **thin POS app** — see `docs/slices/pos-app-v1.md` and Decision 14.  
> Cash-on-pickup toggles, multi-printer category routing, manager-only void/refund, and print rules are absorbed into the POS slice.  
> This file is retained for historical context only. Do not implement a separate kitchen-only binary.

---

**Status**: **Superseded** (originally Locked July 29, 2026)  
**Branch**: N/A  
**Authority (historical)**: Decision 13 (now superseded in framing by Decision 14)  
**Replacement**: `docs/slices/pos-app-v1.md` · Decision 14

---

## Original problem (historical)

MVP was framed as **not** a full POS. Kitchen needed a safe order board for cooks, automatic ticket printing, optional cash on pickup, and manager visibility on tablet/printer failure.

## Original product locks (historical)

Thin Kitchen Flutter app for cooks only; Admin cashOnPickup + cashPrintOnAcceptOnly toggles; multi-printer by category; card auto-print on `paid`; cash print rules; manager-only void/cancel/refund; Android make-line tablet; manager push/SMS on failure.

Full POS (cash drawer, card-present, complex table service) was explicitly out of MVP at the time.

## Why superseded

A pure kitchen-only management app would not be used long-term and would not make the product market-viable. The counter-focused thin POS (Decision 14) is the correct station surface and reuses the valid print, cash-toggle, and manager-gate thinking without a throwaway binary.

---

**Do not start work from this file.** Use `pos-app-v1.md`.
