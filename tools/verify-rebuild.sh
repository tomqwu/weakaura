#!/bin/bash
# verify-rebuild.sh — prove every shipped import string is reproducible from its
# committed build script, without touching the working tree.
#
# Copies tbc/ into a sandbox, symlinks tools/, re-runs each generate script there,
# and diffs the regenerated strings against the committed ones. A mismatch means
# either the script is non-deterministic or the shipped string was not built from it.
#
# Run: tools/verify-rebuild.sh   (from the repo root, after
#      tools/tbc-weakaura-creator/scripts/setup.sh)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

cp -r "$ROOT/tbc" "$SANDBOX/tbc"
ln -s "$ROOT/tools" "$SANDBOX/tools"

fails=0
count=0
while IFS= read -r shipped; do
  script="${shipped%/*}/generate.lua"
  count=$((count + 1))
  if [ ! -f "$ROOT/$script" ]; then
    echo "  ! missing build script $script"; fails=$((fails + 1)); continue
  fi
  if ! out="$(cd "$SANDBOX" && lua5.1 "$SANDBOX/$script" 2>&1)"; then
    echo "  ! $script failed to run:"; echo "$out" | sed 's/^/      /'
    fails=$((fails + 1)); continue
  fi
  if cmp -s "$SANDBOX/$shipped" "$ROOT/$shipped"; then
    printf '  %-40s reproduces %s\n' "$script" "$shipped"
  else
    echo "  ! $script output differs from committed $shipped"
    fails=$((fails + 1))
  fi
done < <(find "$ROOT/tbc" -mindepth 2 -maxdepth 2 -type f -name all-specs.txt \
  -printf 'tbc/%P\n' | sort)

if [ "$count" -eq 0 ]; then
  echo "  ! no tbc/*/all-specs.txt packs discovered"
  fails=$((fails + 1))
fi

if ! out="$(cd "$ROOT" && lua5.1 tools/test-wa-lib.lua 2>&1)"; then
  echo "  ! verifier negative tests failed:"; echo "$out" | sed 's/^/      /'
  fails=$((fails + 1))
else
  echo "  tools/test-wa-lib.lua                    rejects malformed history/structure"
fi

if ! out="$(cd "$ROOT" && lua5.1 tools/spec-preview.lua 2>&1)"; then
  echo "  ! profile-aware spec audit failed:"; echo "$out" | sed 's/^/      /'
  fails=$((fails + 1))
else
  echo "  tools/spec-preview.lua                   validates explicit build profiles"
fi

if [ "$fails" -ne 0 ]; then
  echo ""
  echo "FAIL: $fails pack(s) do not reproduce from their build scripts"
  exit 1
fi
echo ""
echo "PASS: all $count discovered strings reproduce byte-for-byte from their committed scripts"
