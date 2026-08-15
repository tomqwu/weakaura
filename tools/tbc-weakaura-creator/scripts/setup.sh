#!/bin/bash
# Fetch the two libraries WeakAuras uses for import strings + ensure lua5.1.
#
# These libraries are load-bearing for reproducibility: LibSerialize + LibDeflate ARE
# the encoder, so a different revision can change the bytes of every shipped string and
# make verify-rebuild.sh fail for reasons that have nothing to do with this repo. They
# are therefore pinned by CONTENT (sha256), not by branch — a moving `main` was the
# original mistake, and it left the exact revision that built every shipped string
# unrecorded.
#
# To upgrade deliberately: fetch the new file, run the full suite, and if every string
# still reproduces byte-for-byte, update the checksum here in the same commit.
set -euo pipefail
cd "$(dirname "$0")"

command -v lua5.1 >/dev/null || apt-get install -y -qq lua5.1

# file | sha256 of the revision every committed string was built with | url
LIBS=(
  "LibDeflate.lua|880e396fbaac7dcf99d33fc706a7f129147f2910f8414a143f8dea57e327c06b|https://raw.githubusercontent.com/SafeteeWoW/LibDeflate/main/LibDeflate.lua"
  "LibSerialize.lua|c20514a330b1d0b5bd41ddb0fa6fc2b3395a35de0c9a2ef84a7df27554a4ed64|https://raw.githubusercontent.com/rossnichols/LibSerialize/main/LibSerialize.lua"
)

for entry in "${LIBS[@]}"; do
  IFS='|' read -r file want url <<< "$entry"

  if [ ! -f "$file" ]; then
    # -f makes curl fail on HTTP errors instead of writing the error page to the file.
    # Without it a 404 page was saved AS LibDeflate.lua and setup still printed "ok",
    # so the first real failure surfaced much later as an inscrutable Lua error.
    if ! curl -fsSL -o "$file" "$url"; then
      echo "setup FAILED: could not download $file from $url" >&2
      rm -f "$file"
      exit 1
    fi
  fi

  got="$(sha256sum "$file" | cut -d' ' -f1)"
  if [ "$got" != "$want" ]; then
    echo "setup FAILED: $file checksum mismatch" >&2
    echo "  expected $want" >&2
    echo "  got      $got" >&2
    echo "  Upstream moved, or the file is corrupt. The shipped strings were built with" >&2
    echo "  the expected revision; encoding with a different one can change every byte." >&2
    echo "  Delete $file to re-fetch, or update the pin here after re-running the suite." >&2
    exit 1
  fi
done

echo "setup ok: $(lua5.1 -v 2>&1 | head -1); libraries match their pinned checksums"
