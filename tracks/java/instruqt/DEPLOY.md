# Deploy the Java track

This directory is one independently deployable Instruqt track. Run Instruqt
CLI commands here; build its workstation image from the repository root.

```bash
docker build --platform linux/amd64 \
  -f tracks/java/instruqt/Dockerfile \
  -t <registry>/temporal-java-workshop:v1 .
docker push <registry>/temporal-java-workshop:v1
```

Replace `REGISTRY_PLACEHOLDER` in `config.yml` with the public registry
namespace. The new local track intentionally has no Instruqt-generated
`id`. Create or duplicate the remote track, then copy its track and
challenge IDs into this directory after the first pull.

```bash
cd tracks/java/instruqt
instruqt track validate
instruqt track push
instruqt track test
```

Before a delivery, run `tracks/java/scripts/smoke-test.sh`, rebuild the
image when course code or dependencies change, and complete one manual
platform play-through.
