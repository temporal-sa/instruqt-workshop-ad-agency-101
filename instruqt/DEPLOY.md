# Deploying the track

The repo is the source of truth; this directory is the Instruqt track. Two
placeholders must be filled before the first push, then it's the standard
track-as-code loop.

## 1. Publish the workstation image

Build from the **repo root** (the image bakes the whole repo + venv +
temporal CLI):

```bash
docker build --platform linux/amd64 -f instruqt/Dockerfile -t temporal-python-workshop .
docker tag temporal-python-workshop <registry>/<org>/temporal-python-workshop:v1
docker push <registry>/<org>/temporal-python-workshop:v1
```

Use a **public** registry ref (Docker Hub public repo is simplest; Instruqt
pulls anonymously, linux/amd64 only). Then set `image:` in
[config.yml](config.yml) — replace `REGISTRY_PLACEHOLDER`.

Re-push the image (bump the tag) whenever exercise code or dependencies
change — the sandbox runs whatever was baked.

## 2. First push

- Set `owner:` in [track.yml](track.yml) to the Temporal Instruqt org slug
  (`instruqt track list` shows tracks per org once you're logged in via
  `instruqt auth login`).
- From this directory: `instruqt track push`. If your CLI version insists on
  a track `id`, mint one with `instruqt track create --title "Durable Python
  with Temporal"` in a scratch directory and copy the generated `id:` line
  into track.yml, keeping everything else ours.

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

From the repo root, with `uv` and `temporal` installed:

```bash
./scripts/smoke-test.sh    # runs every solution end-to-end; expect SMOKE TEST PASSED
```

If the SDK or CLI versions in the image have drifted (new `uv.lock`, new
image tag), run the smoke test, rebuild, re-push the image, and do one
platform play-through.
