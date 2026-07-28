# Durable Python with Temporal — the CatNip Cola workshop

You're the platform engineer at an ad agency, and CatNip Cola's **Summer
Splash** campaign has to go live on three ad channels today. In six
exercises (~90 minutes) you'll watch a plain Python launcher lose $50,000 of
state mid-crash, then rebuild it as a durable Temporal application —
workflows, activities, retry policies, typed business errors — and finish by
killing your own worker mid-launch and watching the campaign complete anyway.

This repo is self-contained: it's the same content used in the instructor-led
Instruqt workshop, runnable on any laptop.

## Prerequisites

Two tools (each is a single binary; both have Homebrew formulas):

- **uv** — Python package manager. [Install docs](https://docs.astral.sh/uv/getting-started/installation/), or:
  `brew install uv` / `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **temporal** — the Temporal CLI, which includes the dev server and Web UI.
  [Install docs](https://docs.temporal.io/cli#install), or:
  `brew install temporal` / `curl -sSf https://temporal.download/cli.sh | sh`

You don't need to install Python: uv manages it.

## Setup

```bash
git clone <this-repo> && cd <this-repo>
uv sync
```

Then open [exercises/01-meet-the-app/README.md](exercises/01-meet-the-app/README.md)
and go. Exercise 1 walks you through starting the two long-running services
(AdNet and the Temporal dev server); keep them running for the whole workshop.

## The exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app (and watch it die)](exercises/01-meet-the-app/README.md) | the problem: crash = lost state |
| 2 | [Your first workflow](exercises/02-first-workflow/README.md) | workflow definitions, workers, task queues, the CLI |
| 3 | [Activities](exercises/03-activities/README.md) | `@activity.defn`, `execute_activity`, timeouts |
| 4 | [Failures, retries, and error handling](exercises/04-retries-and-errors/README.md) | retry policies, transient vs. business errors, `ApplicationError` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | signals, durable timers, `wait_condition`, deadline branching |
| 6 | [Capstone: make it durable](exercises/06-capstone/README.md) | the full refactor + the worker-kill finale |
| 7 | [Bonus: observability deep dive](exercises/07-bonus-observability/README.md) | event history forensics, the Replayer |
| 8 | [Take-home: to the cloud](exercises/08-to-the-cloud/README.md) | Temporal Cloud namespaces, API-key auth, the one-line migration |

## The cast

- **AdNet** (`services/adnet.py`, port 9999) — the mock ad network every
  exercise calls. Starts in **chaos mode**: PetTok's publish API returns 503
  until you `curl -X POST localhost:9999/chaos/off`. (Toggle it back **on**
  before exercises 4 and 6 — the failures are the curriculum.)
- **The channels** — Meowta, Catstagram, PetTok... and Dogbook, where CatNip
  Cola is permanently banned (HTTP 403, forever). That's exercise 4's
  non-retryable error.
- **The Temporal dev server** — `temporal server start-dev`, with the Web UI
  at [http://localhost:8233](http://localhost:8233). Exercise 1 gives you the
  exact command.

## Conventions

- Every exercise has a `practice/` directory (yours — look for `TODO`
  comments) and a `solution/` directory (compare, or unstick yourself).
- Every README ends with a **Verify your work** section: CLI commands whose
  output tells you whether you nailed it.
- Exercises prescribe workflow IDs (`tagline-1`, `publish-1`,
  `campaign-summer-splash`...). Use them verbatim — the verify commands
  (and the Instruqt checks) look those IDs up.
- **Restart your worker after every code edit.** Workers run the code they
  loaded at startup. This is the #1 gotcha; make the restart a reflex.
