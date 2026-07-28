# Durable TypeScript with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary TypeScript launcher lose
state when it crashes, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the TypeScript Instruqt track.

## Prerequisites

- Node.js 22 or newer
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

```bash
npm install
python3 -m venv .adnet-venv
.adnet-venv/bin/pip install -r services/requirements.txt
```

Start with [exercise 1](exercises/01-meet-the-app/README.md). Keep AdNet and
the Temporal dev server running throughout the workshop.

## Exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app](exercises/01-meet-the-app/README.md) | crash = lost process state |
| 2 | [Your first Workflow](exercises/02-first-workflow/README.md) | Workflow functions, Workers, Task Queues |
| 3 | [Activities](exercises/03-activities/README.md) | typed Activity proxies and registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | retry policies and `ApplicationFailure` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signals, `condition`, durable deadlines |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and replay |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- `practice/` contains learner TODOs; `solution/` is the answer key.
- Run TypeScript files with `npx tsx <path>`.
- Workflow files use type-only Activity imports. Activity implementations
  never enter the Workflow sandbox.
- Restart a Worker after every code edit; Workers execute the code loaded at
  startup.
- Use the prescribed Workflow IDs. Verification commands and Instruqt checks
  use those IDs.
