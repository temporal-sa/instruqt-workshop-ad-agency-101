# Durable Rust with Temporal — the CatNip Cola workshop

You are the platform engineer at an ad agency. CatNip Cola's **Summer
Splash** campaign must go live on three channels today. In six exercises
(about 90 minutes), you will watch an ordinary Rust launcher lose state
when it fails, then rebuild it as a durable Temporal application.

This directory is both a standalone local workshop and the source baked
into the Rust Instruqt track.

## Prerequisites

- Rust 1.92 or newer (install with [rustup](https://rustup.rs)); the
  Temporal SDK crates declare `rust-version = "1.92.0"`
- `protoc` and the protobuf well-known types, used to build the Temporal SDK
  (`brew install protobuf` on macOS;
  `apt-get install protobuf-compiler libprotobuf-dev` on Debian/Ubuntu)
- Python 3 with Flask, for the language-neutral AdNet mock service
- Temporal CLI

```bash
python3 -m venv .adnet-venv
.adnet-venv/bin/pip install -r services/requirements.txt
cargo build --bins
```

The first `cargo build` compiles the Temporal SDK and takes a few minutes.
After that, each `cargo run` recompiles only the exercise you changed.

Start with [exercise 1](exercises/01-meet-the-app/README.md). Keep AdNet and
the Temporal dev server running throughout the workshop.

## Exercises

| # | Exercise | You learn |
|---|---|---|
| 1 | [Meet the app](exercises/01-meet-the-app/README.md) | crash = lost process state |
| 2 | [Your first Workflow](exercises/02-first-workflow/README.md) | `#[workflow]` structs, Workers, Task Queues |
| 3 | [Activities](exercises/03-activities/README.md) | `#[activities]`, `ctx.execute_activity`, registration |
| 4 | [Retries and errors](exercises/04-retries-and-errors/README.md) | `RetryPolicy` and non-retryable `ApplicationFailure` |
| 5 | [Human in the loop](exercises/05-human-in-the-loop/README.md) | Signals, `wait_condition`, durable timers |
| 6 | [Capstone](exercises/06-capstone/README.md) | the full durable refactor |
| 7 | [Bonus: observability](exercises/07-bonus-observability/README.md) | Event History and `WorkflowReplayer` |
| 8 | [Take-home: Cloud](exercises/08-to-the-cloud/README.md) | API-key connectivity to Temporal Cloud |

## Conventions

- `practice/` contains learner TODOs; `solution/` is the answer key.
- One Cargo package holds the whole workshop. Each program is a binary
  target in `Cargo.toml`: run a practice Worker with
  `cargo run -q --bin <name>-worker`, and the matching answer key with
  `cargo run -q --bin <name>-worker-solution`.
- Workflow types are struct names (`TaglineWorkflow`). Activity types are
  `<Type>::<method>` (`HashtagActivities::fetch_hashtags`), as named by the
  SDK's `#[activities]` macro.
- Rust has no Workflow sandbox. Workflow code uses `ctx` APIs for Activities,
  timers, and waiting, and the SDK's `select!` instead of Tokio's.
- Restart a Worker after every code edit; Workers execute the code compiled
  into them.
- Use the prescribed Workflow IDs. Verification commands and Instruqt checks
  use those IDs.
