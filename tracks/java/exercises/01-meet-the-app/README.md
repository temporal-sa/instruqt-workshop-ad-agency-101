# Exercise 1: Meet the app (and watch it die)

**Goal:** run the existing Java campaign launcher and see why ordinary
process state is not durable.

Use three terminals from the track root:

```bash
# Terminal 1
.adnet-venv/bin/python services/adnet.py

# Terminal 2
temporal server start-dev --db-filename temporal.db

# Terminal 3
mvn -q -f exercises/01-meet-the-app/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.CampaignApp
```

The launcher validates the creative, reserves $50,000, publishes to Meowta
and Catstagram, then throws when PetTok returns HTTP 503. Its local list of
placements disappears with the JVM.

Re-running is unsafe: it repeats the budget reservation and successful
publications. By exercise 6, the same sequence will be a Temporal Workflow
that recovers after the Worker process dies.

## Verify

```bash
curl -sf localhost:9999/health
temporal operator cluster health
```
