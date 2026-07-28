# Durable ad campaign workshops with Temporal

This repository contains three functionally equivalent versions of the
CatNip Cola workshop. Each language is a separate Instruqt track, but all
course content, exercise scaffolds, solutions, checks, images, and local
workshop material live in one repository.

| Language | Local workshop | Instruqt track | Workflow style |
|---|---|---|---|
| Python | [tracks/python](tracks/python/README.md) | [track files](tracks/python/instruqt) | decorated classes and async methods |
| TypeScript | [tracks/typescript](tracks/typescript/README.md) | [track files](tracks/typescript/instruqt) | exported async functions and typed Activity proxies |
| Java | [tracks/java](tracks/java/README.md) | [track files](tracks/java/instruqt) | annotated interfaces, implementations, and Activity stubs |

## Repository layout

```text
tracks/
├── python/
│   ├── exercises/
│   ├── instruqt/
│   └── scripts/smoke-test.sh
├── typescript/
│   ├── exercises/
│   ├── instruqt/
│   └── scripts/smoke-test.sh
└── java/
    ├── exercises/
    ├── instruqt/
    └── scripts/smoke-test.sh
```

Each `instruqt/` directory is an independent track root for
`instruqt track validate`, `push`, and `test`. Docker images are built from
the repository root because their Dockerfiles copy the matching language
directory:

```bash
docker build -f tracks/python/instruqt/Dockerfile .
docker build -f tracks/typescript/instruqt/Dockerfile .
docker build -f tracks/java/instruqt/Dockerfile .
```

The Python track retains its existing platform IDs. TypeScript and Java omit
platform-generated IDs until their remote tracks are created or duplicated;
their `DEPLOY.md` files document the first-deployment step. Replace each new
track's `REGISTRY_PLACEHOLDER` image reference before pushing it.

The local READMEs are the source for the TypeScript and Java Instruqt
assignment bodies. After editing those READMEs, sync them with:

```bash
node scripts/sync-instruqt-content.mjs typescript java
```
