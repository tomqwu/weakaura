# Rogue — All Specs HUD (v40)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(pips + health/energy/threat with 35/40 threshold lines), Procs, Cooldowns.

`generate.lua` is the historical iteration script (v1→v40 patch lineage). It expects the
original workspace (decoded schema template, prior-version strings for UID continuity checks,
LibDeflate/LibSerialize alongside). For new work, build through
`../../tools/tbc-weakaura-creator/` instead — same machinery, cleaned up.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.
