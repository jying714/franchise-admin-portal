# Overnight sample tasks (July 24, 2026)

Safe, profitable, **proposal-only** tasks for the sequential queue.

## How to run

```powershell
# from repo root
Copy-Item orchestrator\queue\samples\overnight\*.task.txt orchestrator\queue\inbox\

docker exec -d franchise-orchestrator python queue_runner.py --drain
```

Or interactive: `/queue run`

## Morning review

```text
/proposals
/approve <id>                 # inspect
/approve confirm <id>         # only real surgical wins
/reject <id> reason=...       # everything else
```

Queue **never** auto-applies. Prefer rejecting read-only audits after scoring.

## Task mix

- Read-only audits for Decision 7 (onboarding → HQ)
- Real public API quotes (progress provider, shared interface)
- One surgical class-level docstring candidates (A1-safe)
- Live branding path confirmation (no new fields)
