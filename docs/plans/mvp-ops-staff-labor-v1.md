# MVP-Ops Staff & Labor v1 — Owner.com cutover gate

**Status:** **Locked for planning** (2026-08-03) — **greenfield** product surface; required before **hard** swap off Owner.com  
**Authority:** STATUS · HANDOFF · Doughboys operator requirement · this plan  
**Note:** Roster/PIN pieces exist for POS; **schedule, clock, hours, print = new development**

---

## 1. Problem

Managers need to **schedule staff**, **clock in/out**, see **hours**, and **print** schedule / per-employee work paperwork. Owner.com (or spreadsheets) covers this today; FranchiseHQ has **no** full labor module yet.

---

## 2. Product minimum (v1) — mandatory

| Capability | v1 requirement |
|------------|----------------|
| **Roster** | Staff list, roles, active; reuse POS auth/PIN where possible |
| **Schedule** | Create shifts (day/time/role), assign employees, week view |
| **Print schedule** | Competent printable / PDF weekly schedule |
| **Clock in/out** | **Mandatory** — staff can clock in and out (POS and/or staff entry point) |
| **Hours summary** | **Mandatory** — hours worked per employee in a date range |
| **Paperwork** | Per-employee summary suitable to print (shifts + hours) |
| **Pay context (light)** | Optional wage rate × hours for **estimate** only — not full payroll/tax engine |
| **Metrics (light)** | Total hours by day/role; basic labor snapshot |

---

## 3. Locks

| ID | Lock |
|----|------|
| L1 | Franchise-scoped staff and shifts |
| L2 | Clock events are append-only with manager edit/audit later if needed |
| L3 | Schedule print + hours summary ship in v1 (not “later”) |
| L4 | Not a payroll provider — no tax filing, W-2, direct deposit in v1 |
| L5 | Tips allocation **out** of v1 unless already trivial |
| L6 | Permissions: manager vs staff (staff clock + view own hours; manager schedule all) |

---

## 4. Platform matrix

| Surface | v1 responsibility |
|---------|-------------------|
| **HQ / Admin** | Schedule editor, roster, hours reports, print/PDF |
| **POS** | Clock in/out (primary for station staff); manager view optional |
| **Mobile** | Optional staff clock later; not required if POS clock is solid |
| **Shared / CF** | Shift + time-entry collections; report queries |

---

## 5. Work breakdown (high level)

| # | Task |
|---|------|
| LAB.1 | Schema: staff profile extensions, shifts, time_entries |
| LAB.2 | HQ week schedule UI + assign |
| LAB.3 | Print/PDF schedule |
| LAB.4 | Clock in/out on POS (PIN-scoped user) |
| LAB.5 | Hours summary report (range, per employee) |
| LAB.6 | Per-employee printable timesheet-style summary |
| LAB.7 | Light metrics (hours totals) |
| LAB.8 | Optional wage rate field + estimated pay column |

---

## 6. Acceptance

- [ ] Manager builds a week schedule and prints it  
- [ ] Employee clocks in and out on POS  
- [ ] Hours summary matches clock events for a date range  
- [ ] Per-employee paperwork printable  
- [ ] Staff cannot edit others’ punches (manager can correct)  

---

## 7. Explicit non-goals v1

- Full payroll, tax, benefits  
- Advanced forecasting / labor % auto-scheduling AI  
- Multi-state compliance engine  

---

**Cutover:** Staff/labor v1 (including **clock + hours summary + print**) is a **hard Owner.com swap gate** alongside inventory v1.
