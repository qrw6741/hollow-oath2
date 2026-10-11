class_name Dialogues
extends RefCounted
## All spoken lines of the NPCs. A conversation is chosen by who is speaking, how many times
## the player has already talked to them (a saved world flag), and story progress.
## Each result: {"speaker": String, "lines": Array}. Call [method finish] after it was shown.

const MARSHAL_FLAG := &"boss_defeated_hollow_marshal"

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
	],
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
			else:
				lines = [OMMEN_IDLE[(n - OMMEN_STORY.size()) % OMMEN_IDLE.size()]]
			return {"speaker": speaker, "lines": lines}
		&"wenna":
			var lines2: Array = WENNA_FIRST if n == 0 else [WENNA_GREETINGS[(n - 1) % WENNA_GREETINGS.size()]]
			return {"speaker": "Wenna", "lines": lines2}
	return {"speaker": "...", "lines": ["..."]}


## Records that the conversation happened (advances the story).
static func finish(npc: StringName) -> void:
	if npc == &"ommen" and bool(GameState.get_flag(MARSHAL_FLAG, false)) and not bool(GameState.get_flag(&"ommen_heard_after", false)):
		GameState.set_flag(&"ommen_heard_after", true)
		return
	GameState.set_flag(StringName("talks_" + String(npc)), talks(npc) + 1)
