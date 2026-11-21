# Durable ad campaign workshops with Temporal

This repository contains functionally equivalent versions of the
CatNip Cola workshop, one for every Temporal SDK. Each language is a separate Instruqt track, but all
course content, exercise scaffolds, solutions, checks, images, and local
workshop material live in one repository.

| Language | Local workshop | Instruqt track | Workflow style |
|---|---|---|---|
| Python | [tracks/python](tracks/python/README.md) | [track files](tracks/python/instruqt) | decorated classes and async methods |
| TypeScript | [tracks/typescript](tracks/typescript/README.md) | [track files](tracks/typescript/instruqt) | exported async functions and typed Activity proxies |
| Java | [tracks/java](tracks/java/README.md) | [track files](tracks/java/instruqt) | annotated interfaces, implementations, and Activity stubs |
| Go | [tracks/go](tracks/go/README.md) | [track files](tracks/go/instruqt) | plain functions and a Workflow context |
| .NET | [tracks/dotnet](tracks/dotnet/README.md) | [track files](tracks/dotnet/instruqt) | attributed classes and async Tasks |
| PHP | [tracks/php](tracks/php/README.md) | [track files](tracks/php/instruqt) | attributed interfaces and generators, run by RoadRunner |
| Ruby | [tracks/ruby](tracks/ruby/README.md) | [track files](tracks/ruby/instruqt) | Workflow and Activity subclasses |
| Rust | [tracks/rust](tracks/rust/README.md) | [track files](tracks/rust/instruqt) | async functions with macros (SDK in preview) |

## Repository layout

```text
tracks/
├── python/
│   ├── exercises/
│   ├── instruqt/
│   └── scripts/smoke-test.sh
├── typescript/
├── java/
├── go/
├── dotnet/
├── php/
├── ruby/
└── rust/
```

Every language directory has the same `exercises/`, `instruqt/`, and
`scripts/smoke-test.sh` layout as `python/`.

Each `instruqt/` directory is an independent track root for
`instruqt track validate`, `push`, and `test`. Docker images are built from
the repository root because their Dockerfiles copy the matching language
directory:

```bash
docker build -f tracks/python/instruqt/Dockerfile .
docker build -f tracks/typescript/instruqt/Dockerfile .
docker build -f tracks/java/instruqt/Dockerfile .
docker build -f tracks/go/instruqt/Dockerfile .
docker build -f tracks/dotnet/instruqt/Dockerfile .
docker build -f tracks/php/instruqt/Dockerfile .
docker build -f tracks/ruby/instruqt/Dockerfile .
docker build -f tracks/rust/instruqt/Dockerfile .
```

The Python track retains its existing platform IDs. All other tracks omit
platform-generated IDs until their remote tracks are created or duplicated;
their `DEPLOY.md` files document the first-deployment step. Replace each new
track's `REGISTRY_PLACEHOLDER` image reference before pushing it.

The local READMEs are the source for every non-Python track's Instruqt
assignment bodies. After editing those READMEs, sync them with:

```bash
node scripts/sync-instruqt-content.mjs typescript java go dotnet php ruby rust
```
