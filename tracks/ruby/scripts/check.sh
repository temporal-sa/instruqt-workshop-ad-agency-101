#!/usr/bin/env bash
# Static checks for the Ruby track.
#
# 1. Syntax-check every Ruby file with warnings enabled (`ruby -wc`).
# 2. When the gems are installed (`bundle check`), load every Workflow and
#    Activity definition file, one exercise directory per process, so a
#    misspelled SDK constant or superclass fails here instead of in class.
#
# Needs Ruby 3.3+. When the local Ruby is missing or older (for example the
# macOS system Ruby), step 1 runs inside the official Ruby image with Docker
# and step 2 is skipped.
set -euo pipefail
cd "$(dirname "$0")/.."

RUBY_IMAGE="ruby:4.0.10-slim-bookworm"

modern_ruby() {
  command -v ruby >/dev/null 2>&1 &&
    ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.3") ? 0 : 1)' 2>/dev/null
}

syntax_check() {
  local failed=0 output
  while IFS= read -r file; do
    if ! output="$(ruby -wc "$file" 2>&1)" || [ "$output" != "Syntax OK" ]; then
      echo "$file: $output" >&2
      failed=1
    fi
  done < <(find exercises -name '*.rb' -type f | sort)
  return "$failed"
}

if [ "${1:-}" = "--syntax-only" ]; then
  syntax_check
  exit
fi

if ! modern_ruby; then
  echo "==> Ruby 3.3+ not found locally; syntax-checking in $RUBY_IMAGE"
  docker run --rm -v "$PWD:/track:ro" -w /track "$RUBY_IMAGE" \
    bash scripts/check.sh --syntax-only
  echo "Ruby syntax OK (definition load check skipped: no local gems)."
  exit 0
fi

echo "==> ruby -wc"
syntax_check

if ! bundle check >/dev/null 2>&1; then
  echo "Ruby syntax OK (definition load check skipped: run 'bundle install')."
  exit 0
fi

echo "==> load Workflow and Activity definitions"
while IFS= read -r dir; do
  files=()
  for name in activities.rb workflows.rb; do
    [ -f "$dir/$name" ] && files+=("./$dir/$name")
  done
  [ "${#files[@]}" -gt 0 ] || continue
  bundle exec ruby -e 'ARGV.each { |file| require File.expand_path(file) }' "${files[@]}" \
    || { echo "failed to load $dir" >&2; exit 1; }
done < <(find exercises -name '*.rb' -type f -exec dirname {} \; | sort -u)

echo "Ruby static checks passed."
