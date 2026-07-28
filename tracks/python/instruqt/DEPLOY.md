# Deploying the track

The repo is the source of truth; this directory is the existing Python
Instruqt track. Its platform-generated IDs and published workstation image
reference were retained when the repository moved to the multi-track layout.

## 1. Publish the workstation image

Build from the **repo root** (the image bakes the whole repo + venv +
temporal CLI):

```bash
docker build --platform linux/amd64 \
  -f tracks/python/instruqt/Dockerfile -t temporal-python-workshop .
docker tag temporal-python-workshop <registry>/<org>/temporal-python-workshop:v1
docker push <registry>/<org>/temporal-python-workshop:v1
```

Use a **public** registry ref (Docker Hub public repo is simplest; Instruqt
pulls anonymously, linux/amd64 only). Then update the existing `image:` tag
in [config.yml](config.yml).

Re-push the image (bump the tag) whenever exercise code or dependencies
change — the sandbox runs whatever was baked.

## 2. Push the existing track

Authenticate with `instruqt auth login`, then run `instruqt track push` from
this directory. The retained `owner`, track `id`, and challenge IDs target the
existing Python track.

## 3. Test on the platform

```bash
instruqt track validate          # already green locally
instruqt track test              # per challenge: setup -> check (expect fail) -> solve -> check (expect pass)
instruqt track open              # click through as a learner; play all 8 challenges once
```

Worth eyeballing on a real play: the Temporal UI tab errors until the
learner starts the dev server in challenge 1 (intended, the assignment says
so), and the `bash,run` buttons target the right tabs.

## 4. Event setup (virtual delivery)

- **Invite type:** Live Event. Set "how many unique users" to the
  registration count — claim-limited invites are exempt from per-IP play
  caps (matters if attendees share an office VPN egress).
- **Hot start:** invite-scoped pool at ~70% of registrations, provisioned
  ~1 hour before; auto-refill off; kill the pool 15–30 min after start.
- **Timing:** attendees claim sandboxes **after** the 30-minute
  presentation — `idle_timeout: 3600` and `timelimit: 10800` (3 h) keep
  sandboxes alive across the talk and stragglers regardless.
- The instructor dashboard shows per-learner challenge progress and failed
  check attempts live; the check fail-messages are written as hints, so
  "stuck on challenge 4 with 3 failed checks" tells you who to visit.

## 5. Before each delivery

From `tracks/python`, with `uv` and `temporal` installed:

```bash
./scripts/smoke-test.sh    # runs every solution end-to-end; expect SMOKE TEST PASSED
```

If the SDK or CLI versions in the image have drifted (new `uv.lock`, new
image tag), run the smoke test, rebuild, re-push the image, and do one
platform play-through.
