# MVP-Ops Staff & Labor v1 — Owner.com cutover gate

**Status:** **COMPLETE** (2026-08-04) — merged to **main**  
**Authority:** STATUS · HANDOFF · Doughboys operator requirement · this plan  
**Surfaces:** Admin (roster, schedule, hours) · POS (clock in/out via PIN)

---

## 1. Problem

Managers need to **schedule staff**, **clock in/out**, see **hours**, and **print** schedule / per-employee paperwork.

---

## 2. Product minimum (v1) — delivered

| Capability | v1 delivery |
|------------|-------------|
| **Roster** | Admin **Station staff** → `franchises/{id}/staff` + shared `PinHash` |
| **Schedule** | Admin **Schedule** week editor (shifts collection) |
| **Print schedule** | Week print from Schedule screen |
| **Clock in/out** | POS unlock screen **Clock in / Clock out** |
| **Hours summary** | Admin **Hours** date-range totals |
| **Paperwork** | Per-employee timesheet HTML print |
| **Pay context (light)** | Optional `hourlyPay` × hours estimate on Hours |

---

## 3. Schema / services

| Path | Purpose |
|------|---------|
| `franchises/{id}/staff/{staffId}` | Roster + `pinHash` + `posEnabled` |
| `franchises/{id}/shifts/{id}` | Scheduled shifts |
| `franchises/{id}/time_entries/{id}` | Clock punches |
| `LaborFirestoreService` | Shifts + clock + range queries |
| `PinHash` (shared_core) | `v1:salt:sha256` |

---

## 4. Acceptance

- [x] Manager builds a week schedule and prints it  
- [x] Employee clocks in and out on POS  
- [x] Hours summary matches clock events for a date range  
- [x] Per-employee paperwork printable  
- [ ] Staff cannot edit others’ punches (manager can correct) — **partial**: no staff self-service edit UI; punches are service-written  

### Residual hardening

- Replace `isPosStation` email smoke gate with **`stationFranchise` custom claim**  
- Deploy rules after claim cutover  

---

## 5. Explicit non-goals v1 (still out)

- Full payroll, tax, benefits  
- Advanced forecasting / labor % auto-scheduling AI  
- Multi-state compliance engine  

---

**Cutover:** Staff/labor v1 gate **satisfied**. Soft parallel burn-in is the next operational step.
