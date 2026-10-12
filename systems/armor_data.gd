class_name ArmorData
extends Resource
## One wearable armour. Data-driven: add a .tres in data/armors/ and list its id in
## Armors.IDS. Armour is a trade-off, never a free upgrade: heavier armour takes less damage
## but slows the stride and makes dodging cost more stamina. Each upgrade level
## (see Forge) shaves a little more off the damage taken.

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var look := PresetData.ArmorLook.KNIGHT
## Multiplies all damage taken at level 0.
@export var damage_taken_mult := 1.0
@export var run_speed_mult := 1.0
## Status resistance by kind, e.g. {"bleed": 0.4} (see Status).
@export var resist := {}
## Added to the character's dodge stamina cost (negative = cheaper).
@export var dodge_stamina_add := 0.0
@export var cloth_color := Color("221e28")
@export var cloth_light_color := Color("3a3442")
@export var accent_color := Color("8e1b22")


func validate() -> PackedStringArray:
	var p := PackedStringArray()
	if id == &"":
		p.append("armor has no id")
	if display_name == "":
		p.append("%s: no name" % id)
	if damage_taken_mult <= 0.0 or run_speed_mult <= 0.0:
		p.append("%s: invalid multipliers" % id)
	return p
