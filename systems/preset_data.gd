class_name PresetData
extends Resource
## A starting loadout ("origin") chosen at New Game: weapon, vitals, armour and
## handling in one data file. New presets are new .tres files — no code changes —
## plus an entry in Presets.IDS (see docs/ADDING_CONTENT.md).

enum ArmorLook { BARE, LIGHT, KNIGHT, HEAVY }
enum WeaponLook { SWORD, TWIN, SWORD_SHIELD, FISTS }

@export var id: StringName = &""
@export var display_name := ""
@export var tagline := ""
@export_multiline var description := ""
@export var weapon: WeaponData

@export_group("Vitals")
@export var max_health := 100.0
@export var max_stamina := 100.0
@export var stamina_regen := 55.0
@export var flasks := 3
@export var flask_heal := 45.0

@export_group("Armour")
@export var armor_name := ""
@export_multiline var armor_description := ""
## Multiplies all damage taken. Armour is a trade-off, not a free upgrade:
## heavier armour also slows movement (run_speed_mult).
@export var damage_taken_mult := 1.0

@export_group("Handling")
@export var run_speed_mult := 1.0
@export var dodge_stamina := 22.0
@export var parry_window_frames := 8
@export var parry_stamina := 12.0

@export_group("Look")
@export var armor_look := ArmorLook.KNIGHT
@export var weapon_look := WeaponLook.SWORD
@export var cloth_color := Color("221e28")
@export var cloth_light_color := Color("3a3442")
@export var accent_color := Color("8e1b22")
## Short strengths / drawbacks shown on the selection screen.
@export var perks: PackedStringArray = []
@export var drawbacks: PackedStringArray = []


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"":
		problems.append("missing id")
	if weapon == null:
		problems.append("%s: no weapon" % id)
	else:
		if weapon.light_combo_start == null or weapon.heavy == null or weapon.aerial == null or weapon.riposte == null:
			problems.append("%s: weapon %s is incomplete" % [id, weapon.id])
	if max_health < 1.0 or max_stamina < 1.0 or flasks < 0:
		problems.append("%s: invalid vitals" % id)
	if damage_taken_mult <= 0.0 or run_speed_mult <= 0.0:
		problems.append("%s: invalid multipliers" % id)
	if parry_window_frames < 2:
		problems.append("%s: parry window too small" % id)
	return problems
