Checks the EXPORTED build (not the source project): `godot --export-pack "Windows Desktop" /tmp/x.pck` then
`godot --headless --main-pack /tmp/x.pck res://tools/pack_diag/diag.tscn`. tools/ is normally excluded from exports, so
temporarily allow it (export_presets exclude_filter) when running this. It found that a PackedStringArray export on the puzzle gate
loaded empty in exported builds (gates could never open).
