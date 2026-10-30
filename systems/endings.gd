class_name Endings
extends RefCounted
## The three ways this chapter can close, chosen at the Oath Gate after the Marshal falls.
## Data-driven: add an entry to DEFS (and its id to ORDER). State is in world flags (no save
## change):  ending_chosen = id    ending_<id> = true
##   keep - take Orren's place and hold the road.     always open
##   break - set the oath down, as Orren did.           always open
##   mend - rewrite the last line, as Ommen once did.   needs every errand done + the Gallery opened

const MARSHAL_FLAG := &"boss_defeated_hollow_marshal"
const ORDER: Array[StringName] = [&"keep", &"break", &"mend"]
const DEFS := {
	&"keep": {
		"title": "Keep the Oath",
		"blurb": "Take up the lance. Someone must hold the road.",
		"pages": [
			"You lift Orren's lance from the dust and the gate, hearing you, grows still.",
			"The oath tightens like a hand around a wrist. It is not cruel. It is only certain.",
			"The road is held. The candles burn steady. The sworn stand in their rows and are never, quite, alive.",
			"Vaelmoor keeps its order. Behind you, the Citadel waits for the next one who can still choose.",
		],
	},
	&"break": {
		"title": "Break the Oath",
		"blurb": "Set the vow down. Let what it holds go free.",
		"pages": [
			"You lay your hand on the cracked mark and, as Orren did, put the vow down.",
			"It does not shatter. It simply stops being carried. All along the road, something unclenches.",
			"The sworn sit down where they stand. The candles gutter, and for the first time in years the dark is only dark.",
			"It is a cold dawn. It is also a real one.",
		],
	},
	&"mend": {
		"title": "Mend the Oath",
		"blurb": "Rewrite the struck line. Ommen's hand, and yours.",
		"requires": "Finish every errand and open the Gallery to read the Last Draft.",
		"pages": [
			"You speak the liturgy aloud, and where the page was struck through you do not repeat the old line.",
			"You say the one Ommen wrote in the margin forty years too late: that the oath is owed both ways.",
			"The gate hears it. The candles do not go out. The sworn do not fall. They look up.",
			"Something that was a chain becomes a promise. It will take a long time to know the difference. You have, finally, the time.",
		],
	},
}


static func chosen() -> StringName:
	return StringName(str(GameState.get_flag(&"ending_chosen", "")))


static func gate_open() -> bool:
	return bool(GameState.get_flag(MARSHAL_FLAG, false)) and chosen() == &""


static func available(id: StringName) -> bool:
	if id != &"mend":
		return DEFS.has(id)
	for q in Quests.ORDER:
		if Quests.state(q) != "done":
			return false
	return bool(GameState.get_flag(&"door_open_hollowmere_gallery", false))


static func reason(id: StringName) -> String:
	return "" if available(id) else String(DEFS[id].get("requires", ""))


## Locks in the choice. Returns false if the gate is not open or the choice is not available.
static func choose(id: StringName) -> bool:
	if not gate_open() or not available(id):
		return false
	GameState.set_flag(&"ending_chosen", String(id))
	GameState.set_flag(StringName("ending_" + String(id)), true)
	Events.ending_chosen.emit(id)
	Deeds.check_all()
	return true
