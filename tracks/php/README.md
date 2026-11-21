# Durable PHP with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary PHP launcher lose state when
it crashes, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the PHP Instruqt track.

## Prerequisites

- PHP 8.2 or newer with the `curl` and `sockets` extensions
- Composer
- [RoadRunner](https://github.com/roadrunner-server/roadrunner/releases)
  (`rr`) on your `PATH`, in the version that `composer.lock` pins for
  `roadrunner/roadrunner`
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

```bash
composer install
python3 -m venv .adnet-venv
.adnet-venv/bin/pip install -r services/requirements.txt
```

`vendor/bin/rr get-binary` downloads a matching RoadRunner binary if you do
not have one.

Start with [exercise 1](exercises/01-meet-the-app/README.md). Keep AdNet and
the Temporal dev server running throughout the workshop.

## Exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app](exercises/01-meet-the-app/README.md) | crash = lost process state |
| 2 | [Your first Workflow](exercises/02-first-workflow/README.md) | Workflow classes, RoadRunner Workers, Task Queues |
| 3 | [Activities](exercises/03-activities/README.md) | Activity interfaces, stubs, and registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | `RetryOptions` and `ApplicationFailure` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signals, `Workflow::awaitWithTimeout`, durable deadlines |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and replay |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- `practice/` contains learner TODOs; `solution/` is the answer key.
- PHP Workers run under RoadRunner. `.rr.yaml` in this directory holds the
  local connection settings, and each exercise selects its `worker.php`:
  `rr serve -o server.command="php exercises/<exercise>/practice/worker.php"`.
  Do not run `worker.php` with `php` directly.
- Workflow classes carry `#[WorkflowInterface]`; their Workflow Type is the
  class name. Activity contracts are `#[ActivityInterface]` interfaces whose
  Activity Types are the interface prefix plus the method name, for example
  `Campaign.reserveBudget`.
- Workflow methods are coroutines: `yield` an Activity call to get its
  result. The PHP SDK has no Workflow sandbox, so keep I/O, clocks, and
  randomness in Activities.
- Worker processes write logs to STDERR. STDOUT belongs to RoadRunner.
- Restart a Worker after every code edit; Workers execute the code loaded at
  startup.
- Use the prescribed Workflow IDs. Verification commands and Instruqt checks
  use those IDs.
- `composer check` lints every exercise and loads every class.
