# Exercise 1: Meet the app (and watch it die)

**Goal:** run the existing TypeScript campaign launcher and see why ordinary
process state is not durable.

Use three terminals from the track root.

```bash
# Terminal 1
.adnet-venv/bin/python services/adnet.py

# Terminal 2
temporal server start-dev --db-filename temporal.db

# Terminal 3
npx tsx exercises/01-meet-the-app/practice/app.ts
```

The launcher validates the creative, reserves $50,000, publishes to Meowta
and Catstagram, then crashes when PetTok returns HTTP 503. The `placements`
array lived only in Node.js memory, so the process lost its progress.

Re-running is unsafe: it reserves the budget and publishes successful
channels again. By exercise 6, the same sequence will be a Temporal
Workflow that recovers after the Worker process dies.

## Verify

```bash
curl -sf localhost:9999/health
temporal operator cluster health
```
