# Slice: Admin dashboard ops fixes v1

**Status**: Ready to implement  
**Branch (suggested)**: `feat/admin-dashboard-ops-fixes-v1` off `main`  
**Date locked**: July 27, 2026  
**Authority for failures**: Admin exhaustive smoke (July 27)

## Goal

Restore **day-2 Admin ops reliability** for managers without redesigning the menu modifier architecture (that is `menu-modifier-system-rebuild-v1`).

## In scope (P0 / P1)

| Area | Work |
|------|------|
| Categories | Fix **add** persist; fix **delete**; implement or remove bulk delete; remove broken name/description sort UI; fix/keep asc toggle only; **remove bulk upload** entry |
| Promotions | Fix add / edit / delete end-to-end (Firestore + UI) |
| Orders | Fix row ⋮ **Update status** / **Process refund**; franchise switch refresh; clear date-range filter; hide or label export stub |
| Menu list ops only | Fix delete **snackbar** auto-dismiss; layout overflow; **remove Import CSV**; hide empty Columns stub |
| Home | **Wire Active Promotions KPI** (real count, not eternal loading `"--"`) |
| Franchise switch | Menu/categories streams must not hang after multi-switch |
| Staff / Chat | Keep **honest placeholders** or document defer — do not fake completeness |

## Out of scope (hard)

- Menu **modifier / Customize** redesign, dual-tree migration, mobile heuristics  
- Full StaffAccessScreen / ChatManagementScreen wiring (optional later)  
- Inventory full warehouse / SKU linking  
- Dietary/allergens/inventory fields on menu item (belong with modifier rebuild or immediate follow-on of that epic)  
- Developer dashboard  

## Acceptance

- [ ] Category add/edit/delete works on Doughboys franchise  
- [ ] Promo CRUD works  
- [ ] Orders status + refund menus open and persist; franchise switch updates list  
- [ ] Active Promotions KPI shows a real number (including 0)  
- [ ] No Import CSV / category bulk upload in UI  
- [ ] Smoke re-run of failed rows → Pass  

## Notes

Registry: `web-app/lib/core/section_registry.dart` — ops only.  
Shell: `web-app/lib/admin/dashboard/admin_dashboard_screen.dart`.
