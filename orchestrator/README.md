# Franchise Platform Orchestrator

Multi-agent coordinator that runs 24/7 on the MINISFORUM AI X1 Pro-470.

## What it does

- Loads mandatory governance docs (`STATUS.md`, `AGENT_SYSTEM.md`, …)
- Loads **real source files** when a path appears in the task
- Routes tasks to specialized agents and calls Ollama
- Validates proposals for scope drift (A3)
- Saves proposals; applies **only** after explicit `/approve confirm [id]`
- **Never** auto-pushes to git; **never** writes Firestore

## Directory layout

```
orchestrator/
├── Dockerfile
├── requirements.txt
├── main.py                 ← CLI + interactive
├── context_loader.py       ← mandatory docs (full vs minimal mode)
├── agent_router.py         ← routing + prompts
├── file_reader.py          ← safe source-file load
├── ollama_client.py        ← Ollama client + 14b→7b fallback
├── proposal_validator.py   ← A3 drift checks
├── proposal_store.py       ← save / approve / local apply
├── proposals/              ← saved proposal JSON (runtime)
└── README.md
```

Monorepo is volume-mounted at `/app`.

## Quick start

```bash
docker compose up -d --build

docker exec -it franchise-orchestrator python main.py

docker exec -it franchise-orchestrator python main.py status
```

## Preferred coding task prompts (A2)

See also `AGENT_SYSTEM.md` → **Preferred Coding Task Prompt Style**.

**Template that works well:**

```text
Using packages/shared_core/lib/src/core/models/address.dart:

1. Quote the exact first 8–12 lines of the real file.
2. Propose ONLY a short class-level docstring above the main class declaration.
3. Do not add fields, getters, methods, or change any logic or serialization.
4. Show exact before/after for that small region only (fenced code blocks preferred).
```

**Rules of thumb**

- Always include the full file path
- One file, one small change per task
- Explicit forbid list (no fields / no logic)
- Prefer natural constrained wording over ultra-rigid copy-paste-only prompts
- Do not press Enter on empty prompts (creates junk proposals)

## Review & apply workflow

```text
1. Run task → proposal saved with an id
2. /proposals
3. /approve <id>              # inspect parsed before/after
4. /approve confirm <id>      # local file write only
5. git diff on the host → you commit & push
```

| Command | Effect |
|---------|--------|
| `/proposals` | List recent ids |
| `/approve` | Show last proposal |
| `/approve <id>` | Show proposal by id |
| `/approve confirm` | Apply last locally |
| `/approve confirm <id>` | Apply that id locally |
| `/reject [id]` | Mark rejected |

Apply refuses if before-text is missing, matches multiple places, or path is outside allowed roots.

## Model configuration

| Agent | Default | Env var |
|-------|---------|---------|
| orchestrator | qwen2.5-coder:7b | MODEL_ORCHESTRATOR |
| backend | qwen2.5-coder:14b | MODEL_BACKEND |
| web_frontend | qwen2.5-coder:14b | MODEL_WEB |
| mobile_shared | qwen2.5-coder:14b | MODEL_MOBILE |
| tester | qwen2.5-coder:7b | MODEL_TESTER |
| reviewer | qwen2.5-coder:7b | MODEL_REVIEWER |

```bash
docker exec -it ollama ollama pull qwen2.5-coder:7b
docker exec -it ollama ollama pull qwen2.5-coder:14b
```

## Safety

- Proposal-first; local apply only after `/approve confirm`
- No git push from the orchestrator
- No Firestore / production writes
- High-risk keywords raise human-approval flags
- A3 warnings when a "no new fields" task still looks like it added API surface

## Next improvements

- Structured unified-diff proposals for more reliable apply
- Optional second gate for `git commit` / draft PR
- File-drop inbox / HTTP task submission

---
Last updated: 2026-07-23
