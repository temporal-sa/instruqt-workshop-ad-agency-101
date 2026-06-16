# Exercise 1 — Solution notes

There's no code to fix in this exercise — the broken behavior **is** the
lesson. If your run looked like this, it worked:

```
🚀 Launching campaign 'summer-splash' for CatNip Cola...
  ✅ Creative approved: creative-summer-splash
  💸 Budget reserved: $50,000 (budget-summer-splash)
  📣 Live on meowta: meowta-summer-splash
  📣 Live on catstagram: catstagram-summer-splash
Traceback (most recent call last):
  ...
requests.exceptions.HTTPError: 503 Server Error: SERVICE UNAVAILABLE
for url: http://localhost:9999/publish/pettok
```

## What was lost when the process died

| State | Where it lived | Where it is now |
|---|---|---|
| Creative approval | `creative_id` local variable | gone |
| $50k budget reservation | `reservation_id` local variable | gone (but AdNet still has the money committed) |
| Which channels are live | `placements` list | gone |
| Where to resume | the instruction pointer | gone |

## Why "just run it again" is dangerous

`launch_campaign` starts from the top every time. A second run would:

1. Re-validate the creative (harmless, but wasteful)
2. **Reserve a second $50,000** — AdNet has no idea this is the same launch
3. Re-publish to Meowta and Catstagram, which are already live

The script has no memory, so every failure forces a human to reconstruct
state by hand before anyone dares re-run it.

In the capstone (exercise 6) you'll refactor this exact file into a Temporal
workflow. Same four functions, same orchestration — but every completed step
is recorded, the crash becomes a non-event, and the launch picks up exactly
where it left off.
