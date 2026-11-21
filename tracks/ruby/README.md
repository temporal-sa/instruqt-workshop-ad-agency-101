# Durable Ruby with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary Ruby launcher lose state
when it crashes, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the Ruby Instruqt track.

## Prerequisites

- Ruby 3.3 or newer (the `temporalio` gem requires it) and Bundler, on
  macOS or Linux
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

```bash
bundle install
python3 -m venv .adnet-venv
.adnet-venv/bin/pip install -r services/requirements.txt
```

Start with [exercise 1](exercises/01-meet-the-app/README.md). Keep AdNet and
the Temporal dev server running throughout the workshop.

## Exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app](exercises/01-meet-the-app/README.md) | crash = lost process state |
| 2 | [Your first Workflow](exercises/02-first-workflow/README.md) | Workflow classes, Workers, Task Queues |
| 3 | [Activities](exercises/03-activities/README.md) | Activity classes, `execute_activity`, and registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | `RetryPolicy` and non-retryable `ApplicationError` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signals, `wait_condition`, durable deadlines |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and replay |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- `practice/` contains learner TODOs; `solution/` is the answer key.
- Run Ruby files with `bundle exec ruby <path>` from this directory.
- Workflows subclass `Temporalio::Workflow::Definition`; Activities subclass
  `Temporalio::Activity::Definition`. Workflow and Activity type names
  default to the class names, such as `CampaignWorkflow` and
  `ReserveBudget`.
- Workflow code runs on a deterministic fiber scheduler with illegal-call
  tracing: network, file, clock, and `sleep` calls belong in Activities.
- Restart a Worker after every code edit; Workers execute the code loaded at
  startup.
- Use the prescribed Workflow IDs. Verification commands and Instruqt checks
  use those IDs.
- `scripts/check.sh` syntax-checks every Ruby file and loads every Workflow
  and Activity definition. `scripts/smoke-test.sh` runs every solution end to
  end.
