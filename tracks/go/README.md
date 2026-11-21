# Durable Go with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary Go launcher lose state when
it crashes, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the Go Instruqt track.

## Prerequisites

- Go matching the `go` directive in `go.mod` or newer
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

Run every command from this directory (the Go module root):

```bash
go mod download
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
| 3 | [Activities](exercises/03-activities/README.md) | Activity structs, `ExecuteActivity`, and registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | `RetryPolicy` and non-retryable `ApplicationError` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signal channels, `AwaitWithTimeout`, durable deadlines |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and replay |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- One Go module (`go.mod`) holds every exercise. Each `practice/` and
  `solution/` directory is a package with a `worker/` main package beside it.
- `practice/` contains learner TODOs; `solution/` is the answer key.
- Start Workers with `go run ./exercises/<exercise>/practice/worker`.
- Workflow and Activity Types are the Go function and method names, for
  example `CampaignWorkflow` and `ReserveBudget`.
- Go has no Workflow sandbox: use `workflow.*` APIs (`workflow.Go`,
  `workflow.Sleep`, `workflow.Now`, `workflow.GetLogger`) in Workflow code
  and keep I/O in Activities.
- Restart a Worker after every code edit; Workers execute the code compiled
  at startup.
- Use the prescribed Workflow IDs. Verification commands and Instruqt checks
  use those IDs.
