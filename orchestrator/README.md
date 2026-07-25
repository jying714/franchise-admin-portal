# Franchise Platform Orchestrator

Multi-agent coordinator that runs 24/7 on the MINISFORUM AI X1 Pro-470.

## What it does

- Loads mandatory governance docs (`STATUS.md`, `AGENT_SYSTEM.md`, …)
- Always loads **SCOPE_CARD.md** (short Phase 1 hard constraints)
- Loads **real source files** when a path appears in the task
- Routes tasks to specialized agents; **primary backend is xAI** (`backend: xai`); Ollama optional
- Validates proposals for scope drift (A3) + **hard ban list** + **identical BEFORE/AFTER no-op ban**
- Saves proposals; applies **only** after explicit `/approve confirm [id]`
- Treats **"No change needed"** as a first-class success (`status=no_change`)
- **Never** auto-pushes to git; **never** writes Firestore
- Optional **overnight queue**: drop task files in `queue/inbox/` and drain sequentially
- Lightweight **`/metrics`** for training measurement

## Operating mode (xAI-first)

| Backend | Role |
|---------|------|
| **`backend: xai`** (grok-4.5) | **Primary product engine** — outcome-sized tasks, ≤2–3 regions/file |
| Ollama (7b/14b) | Optional verify-only / tiny hygiene when xAI unavailable |

Human remains the merge gate. HARD BAN field/path rules still apply to both.

## Directory layout

```
orchestrator/
├── Dockerfile
├── requirements.txt
├── main.py                 ← CLI + interactive
├── queue_runner.py         ← drain inbox overnight
├── feedback.py             ← approve/reject JSONL logging
├── context_loader.py       ← mandatory docs + SCOPE_CARD
├── SCOPE_CARD.md           ← always-on IN/OUT constraints
├── agent_router.py         ← routing + prompts
├── file_reader.py          ← safe source-file load
├── ollama_client.py        ← Ollama client + 14b→7b fallback
├── xai_client.py           ← xAI API (proposal only)
├── proposal_validator.py   ← A3 drift checks + hard bans + no-op ban
├── proposal_store.py       ← save / approve / local apply + list_by_status + metrics
├── proposals/              ← saved proposal JSON (runtime)
├── queue/
│   ├── inbox/              ← drop *.task.txt here
│   ├── running/            ← in-flight task file
│   ├── done/               ← finished + .meta.json
│   └── run_log.md          ← append-only run log (runtime)
├── feedback/
│   ├── rejects.jsonl       ← /reject reason=… (runtime)
│   └── approves.jsonl      ← successful applies (runtime)
└── README.md
```

Monorepo is volume-mounted at `/app`.

## Quick start

```bash
docker compose up -d --build
docker exec -it franchise-orchestrator python main.py
```

## Overnight queue

### Task file format

```text
# id: optional-slug
# agent: web_frontend
# priority: 5
# backend: xai
# max_regions: 1

backend: xai
Role: web_frontend

Files:
- path/to/file.dart

Goal: <one sentence product outcome>

Task:
Quote the exact first 10–12 lines of the loaded file.
Respond ONLY with FILE / BEFORE / AFTER fences (no truncation prose).
Locate exact on-disk BEFORE (prefer multi-line window).
AFTER: <outcome using real APIs only>.
If already done → No change needed
```

Lower `priority` numbers run first.

### Drain

```bash
/queue status
/queue run
/queue run --once
docker exec -d franchise-orchestrator python queue_runner.py --drain
```

### End-of-day review

```text
/proposals full
/metrics
/approve <id>
/approve confirm <id>
/reject <id> reason=...
```

## SCOPE_CARD highlights (July 25)

- **xAI-first** outcome tasks; paste exact on-disk BEFORE
- **One FILE path once** — dual FILE headers for same path → allowlist HARD BAN
- Prefer **multi-line** BEFORE; fences only (no truncation essay)
- Progress listenable: `ChangeNotifierProvider<OnboardingProgressProviderImpl>` + ProxyProvider to abstract — **never** CNP of abstract
- Menu delete: **`deleteMenuItem(id)`** not `removeMenuItem`
- Empty BEFORE on empty file → HARD BAN
- `after parsed: no` → reject

## Preferred coding task prompts

**Rules of thumb**

- One outcome, one file preferred, `max_regions: 1` when wiring one stub
- Paste exact on-disk BEFORE — highest apply rate
- Name real APIs from injected interfaces
- Batch **4–8** outcome tasks per AFK run
- Verify-only sparse; STATUS.md prefer human edit

## Review & apply workflow

1. Run task → proposal id  
2. `/proposals full`  
3. `/approve confirm <id>` local only  
4. Host `git diff` → commit & push  

## Safety

- Proposal-first; no git push; no Firestore from agents
- HARD BAN / no-op / empty BEFORE / after parse fail → reject
- Field/schema HARD BANs apply to xAI and Ollama

## Next improvements

- Auto-reject when AFTER fails to parse
- Empty-file / full-file replace apply path
- Metrics split by backend
- Validator: honor `max_regions`; same-path multi-pair allowlist

---
Last updated: 2026-07-25 (xAI API lessons)
