class_name Jutsu
extends RefCounted
## Jutsu: a special weapon's own technique. A weapon with a `jutsu` id uses it on the Art button
## (U / left trigger) instead of the equipped Art, for focus [member WeaponData.jutsu_cost].
## Data only here; each is performed by Player._cast_jutsu().

const DEFS := {
	&"amaterasu": {"title": "Amaterasu", "kind": "black_flames",
		"desc": "Black flames burst from the ground around you and keep burning whatever stands in them."},
}


static func has(id: StringName) -> bool:
	return DEFS.has(id)


static func title(id: StringName) -> String:
	return String(DEFS.get(id, {}).get("title", ""))
