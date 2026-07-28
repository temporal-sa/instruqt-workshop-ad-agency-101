# Durable Java with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary Java launcher lose state
when it crashes, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the Java Instruqt track.

## Prerequisites

- Java 21
- Maven 3.9+
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

```bash
python3 -m venv .adnet-venv
.adnet-venv/bin/pip install -r services/requirements.txt
mvn -q install -N
```

Start with [exercise 1](exercises/01-meet-the-app/README.md). Keep AdNet and
the Temporal dev server running throughout the workshop.

## Exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app](exercises/01-meet-the-app/README.md) | crash = lost process state |
| 2 | [Your first Workflow](exercises/02-first-workflow/README.md) | interfaces, implementations, Workers, Task Queues |
| 3 | [Activities](exercises/03-activities/README.md) | Activity interfaces, stubs, and registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | `RetryOptions` and `ApplicationFailure` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signals, `Workflow.await`, durable deadlines |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and replay |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- Each `practice/` and `solution/` directory is a small Maven project that
  inherits SDK and plugin versions from this directory's `pom.xml`.
- Workflow and Activity contracts are annotated interfaces; implementation
  classes contain behavior.
- Workflow code uses `Workflow.*` APIs. Java has no Workflow sandbox, so
  determinism is enforced by design and replay testing.
- Restart a Worker after every code edit.
- Use the prescribed Workflow IDs; verification and Instruqt checks use them.
