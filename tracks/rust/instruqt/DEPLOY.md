# Deploy the Rust track

This directory is one independently deployable Instruqt track. Run Instruqt
CLI commands here; build its workstation image from the repository root.

## First deployment

```bash
docker build --platform linux/amd64 \
  -f tracks/rust/instruqt/Dockerfile \
  -t <registry>/temporal-rust-workshop:v1 .
docker push <registry>/temporal-rust-workshop:v1
```

The image compiles the Temporal SDK and every exercise binary at build time,
so learners' `cargo run` commands only recompile the file they edited. Under
`linux/amd64` emulation on an Apple Silicon host, the first build takes a
while; later builds reuse the dependency layer unless `Cargo.toml` or
`Cargo.lock` changes.

Replace `REGISTRY_PLACEHOLDER` in `config.yml` with the public registry
namespace. The new local track intentionally has no Instruqt-generated
`id`. Create or duplicate the remote track, then copy its track and
challenge IDs into this directory after the first pull.

```bash
cd tracks/rust/instruqt
instruqt track validate
instruqt track push
instruqt track test
```

Before a delivery, run the smoke test inside the image (it starts its own
dev server and AdNet when none are running):

```bash
docker run --rm temporal-rust-workshop:dev bash scripts/smoke-test.sh
```

Rebuild the image whenever course code or dependencies change, and complete
one manual platform play-through.
