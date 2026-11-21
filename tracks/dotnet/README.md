# Durable .NET with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary C# launcher lose state when
it crashes, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the .NET Instruqt track.

## Prerequisites

- .NET 10 SDK
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

```bash
python3 -m venv .adnet-venv
.adnet-venv/bin/pip install -r services/requirements.txt
dotnet build CatNipCola.Workshop.slnx
```

Start with [exercise 1](exercises/01-meet-the-app/README.md). Keep AdNet and
the Temporal dev server running throughout the workshop.

## Exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app](exercises/01-meet-the-app/README.md) | crash = lost process state |
| 2 | [Your first Workflow](exercises/02-first-workflow/README.md) | `[Workflow]` classes, Workers, Task Queues |
| 3 | [Activities](exercises/03-activities/README.md) | `[Activity]` methods, typed lambdas, and registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | `RetryPolicy` and `ApplicationFailureException` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signals, `Workflow.WaitConditionAsync`, durable deadlines |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and replay |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- Each `practice/` and `solution/` directory is a small console project.
  `Directory.Build.props` sets the target framework and
  `Directory.Packages.props` pins the `Temporalio` package version for all
  of them.
- `practice/` contains learner TODOs; `solution/` is the answer key.
- Run a project with `dotnet run --project <path to .csproj>`. Worker
  projects are named `*Worker.csproj`.
- Workflow classes live in `*.workflow.cs` files. The .NET SDK has no
  sandbox, so Workflow code uses `Workflow.*` APIs and never performs I/O.
- Workflow and Activity type names come from the class name and the method
  name without its `Async` suffix, for example `CampaignWorkflow` and
  `ReserveBudget`.
- Restart a Worker after every code edit; `dotnet run` rebuilds it.
- Use the prescribed Workflow IDs. Verification commands and Instruqt checks
  use those IDs.
