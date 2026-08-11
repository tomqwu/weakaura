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

# build script -> shipped string, relative to the repo root
PACKS="
tbc/paladin/generate.lua:tbc/paladin/tank-starter.txt
tbc/paladin/generate-all-specs.lua:tbc/paladin/all-specs.txt
tbc/druid/generate.lua:tbc/druid/all-specs.txt
tbc/warlock/generate.lua:tbc/warlock/all-specs.txt
tbc/hunter/generate.lua:tbc/hunter/all-specs.txt
tbc/priest/generate.lua:tbc/priest/all-specs.txt
tbc/mage/generate.lua:tbc/mage/all-specs.txt
"
# NB: tbc/rogue/generate.lua is the historical v1->v41 iteration script and needs the
# original workspace (dump.lua, prior-version strings); it is intentionally not rebuilt
# here. tbc/rogue/all-specs.txt is covered by tools/verify-packs.lua.

fails=0
for entry in $PACKS; do
  script="${entry%%:*}"
  shipped="${entry##*:}"
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
done

if [ "$fails" -ne 0 ]; then
  echo ""
  echo "FAIL: $fails pack(s) do not reproduce from their build scripts"
  exit 1
fi
echo ""
echo "PASS: every shipped string reproduces byte-for-byte from its committed script"
