# Import-string encoding, envelope, and UID mechanics

## Pipeline (exact WeakAuras Transmission.lua behavior)

```
table  --LibSerialize:SerializeEx({errorOnUnserializableType=false})-->
bytes  --LibDeflate:CompressDeflate({level=9})-->
bytes  --LibDeflate:EncodeForPrint-->  "!WA:2!" .. printable
```
Decode is the mirror (strip prefix, DecodeForPrint, DecompressDeflate, Deserialize).
`wa_lib.lua` implements both; always round-trip your own output (`W.verify`).

## Transmit envelope

```lua
{ m = "d", d = <top-level aura table>, c = { <children...> }, v = <version>, s = "3.5.0" }
```

- **v = 1421** — flat/legacy: one group with direct children. `parent` and
  `controlledChildren` are STRIPPED from every table; on import WA rebuilds them from the
  ORDER of `c`. Fine for simple single-level packs.
- **v = 2000** — nested groups (what this skill uses): `parent` and `controlledChildren`
  are KEPT on every table and must be consistent; `c` lists all descendants depth-first
  (walk the top group's controlledChildren, recursing). `F.assemble` does this and
  `W.verify` checks the wiring.
- `s` is informational (WA version string of the exporter). Keep "3.5.0" to match
  internalVersion 45.
- Strip wago metadata (`wagoID`, `url`, `semver`, `version`) from anything derived from a
  wago import, or the Companion app will think your pack is that wago entry.

## Per-aura required scaffolding

Every aura table carries: `id` (unique string), `uid` (11 chars), `regionType`,
`internalVersion = 45`, `tocversion = 20501`, `triggers`, `load`, `actions`, `animation`,
`conditions`, `config`, `authorOptions`, `information`, anchoring fields. The factories
fill all of this; missing region-specific fields are back-filled by WA's defaults on import,
but the scaffolding set must be present.

## UID discipline (what makes iteration painless)

- UID = 11 chars of `[a-zA-Z0-9()]`. WA matches auras across imports BY UID: same UID ⇒
  "Update" flow (in-place upgrade, dragged positions preservable); different UID ⇒ duplicate.
- Deterministic generation: `math.randomseed(<fixed pack seed>)` at the top of the build
  script, then `W.uid()` calls in a stable order. Between versions: never remove or reorder
  existing `uid()` calls; new auras consume NEW calls appended after all existing ones.
  Restructuring (re-parenting, renaming, resizing) is free — only the uid() CALL ORDER
  is sacred.
- `W.uidContinuity(newString, prevFile)` reports stable/changed counts — `changed` must be 0.
  (Renamed auras show as neither: matched by the new id failing lookup — that's fine, the
  UID itself carried over; eyeball those cases.)
