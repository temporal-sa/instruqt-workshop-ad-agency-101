# Exercise 1: Meet the app (and watch it die)

**Goal:** run the campaign launcher the way it exists today — a plain Python
script — watch it fail halfway through, and take stock of what was lost.

You're the platform engineer at an ad agency. Marketing wants CatNip Cola's
**Summer Splash** campaign live on three channels: Meowta, Catstagram, and
PetTok. The launcher script does four things in order:

1. `validate_creative` — get the creative assets approved
2. `reserve_budget` — commit $50,000 of client money
3. `publish_to_channel` — push the campaign live on each channel
4. `generate_launch_report` — tell marketing the good news

All four call **AdNet**, the ad network's API. AdNet is having a rough day.

## Part A: Start the services

You need two terminals for this part.

**Terminal 1 — AdNet** (the ad network):

```bash
uv run services/adnet.py
```

**Terminal 2 — the Temporal dev server.** We won't use Temporal in this
exercise, but start it now so it's ready for exercise 2:

```bash
temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --db-filename temporal.db
```

Open the Temporal Web UI at [http://localhost:8233](http://localhost:8233).
It's empty — no workflows yet. We'll fix that soon.

## Part B: Launch the campaign

In a third terminal, run the launcher:

```bash
uv run exercises/01-meet-the-app/practice/app.py
```

Watch closely. You should see:

- ✅ Creative approved
- 💸 Budget reserved: $50,000
- 📣 Live on meowta
- 📣 Live on catstagram
- 💥 ...and then a `requests.exceptions.HTTPError: 503 Server Error` from
  PetTok. (PetTok's ads API is, quote, "on fire.")

## Part C: The damage report

The process is dead. Take stock of what just happened:

- **$50,000 of client budget is reserved.** Is anything tracking that?
- **The campaign is live on 2 of 3 channels.** Which two? The only record
  was in local variables that died with the process.
- **Can you just run it again?** Read the script: running it from the top
  validates again, *reserves the budget again* (now $100k committed), and
  re-publishes to channels that are already live.

You could fix this the hard way: a state table in a database, a status column,
catch/retry logic around every call, a cron job to find stuck launches, a
runbook for on-call... That's the machinery every team ends up hand-building
around scripts like this one.

Or the orchestration could be **durable**: every step recorded as it
completes, automatically resumed after any crash, with retries built in.
That's what we'll build over the next four exercises — and in the capstone,
this exact script becomes a Temporal workflow.

## Verify your work

Both services should be up:

```bash
curl -s localhost:9999/health        # {"chaos": true, "status": "ok"}
temporal operator cluster health     # SERVING
```

(That `"chaos": true` is AdNet's outage simulator — it's why PetTok is down.
Leave it on. It's the whole point.)

## Stretch (if you have time)

Read `app.py` end to end and count the distinct ways a mid-run crash can leave
the system in a state the code can't recover from. (We count at least four.)

---

*Stuck or want to compare? See the `solution/` directory.*
