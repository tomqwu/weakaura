# Agent workflow

Rules for AI coding agents (GitHub Copilot, Claude Code, ChatGPT/Codex) working in this repo.
Kept byte-identical across `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` —
edit all three together.

Every change — packs, toolkit, docs — follows branch → test → commit → push → merge. Never
commit directly on `main`.

1. **Branch** off up-to-date `main` before touching anything:
   `git checkout -b <area>/<short-desc>` (examples: `rogue/v42-energy-ticks`,
   `toolkit/aurabar-schema`, `docs/readme`).
2. **Build, don't hand-edit**: `!WA:2!` import strings are only ever produced by Lua build
   scripts through `tools/tbc-weakaura-creator/scripts/wa_lib.lua` (run `setup.sh` there once
   to fetch LibDeflate/LibSerialize; needs lua5.1).
3. **Test before every commit** — for every changed import string, with lua5.1:
   - `wa_lib.verify(transmit, encoded)` — round-trip fidelity, unique ids/uids, parent refs
     resolve, controlledChildren complete.
   - `wa_lib.uidContinuity(encoded, <last committed string>)` — existing auras must keep 100%
     stable UIDs (the in-game Update flow depends on it); new auras append new `uid()` calls,
     never reorder existing ones.
   - Version numbers and feature wording in the root `README.md`, the pack `README.md`, and
     the pack's `generate.lua` lineage script match the shipped string.
   - Every pack `README.md` ends with an `## Import string (vN)` section embedding the
     current string in a plain fenced code block (GitHub's copy button is the quick-copy
     path), byte-identical to the shipped `.txt`; the root `README.md` "Import strings"
     table lists every pack's current version and links to that block.
4. **Commit** on the branch: one logical change per commit, message `<area>: <what>`
   (e.g. `rogue: v41 — combo pip green→orange gradient`), with the string, lineage script,
   and docs in the same commit.
5. **Push** the branch to `origin`, **merge to `main`** (PR when collaborating; otherwise a
   local `--no-ff` merge), push `main`, then delete the branch. `main` must only ever contain
   verified strings.
