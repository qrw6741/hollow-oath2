class_name Loadout
extends RefCounted
## Equipping: which weapon and armour the character uses right now, and how that turns into
## player numbers and a drawn look. State lives in GameState (and the save file); this class is
## the rules. Taking armour off is wearing Armors.NONE.


## Fills in a starting loadout when there is none (new game, old saves, tests).
static func ensure(preset: PresetData) -> void:
	if preset == null:
		return
	if GameState.weapons.is_empty():
		var w := preset.weapon.id if preset.weapon else &"fists"
		GameState.weapons = {String(w): 0}
		GameState.weapon_id = w
	if GameState.armors.is_empty() and GameState.armor_id == &"":
		if Armors.is_valid_id(String(preset.id)):
			GameState.armors = {String(preset.id): 0}
			GameState.armor_id = preset.id
		else:
			GameState.armor_id = Armors.NONE
	if not GameState.weapons.has(String(GameState.weapon_id)):
		GameState.weapon_id = StringName(GameState.weapons.keys()[0])
	if GameState.armor_id != Armors.NONE and not GameState.armors.has(String(GameState.armor_id)):
		GameState.armor_id = Armors.NONE if GameState.armors.is_empty() else StringName(GameState.armors.keys()[0])


static func equip_weapon(id: StringName) -> bool:
	if not GameState.owns_weapon(id) or id == GameState.weapon_id:
		return false
	GameState.weapon_id = id
	Events.loadout_changed.emit()
	return true


## Wears an owned armour, or Armors.NONE to take it all off.
static func equip_armor(id: StringName) -> bool:
	if id != Armors.NONE and not GameState.owns_armor(id):
		return false
	if id == GameState.armor_id:
		return false
	GameState.armor_id = id
	Events.loadout_changed.emit()
	return true


static func weapon() -> WeaponData:
	return Weapons.get_weapon(GameState.weapon_id)


## Damage multiplier from the weapon's upgrade level.
static func weapon_mult() -> float:
	var w := weapon()
	return Weapons.level_mult(GameState.weapon_level(GameState.weapon_id)) * (w.damage_mult if w else 1.0)


static func damage_taken_mult() -> float:
	return Armors.damage_mult(GameState.armor_id, GameState.armor_level(GameState.armor_id))


## A copy of the preset with the equipped weapon and armour's looks: what is drawn.
static func compose_look(preset: PresetData) -> PresetData:
	var l := preset.duplicate() as PresetData
	var w := weapon()
	if w:
		l.weapon = w
		l.weapon_look = w.look
	var a := Armors.get_armor(GameState.armor_id)
	if a:
		l.armor_look = a.look
		l.cloth_color = a.cloth_color
		l.cloth_light_color = a.cloth_light_color
		l.accent_color = a.accent_color
		l.armor_name = a.display_name
		l.armor_description = a.description
	else:
		l.armor_look = PresetData.ArmorLook.BARE
		l.cloth_color = Color("6b4a3a")
		l.cloth_light_color = Color("8a6a52")
		l.accent_color = Color("d9d0bc")
		l.armor_name = "Nothing"
		l.armor_description = "No armour at all. Quick on your feet, and every blow lands in full."
	return l
