# Exercise 1: Meet the app (and watch it die)

**Goal:** run the existing Java campaign launcher and see why ordinary
process state is not durable.

# Step 1: Start the services

In the [button label="AdNet"](tab-2) tab, start the ad network:

```bash,run
.adnet-venv/bin/python services/adnet.py
```

In the [button label="Server"](tab-1) tab, start the Temporal dev server:

```bash,run
temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --db-filename temporal.db
```

Now open the [button label="Temporal UI"](tab-5) tab. It works now, and
there are no Workflows yet.

> [!IMPORTANT]
> Leave AdNet and the Temporal dev server running for the whole workshop.
> Every later challenge reattaches to these same persistent tmux sessions.

# Step 2: Launch the campaign

Skim `01-meet-the-app/practice/src/main/java/workshop/CampaignApp.java` in
the [button label="Editor"](tab-0) tab. Then use the
[button label="CLI"](tab-4) tab:

```bash,run
mvn -q -f exercises/01-meet-the-app/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.CampaignApp
```

The launcher validates the creative, reserves $50,000, publishes to Meowta
and Catstagram, then throws when PetTok returns HTTP 503. Its local list of
placements disappears with the JVM.

Re-running is unsafe: it repeats the budget reservation and successful
publications. By exercise 6, the same sequence will be a Temporal Workflow
that recovers after the Worker process dies.

# Step 3: Verify the services

In the [button label="CLI"](tab-4) tab:

```bash,run
curl -sf localhost:9999/health
```

```bash,run
temporal operator cluster health
```

When both commands succeed, hit **Check**.
