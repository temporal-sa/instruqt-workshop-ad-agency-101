#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for language in python typescript java; do
  echo "==> validating Instruqt track: $language"
  (
    cd "tracks/$language/instruqt"
    instruqt track validate
  )
done

echo "==> checking TypeScript"
(
  cd tracks/typescript
  npm run check
)

echo "All local structural checks passed."
