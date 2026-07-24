# Franchise Platform Orchestrator

Multi-agent coordinator that runs 24/7 on the MINISFORUM AI X1 Pro-470.

## What it does

- Loads mandatory governance docs (`STATUS.md`, `AGENT_SYSTEM.md`, …)
- Always loads **SCOPE_CARD.md** (short Phase 1 hard constraints)
- Loads **real source files** when a path appears in the task
- Routes tasks to specialized agents and calls Ollama
- Validates proposals for scope drift (A3) + **hard ban list** + **identical BEFORE/AFTER no-op ban**
- Saves proposals; applies **only** after explicit `/approve confirm [id]`
- Treats **"No change needed"** as a first-class success (`status=no_change`)
- **Never** auto-pushes to git; **never** writes Firestore
- Optional **overnight queue**: drop task files in `queue/inbox/` and drain sequentially
- Lightweight **`/metrics`** for training measurement

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
# agent: backend
# priority: 10

Using web-app/lib/config/design_tokens.dart:

1. Quote the exact first 12 lines of the real file.
2. No edits. End with: No change needed.
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
/proposals no_change            # escape-hatch successes
/proposals full                 # full context dump of every pending proposal
/metrics                        # training rates (last 50)
/approve <id>
/approve confirm <id>           # winners only
/reject <id> reason=...         # logs orchestrator/feedback/rejects.jsonl
```

Learning is **governance**, not model fine-tuning: use reject reasons to update `SCOPE_CARD.md` / hard bans / task templates.

## SCOPE_CARD (always-on)

`orchestrator/SCOPE_CARD.md` is injected on every coding task (especially minimal mode).

Key rules (see full file):
- Prefer **new surfaces** over re-polishing the same HQ DesignTokens consumers
- If the region already satisfies the request → reply only: **No change needed**
- Identical BEFORE/AFTER is a HARD BAN (no-op)

## Preferred coding task prompts (A2)

See also `AGENT_SYSTEM.md` → **Preferred Coding Task Prompt Style**.

**Template that works well:**

```text
Using packages/shared_core/lib/src/core/models/address.dart:

1. Quote the exact first 8–12 lines of the real file.
2. Propose ONLY a short class-level docstring above the main class declaration.
3. Do not add fields, getters, methods, or change any logic or serialization.
4. If the named region already satisfies the request, reply ONLY with: No change needed.
5. Show exact before/after for that small region only (fenced code blocks preferred).
   BEFORE and AFTER must differ. Identical fences = invalid (no-op).
```

**Rules of thumb**

- Always include the full file path
- One file (or explicit 2-file), one small change per task
- Explicit forbid list (no fields / no logic)
- Prefer **new surfaces** (files not recently micro-polished)
- Multi-file tasks: require quote blocks first or `FAILED TO LOAD`
- Prefer small read-only quote tasks for overnight until timeouts are rare
- Reward honesty: **No change needed** is a correct outcome when already done

## Review & apply workflow

```text
1. Run task (interactive or queue) → proposal saved with an id
2. /proposals  or  /proposals pending  or  /proposals no_change
3. /metrics                     # see training rates
4. /proposals full              # see every pending proposal with full task + response
5. /approve <id>
6. /approve confirm <id>        # local file write only
7. git diff on the host → you commit & push
```

| Command | Effect |
|---------|--------|
| `/proposals` | List recent ids (all statuses) |
| `/proposals pending` | List only pending (un-accepted / un-rejected) |
| `/proposals no_change` | List escape-hatch successes |
| `/proposals rejected` | List rejected |
| `/proposals applied` | List applied |
| `/proposals full` | **Fully print** every pending proposal (task + response + parsed before/after) |
| `/metrics` | Training metrics (quote / no_change / real-diff / HARD BAN / applied rates) |
| `/approve` | Show last proposal |
| `/approve <id>` | Show proposal by id |
| `/approve confirm` | Apply last locally |
| `/approve confirm <id>` | Apply that id locally |
| `/reject [id] reason=...` | Mark rejected + feedback log |
| `/queue status` | Inbox / running / done |
| `/queue run` | Drain inbox |
| `/queue run --once` | One task |

Treat **HARD BAN** validator warnings as reject candidates.  
**No change needed** is a success — it is not pending work.

## Model configuration

| Agent | Default | Env var |
|-------|---------|---------|
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
- "No change needed" → status=`no_change` (success, nothing to apply)

## Next improvements

- Structured unified-diff proposals for more reliable apply (optional)
- Feedback → SCOPE_CARD refresh checklist (human-gated)
- Systematic 7b vs 14b A/B on Stage-A tasks (optional)

---
Last updated: 2026-07-24
