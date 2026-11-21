#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for language in python typescript java go dotnet php ruby rust; do
  echo "==> validating Instruqt track: $language"
  (
    cd "tracks/$language/instruqt"
    instruqt track validate
  )
done

echo "==> checking Instruqt assignment interactions"
node scripts/validate-instruqt-ux.mjs

echo "==> checking TypeScript"
(
  cd tracks/typescript
  npm run check
)

echo "==> checking Go"
(
  cd tracks/go
  test -z "$(gofmt -l .)"
  go vet ./...
  go build ./...
)

echo "==> checking .NET"
(
  cd tracks/dotnet
  dotnet build CatNipCola.Workshop.slnx -nologo -v quiet
)

echo "==> checking PHP (in Docker)"
docker run --rm -v "$PWD/tracks/php:/src:ro" composer:2.11.1 sh -c \
  'cp -r /src /tmp/app && cd /tmp/app \
   && composer install -q --no-progress --ignore-platform-req=ext-sockets \
   && php scripts/check.php'

echo "==> checking Ruby"
tracks/ruby/scripts/check.sh

echo "==> checking Rust"
(
  cd tracks/rust
  cargo check --locked --bins
)

echo "All local structural checks passed."
