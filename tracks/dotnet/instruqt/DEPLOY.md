# Deploy the .NET track

This directory is one independently deployable Instruqt track. Run Instruqt
CLI commands here; build its workstation image from the repository root.

```bash
docker build --platform linux/amd64 \
  -f tracks/dotnet/instruqt/Dockerfile \
  -t <registry>/temporal-dotnet-workshop:v1 .
docker push <registry>/temporal-dotnet-workshop:v1
```

Replace `REGISTRY_PLACEHOLDER` in `config.yml` with the public registry
namespace. The new local track intentionally has no Instruqt-generated
`id`. Create or duplicate the remote track, then copy its track and
challenge IDs into this directory after the first pull.

```bash
cd tracks/dotnet/instruqt
instruqt track validate
instruqt track push
instruqt track test
```

Before a delivery, run the smoke test inside the image (it starts its own
Temporal dev server and AdNet, so it does not need host ports):

```bash
docker run --rm temporal-dotnet-workshop:dev bash scripts/smoke-test.sh
```

Rebuild the image when course code or dependencies change, and complete one
manual platform play-through.
