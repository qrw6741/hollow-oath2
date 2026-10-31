class_name ItemData
extends Resource
## One kind of carryable item. Data-driven: add a new .tres in data/items/ and list its id
## in Items.IDS. Effects are intentionally few and generic; special behaviour (keys, lore)
## is handled by whatever checks for the item.

enum Kind { CONSUMABLE, KEY, LORE }
enum Effect { NONE, HEAL, STAMINA, EMBERS, TRAVEL, BUFF }

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var kind := Kind.CONSUMABLE
@export var effect := Effect.NONE
## Health or stamina restored, or embers granted.
@export var effect_amount := 0.0
@export var max_stack := 9
@export var icon_color := Color(0.85, 0.8, 0.7)


func is_usable() -> bool:
	return (kind == Kind.CONSUMABLE and effect != Effect.NONE) or effect == Effect.TRAVEL


func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if id == &"":
		errs.append("id is empty")
	if display_name == "":
		errs.append("display_name is empty")
	if max_stack < 1:
		errs.append("max_stack must be at least 1")
	if kind == Kind.CONSUMABLE and effect == Effect.NONE:
		errs.append("consumable has no effect")
	if effect != Effect.NONE and effect != Effect.TRAVEL and effect_amount <= 0.0:
		errs.append("effect_amount must be positive")
	return errs
