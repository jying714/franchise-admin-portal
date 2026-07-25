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

docker exec -it franchise-orchestrator python main.py status
```

## Overnight queue

### Task file format (`orchestrator/queue/inbox/my-task.task.txt`)

```text
# id: optional-slug
# agent: web_frontend
# priority: 5
# backend: xai
# max_regions: 2

backend: xai
Role: web_frontend

Files:
- path/to/file.dart

Goal: <one sentence product outcome>

Task:
Quote the exact first 10–12 lines of the loaded file.

Locate this exact region:
```dart
<paste real on-disk BEFORE>
```

Replace / extend so that <outcome>. Use only APIs already in this file.
Prefer ≤2 BEFORE/AFTER regions (or max_regions from header).
If already done → reply only: No change needed
```

Lower `priority` numbers run first. Default priority is 100.

### Drain commands

```bash
# Interactive CLI
/queue status
/queue run --once
/queue run

# Detached overnight (no TTY required)
docker exec -d franchise-orchestrator python queue_runner.py --drain

# One task then exit
docker exec -it franchise-orchestrator python queue_runner.py --once
```

**Rules:** sequential only; never auto-apply; on failure continue to next task; sleep 15s between tasks by default (`--sleep N`).

### End-of-day review

```text
/proposals
/proposals pending
/proposals no_change
/proposals full
/metrics
/approve <id>
/approve confirm <id>
/reject <id> reason=...
```

Learning is **governance**, not model fine-tuning: use reject reasons to update `SCOPE_CARD.md` / hard bans / task templates.

## SCOPE_CARD (always-on)

`orchestrator/SCOPE_CARD.md` is injected on every coding task.

Key rules:
- **xAI-first**: one product **outcome** per task; ≤2 regions default (3 if `max_regions: 3`)
- Paste **exact on-disk BEFORE** strings
- Field/path HARD BANs unchanged (no new DesignTokens/BrandingConfig fields, no invented progress imports)
- If region already satisfies the request → **No change needed**
- Empty-file BEFORE → HARD BAN
- `after parsed: no` → reject; do not apply

## Preferred coding task prompts (xAI outcome style)

See also `AGENT_SYSTEM.md` and **SCOPE_CARD → TASK DESIGN**.

**Outcome template (preferred):**

```text
backend: xai
Role: web_frontend
max_regions: 2

Files:
- path/to/file.dart

Goal: <one product outcome>

Task:
Quote the exact first 10–12 lines of the loaded file.

Region 1 — locate exact on-disk:
```dart
BEFORE…
```
AFTER should …

Region 2 (optional) — …

Constraints:
- Use only APIs already imported or used in this file
- No new fields on BrandingConfig / DesignTokens / FeatureConfig
- shared.OnboardingProgressProvider only (no invented progress import)
- If already satisfied → No change needed
```

**Rules of thumb (xAI-first, July 25)**

- Always include full file path(s)
- **One outcome** per task; one file preferred; explicit 2-file only when both paths listed
- Paste exact on-disk BEFORE — highest apply rate
- Prefer real fix over no_change when the goal is unmet
- Batch **4–8 outcome tasks** per AFK run (not 20 micro-chores)
- Verify-only: sparse post-apply smoke; do not fill the main queue
- Empty files: human full-file or special wording — never empty BEFORE
- STATUS.md: prefer human edit
- Treat `after parsed: no` like HARD BAN — reject

**Ollama (secondary):** keep 1-region surgical prompts if used at all.

## Review & apply workflow

```text
1. Run task (interactive or queue) → proposal saved with an id
2. /proposals  or  /proposals pending  or  /proposals no_change
3. /metrics
4. /proposals full
5. /approve <id>
6. /approve confirm <id>        # local file write only
7. git diff on the host → you commit & push
```

| Command | Effect |
|---------|--------|
| `/proposals` | List recent ids (all statuses) |
| `/proposals pending` | List only pending |
| `/proposals no_change` | Escape-hatch successes |
| `/proposals rejected` | Rejected |
| `/proposals applied` | Applied |
| `/proposals full` | Full dump of every pending proposal |
| `/metrics` | Training metrics (last 50) |
| `/approve` / `/approve <id>` | Show proposal |
| `/approve confirm` / `/approve confirm <id>` | Apply locally |
| `/reject [id] reason=...` | Reject + feedback log |
| `/queue status` / `/queue run` / `/queue run --once` | Queue control |

Treat **HARD BAN** as reject candidates.  
**No change needed** is success.  
**`after parsed: no`** → reject; do not apply.

## Model configuration

| Agent | Default | Env var |
|-------|---------|---------|
| xAI (primary) | grok-4.5 | XAI_MODEL / backends.yaml |
| orchestrator | qwen2.5-coder:7b | MODEL_ORCHESTRATOR |
| backend | qwen2.5-coder:14b | MODEL_BACKEND |
| web_frontend | qwen2.5-coder:14b | MODEL_WEB |
| mobile_shared | qwen2.5-coder:14b | MODEL_MOBILE |
| tester | qwen2.5-coder:7b | MODEL_TESTER |
| reviewer | qwen2.5-coder:7b | MODEL_REVIEWER |

## Safety

- Proposal-first; local apply only after `/approve confirm`
- Queue never applies
- No git push from the orchestrator
- No Firestore / production writes
- Source injection always wins over status-only prompts when paths are present
- Identical BEFORE/AFTER → HARD BAN (no-op)
- "No change needed" → status=`no_change`
- Empty BEFORE on empty file → HARD BAN
- Field/schema HARD BANs apply to **xAI and Ollama**

## Next improvements

- Auto-reject when AFTER fails to parse
- Empty-file / full-file replace apply path
- Optional structured unified-diff proposals
- Metrics split by backend (xAI vs Ollama)
- Validator: honor `max_regions` from task header for xAI without HARD BAN

---
Last updated: 2026-07-25 (xAI-first)
