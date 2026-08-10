#!/bin/bash
# Fetch the two libraries WeakAuras uses for import strings + ensure lua5.1
set -e
cd "$(dirname "$0")"
command -v lua5.1 >/dev/null || apt-get install -y -qq lua5.1
[ -f LibDeflate.lua ] || curl -sL -o LibDeflate.lua https://raw.githubusercontent.com/SafeteeWoW/LibDeflate/main/LibDeflate.lua
[ -f LibSerialize.lua ] || curl -sL -o LibSerialize.lua https://raw.githubusercontent.com/rossnichols/LibSerialize/main/LibSerialize.lua
echo "setup ok: $(lua5.1 -v 2>&1 | head -1)"
