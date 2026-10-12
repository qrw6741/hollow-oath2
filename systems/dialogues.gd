class_name Dialogues
extends RefCounted
## All spoken lines of the NPCs. A conversation is chosen by who is speaking, how many times
## the player has already talked to them (a saved world flag), and story progress.
## Each result: {"speaker": String, "lines": Array}. Call [method finish] after it was shown.

const MARSHAL_FLAG := &"boss_defeated_hollow_marshal"
const SIGIL_FLAG := &"ommen_gave_sigil"

## The hooded figure's story, one page per visit. Page 4 only opens once the Marshal is down.
const OMMEN_STORY := [
	[
		"Easy. Easy. The light is real, here - sit a moment. The oath leaves a taste in the mouth.",
		"You walked out of the Hollow. Do you know what that means? Nobody has. It was a dream the oath wove around the sworn, and you were the only one still able to wake.",
		"I keep the candles on this road. Rest at one and the oath remembers you - and I will remember to be here.",
	],
	[
		"Vaelmoor was held together by a vow. Every child of the kingdom swore it at coming of age, and a sliver of the soul went to the Crown with it. We called it the Hollow Oath. We thought 'hollow' meant 'sincere'.",
		"Then came the Night of Unbinding. The oath turned over. The sworn did not die - whatever the vow held was emptied out of them, and they went on walking.",
		"The royal records blame a plague. I was there. It was not a plague.",
	],
	[
		"My name is Ommen. I was a Candlewright, once - one of those who wrote the liturgy and kept the candles lit.",
		"Forty years before the Night, we rewrote it. I signed my name to the new words. I did not read them closely enough.",
		"You carry a Candlewright's note, I think. 'Read from its last line to its first. The sworn will not notice.' I know that hand. I would rather not say whose.",
	],
	[
		"The road runs on to the Crownless Citadel. The chancellors sealed it behind them, and something sits on the Hollow Throne that is not a king.",
		"A Marshal holds the crossroads ahead. Sir Orren swore to guard the Crown's road, and so he does, and so he will, long after there is any Crown to guard.",
		"Break him if you can. Not out of cruelty. He has been standing there a very long time.",
		"Take this. It is a Candlewright's sigil - the seal we pressed on letters we never meant the Crown to read.",
		"Hold it up and the oath will fold the road. It will carry you to Hollowmere Manor, where the last of us have gathered - and, used there, back to the very spot you left. Use it from your pack.",
	],
]
const OMMEN_SIGIL_LATE := [
	"I nearly forgot. I meant to give you this, the last time.",
	"A Candlewright's sigil. Hold it up and the oath folds the road: it carries you to Hollowmere Manor, where the last of us have gathered, and brings you back to the spot you left. Use it from your pack.",
]
const OMMEN_AFTER_MARSHAL := [
	"The crossroads are quiet. I heard the banner fall from here.",
	"Orren's oath is broken. That is all it takes, I think - one vow, set down by someone who still can. You did that.",
	"The Citadel gate will not open yet. Not for you, and not for me. Go carefully when it does.",
]
const OMMEN_IDLE := [
	"The candles are still lit. That is something.",
	"Rest when you can. The oath remembers those who rest.",
	"I have been counting the days since the Night. I lost the number somewhere in the second year.",
]

const WENNA_FIRST := [
	"Ha! A customer! A living one, even, by the look of you - the hollow ones never haggle.",
	"Wenna. Pedlar. I walk the road because someone has to, and because the road is the only thing in Vaelmoor that still pays.",
	"I take embers. I do not ask where you got them. Look, buy, and mind the crows.",
]
const WENNA_GREETINGS := [
	"Back again! Embers talk louder than oaths.",
	"Careful out there. I like my regulars alive.",
	"Whatever you are carrying, I have something that will carry it better.",
	"Business is slow. The dead are poor customers.",
]

const HOBB_FIRST := [
	"Mind the sparks. Hobb. I was a farrier, then a smith for the garrison, and now I'm a smith for whoever is still walking.",
	"Bring me Forge Scrap - anything broken and iron, the hollow knights drop plenty - and embers for the coal, and I'll make your steel better. Blade, plate, anything.",
	"Bring me a relic of something great that you've killed, and I'll make something new from it. I only need to see it. I'd never take a thing like that from you.",
]
const HOBB_GREETINGS := [
	"Fire's hot. Make it count.",
	"Steel remembers every hand that held it. Treat it kindly and it'll give you more.",
	"A good edge won't save a bad swing. But it helps.",
	"Armour doesn't make you brave. It makes you stay in the fight a little longer.",
]
const ALDOUS_FIRST := [
	"Good evening. Or morning; time keeps poor manners in this house. I am Aldous Vane, steward of Hollowmere - and, as you will have noticed, rather dead.",
	"The house was the Dowager's, then the Candlewrights', then nobody's. The Night emptied the halls and the oath filled them again with those who could not leave. You will find them gentle. Mostly.",
	"Mr. Hobb has taken the forge, Sister Ilse the conservatory, and Mistress Wenna insists on the hall, 'for trade'. Ser Ommen keeps the candle. The door by the stair returns you wherever you came from. The Gallery, at the far end, is sealed; the house has not yet decided who is to be let in.",
]
const ALDOUS_GREETINGS := [
	"The house keeps itself, mostly. I merely supervise the dust.",
	"You carry the road on your boots. Wipe them, or do not. I am past minding.",
	"Should you tire of the house, the sigil will return you exactly where you left. Exactly. I checked.",
	"The portraits have opinions of you. I would not ask what they are.",
]
const ALDOUS_AFTER_MARSHAL := [
	"Sir Orren has fallen? How very sad. I served with his grandfather's steward. If you meet the Marshal's ghost, tell him the cellar key is under the third flagstone. He always forgot.",
]
const ILSE_FIRST := [
	"Peace, traveller. I am Sister Ilse. I keep the vials.",
	"The Ember Vials are older than the Night - the Candlewrights taught us to bottle the last warmth of a fire. They keep faith better than we did.",
	"Bring me Hollow Resin and embers, and I will teach your vials to hold more, and to give more. Do not ask how the resin is gathered. It does not hurt anyone who is still alive.",
]
const ILSE_GREETINGS := [
	"May your vials never run dry.",
	"A little warmth is enough. It always was.",
	"The Resin grows brighter when the candles are lit. I like to think they are talking.",
]

## What the prompt calls them: the stranger gives his name on the third talk.
static func display_name(npc: StringName, fallback: String) -> String:
	if npc == &"ommen" and talks(npc) >= 2:
		return "Ommen"
	return fallback


static func talks(npc: StringName) -> int:
	return int(GameState.get_flag(StringName("talks_" + String(npc)), 0))


static func conversation(npc: StringName) -> Dictionary:
	var n := talks(npc)
	match npc:
		&"ommen":
			var marshal_down := bool(GameState.get_flag(MARSHAL_FLAG, false))
			var speaker := "Hooded Figure" if n < 2 else "Ommen"
			var lines: Array
			if marshal_down and not bool(GameState.get_flag(&"ommen_heard_after", false)):
				lines = OMMEN_AFTER_MARSHAL
				speaker = "Ommen"
			elif n < OMMEN_STORY.size():
				lines = OMMEN_STORY[n]
			elif not bool(GameState.get_flag(SIGIL_FLAG, false)):
				lines = OMMEN_SIGIL_LATE
			else:
				lines = [OMMEN_IDLE[(n - OMMEN_STORY.size()) % OMMEN_IDLE.size()]]
			return {"speaker": speaker, "lines": lines}
		&"wenna":
			var lines2: Array = WENNA_FIRST if n == 0 else [WENNA_GREETINGS[(n - 1) % WENNA_GREETINGS.size()]]
			return {"speaker": "Wenna", "lines": lines2}
		&"hobb":
			return {"speaker": "Hobb", "lines": HOBB_FIRST if n == 0 else [HOBB_GREETINGS[(n - 1) % HOBB_GREETINGS.size()]]}
		&"ilse":
			return {"speaker": "Sister Ilse", "lines": ILSE_FIRST if n == 0 else [ILSE_GREETINGS[(n - 1) % ILSE_GREETINGS.size()]]}
		&"aldous":
			var lines3: Array
			if n == 0:
				lines3 = ALDOUS_FIRST
			elif bool(GameState.get_flag(MARSHAL_FLAG, false)) and not bool(GameState.get_flag(&"aldous_heard_marshal", false)):
				lines3 = ALDOUS_AFTER_MARSHAL
			else:
				lines3 = [ALDOUS_GREETINGS[(n - 1) % ALDOUS_GREETINGS.size()]]
			return {"speaker": "Aldous Vane", "lines": lines3}
	return {"speaker": "...", "lines": ["..."]}


## Records that the conversation happened (advances the story).
static func finish(npc: StringName) -> void:
	if npc == &"ommen" and bool(GameState.get_flag(MARSHAL_FLAG, false)) and not bool(GameState.get_flag(&"ommen_heard_after", false)):
		GameState.set_flag(&"ommen_heard_after", true)
		return
	if npc == &"aldous" and bool(GameState.get_flag(MARSHAL_FLAG, false)) and talks(npc) > 0 and not bool(GameState.get_flag(&"aldous_heard_marshal", false)):
		GameState.set_flag(&"aldous_heard_marshal", true)
		return
	if npc == &"ommen" and talks(npc) >= 3 and not bool(GameState.get_flag(SIGIL_FLAG, false)):
		GameState.set_flag(SIGIL_FLAG, true)
		GameState.add_item(&"hollow_sigil", 1)
	GameState.set_flag(StringName("talks_" + String(npc)), talks(npc) + 1)
