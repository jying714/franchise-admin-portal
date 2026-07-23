# Franchise Platform Orchestrator

Minimal but functional multi-agent coordinator that runs 24/7 on the MINISFORUM AI X1 Pro-470.

## What it does

- Loads the **mandatory governance documents** defined in `AGENT_SYSTEM.md` at startup and for every task.
- Routes natural-language tasks to the correct specialized agent (backend, web_frontend, mobile_shared, tester, reviewer, or itself).
- Calls the appropriate Ollama model (light 7B for orchestration / review / test, 14B for heavy coding work).
- **Never** writes to the repo or Firestore. It only produces proposals.
- Explicitly flags tasks that require human approval (config, schema, payments, security, branding, architecture).

## Directory layout

```
orchestrator/
├── Dockerfile
├── requirements.txt
├── main.py              ← entrypoint (CLI + interactive)
├── context_loader.py    ← loads mandatory .md files
├── agent_router.py      ← routing + human-approval gates
├── ollama_client.py     ← thin async Ollama wrapper
└── README.md
```

The monorepo is volume-mounted at `/app`, so the real `prompts/`, `AGENT_SYSTEM.md`, `ROADMAP.md`, etc. are always live.

## Quick start

```bash
# From the monorepo root
docker compose up -d --build

# Interactive session
docker exec -it franchise-orchestrator python main.py

# One-shot task
docker exec -it franchise-orchestrator python main.py task \
  "Summarize current Phase 0 status against the acceptance criteria in tasks/Phase0.md"

# Check environment
docker exec -it franchise-orchestrator python main.py status
```

## Model configuration

Defaults (override with environment variables in `docker-compose.yml`):

| Agent          | Default model          | Env var              |
|----------------|------------------------|----------------------|
| orchestrator   | qwen2.5-coder:7b       | MODEL_ORCHESTRATOR   |
| backend        | qwen2.5-coder:14b      | MODEL_BACKEND        |
| web_frontend   | qwen2.5-coder:14b      | MODEL_WEB            |
| mobile_shared  | qwen2.5-coder:14b      | MODEL_MOBILE         |
| tester         | qwen2.5-coder:7b       | MODEL_TESTER         |
| reviewer       | qwen2.5-coder:7b       | MODEL_REVIEWER       |

Make sure the models are already pulled in the `ollama` container:

```bash
docker exec -it ollama ollama pull qwen2.5-coder:7b
docker exec -it ollama ollama pull qwen2.5-coder:14b
# (and any other models you prefer)
```

## Safety guarantees (Phase 0)

- Tool surface is intentionally tiny: read docs + call Ollama.
- No git write, no Firestore write, no file mutation.
- High-risk keywords automatically raise the human-approval flag.
- Every response ends with a clear “Next steps for human” section.

## Next improvements (after Phase 0 is green)

- File-drop inbox (`tasks/inbox/*.md`)
- Simple FastAPI endpoint for remote task submission
- LangGraph state machine for multi-step tickets
- Automatic PR draft creation (still requiring human merge)

---
Last updated: 2026-07-22
