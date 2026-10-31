class_name Endings
extends RefCounted
## The three ways this chapter can close, chosen at the Oath Gate after the Marshal falls.
## Data-driven: add an entry to DEFS (and its id to ORDER). State is in world flags (no save
## change):  ending_chosen = id    ending_<id> = true
##   keep - take Orren's place and hold the road.     always open
##   break - set the oath down, as Orren did.           always open
##   mend - rewrite the last line, as Ommen once did.   needs every errand done + the Gallery opened

const MARSHAL_FLAG := &"boss_defeated_hollow_marshal"
const REGENT_FLAG := &"boss_defeated_hollow_regent"
const ETERNAL_FLAG := &"boss_defeated_the_oath_eternal"
const ORDER: Array[StringName] = [&"keep", &"break", &"mend", &"crown", &"unsworn"]
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
	&"crown": {
		"title": "Take the Crown",
		"blurb": "Wear the Hollow Crown. Rule what is left.",
		"requires": "Defeat the Hollow Regent in the Hollow Keep.",
		"pages": [
			"You carry the Hollow Crown to the gate and set it on your own head. It is lighter than a vow, and hungrier.",
			"The gate bows. Not in worship: in recognition, the way a lock knows a key that has been cut to fit it.",
			"The sworn rise in their rows and turn to face you. They do not ask what you will command. They only wait.",
			"You have a court now. It will be a long time before you learn whether it is a kindness to rule the dead.",
		],
	},
	&"unsworn": {
		"title": "Go Unsworn",
		"blurb": "Walk back up the Descent with nothing owed to anyone.",
		"requires": "Defeat the Oath Eternal in the Hollow Heart, at the bottom of the Descent.",
		"pages": [
			"At the bottom of the Descent the first oath lay still. It had been a kindness once: two people, a promise, a candle.",
			"You do not take it up and you do not break it. You carry it to the surface and set it, unopened, on the gate.",
			"The gate has nothing to hold. It opens the way a hand opens when it has stopped being a fist.",
			"The sworn walk past you into a morning that owes them nothing. You follow, owing nobody, and it is the lightest thing you have ever carried.",
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


## The gate asks once after the Marshal falls, and once more at the very end of the Descent (only the
## last ending is offered the second time) so a player who chose early can still finish the story.
static func gate_open() -> bool:
	if bool(GameState.get_flag(MARSHAL_FLAG, false)) and chosen() == &"":
		return true
	return bool(GameState.get_flag(ETERNAL_FLAG, false)) and chosen() != &"" and chosen() != &"unsworn"


static func available(id: StringName) -> bool:
	if chosen() != &"" and id != &"unsworn":
		return false   # a second asking only offers the last ending
	if id == &"crown":
		return bool(GameState.get_flag(REGENT_FLAG, false))
	if id == &"unsworn":
		return bool(GameState.get_flag(ETERNAL_FLAG, false))
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
