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
	"The gate at the end of the road has woken, but it is not ready to ask anything yet. The story is not finished, and neither is the road: there is more of it, down under the chapel and past the Citadel.",
]
const OMMEN_IDLE := [
	"The candles are still lit. That is something.",
	"Rest when you can. The oath remembers those who rest.",
	"I have been counting the days since the Night. I lost the number somewhere in the second year.",
]

const PELL_FIRST := [
	"Oh! You are dry. Nobody comes down the stair dry. Sit if you like - it is only the floor that is wet.",
	"I dive the Reliquary for what the water has not finished with. Candle-ends, coin, now and then a saint's finger. I sell what I bring up.",
]
const PELL_GREETINGS := [
	"Mind the ripples that have no wind behind them.",
	"The Abbot's bell rings under the water on still nights. I stopped counting the strokes.",
	"If you hear singing from the wall, do not answer it. It likes to be answered.",
]

const HESK_FIRST := [
	"Quiet. Please. Vess counted us every hour for eleven years, and I am not sure she has stopped, even now.",
	"I was a mason. They put me in a cell I had built myself. I knew which stone was loose and I never touched it. Do not ask me why.",
]
const HESK_GREETINGS := [
	"The cell door is open. I keep checking that it is still open.",
	"Brand cast the chains but he never asked who they were for. I think that was kindness, of a sort.",
	"The Regent's court is full. Do not look at them for long. They look back.",
]

const LANTERN_FIRST := [
	"Evening. Or morning, if you are being generous. I walk the road when the sun is off it. Someone should.",
	"I sell what the dark leaves lying about. The prices are lower at night. Nobody is looking, you see.",
]
const LANTERN_GREETINGS := [
	"Mind the light. It likes you more than it likes me.",
	"I was a lamplighter once. I still am, really. It is only that the lamps went out first.",
	"Dawn comes and I go. You never see me in daylight. Do not take it personally.",
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

## What these four say when you find them in Hollowmere Manor (instead of their road lines).
const MANOR_GREETINGS := {
	&"ommen": [
		"It is strange to sit by a candle that nobody needs to guard. I keep forgetting that.",
		"Aldous insists on formal dinners. There is nothing to eat. We sit anyway. It helps.",
		"The house remembers every Candlewright who ever slept under this roof. Some nights I can hear them rehearsing.",
		"You came back. That is all I ever hope for, when you leave.",
	],
	&"wenna": [
		"Trade in a haunted manor! The ghosts are slow payers, but they never haggle.",
		"I have hung my beads from the chandelier. Aldous pretends not to notice.",
		"Wenna's Hall - I had a sign painted. The painter was already dead, so he did it for free.",
		"The road is hungry. The house is full. I prefer the house.",
	],
	&"hobb": [
		"Best forge I ever had. The chimney draws like a dream. Don't ask what feeds it.",
		"The old Dowager's armour hangs in the hall. I've been itching to take it apart and see how it was made.",
		"Quiet here. Too quiet. I keep tapping the anvil to hear something that answers.",
		"Anything you break out there, bring it in. The house makes a good listener for hammering.",
	],
	&"ilse": [
		"The conservatory still blooms. Nothing that grows here has ever seen sunlight. They are lovely anyway.",
		"The ghosts come to warm their hands at the vials. I have not the heart to send them off.",
		"Aldous says the house will let someone into the Gallery when it has decided. I think the house is waiting for a particular kind of courage.",
		"Out there the oath hurts. In here, it only aches. That is a mercy, of a kind.",
	],
}

## What the archivist says about things you carry. Each is explained once.
const ARCHIVE := {
	&"candlewright_note": "The Note. I filed the original, you know - or its twin. 'Read from the last line to the first.' They did not even disguise it. We were so sure no one would ever check.",
	&"penitents_tear": "A penitent's tear: wax and salt. The sworn weep when the oath turns on them - the only sign left that someone is still inside. Do not be moved. Be quick.",
	&"canon_seal": "The Canon's seal. Seals like this closed the Candlewright vaults. Whoever wore it was trusted with the final copy of the liturgy - the one that was never burned.",
	&"warden_bell_shard": "A piece of the Warden's bell. It rang for every vow sworn in Vaelmoor, three hundred years running. It cracked on the Night, the way a throat cracks after a scream.",
	&"marshals_crest": "Orren's crest. The Marshal is in the records as 'faithful beyond reason'. I never understood why that was a compliment.",
	&"rusted_key": "An old cellar key, I think. Every manor has one nobody can match to a door. Keep it. Doors turn up.",
	&"hollow_sigil": "The sigil! Candlewrights pressed these on letters they never meant the Crown to read. It was clever of Ommen to turn a seal into a road.",
	&"gallery_key": "The Gallery key. You went down there and came back up. Few do. The cellarer was an excellent butler, you know, before the Night. He just never learned when to stop serving.",
	&"cinder_heart": "Mother Cinder's heart. I confess I did not think it could be taken from her. Give it to Hobb. A coal like that should be a sword, not a vigil.",
	&"ashfall_seal": "An Ashfall seal. He was the only guardsman who ever refused to swear in my hearing. I told him it would cost him everything. He said that was the point.",
	&"relic_locket": "A Hollow Locket. They were handed out at funerals so the dead would not be forgotten. It remembers, if you hold it while you fight.",
	&"relic_thorn": "The Widow's Thorn. It was worn by someone who held a grudge for forty years. It shows.",
	&"relic_knot": "A Penitent's Knot. One knot per vow kept. This one has a great many.",
	&"relic_coin": "A gravedigger's coin. He charged both the living and the dead, and the dead were better payers.",
	&"relic_candle": "A Candle Stub. Tallow that refuses to finish. It reminds me of Ommen.",
	&"relic_riposte": "A Duellist's Glove. Whoever left this in my Gallery taught fencing, I suspect, to people who would not use it politely.",
	&"relic_shackle": "Vess's shackle. Every cell in the Keep had a ledger; hers had one entry, repeated. I would not wear it for comfort. It is, however, very good at not being moved.",
	&"relic_slag": "A foundry ladle. Brand poured the Keep's chains, bells and crowns from it. It still holds the warmth of the last one.",
	&"relic_clapper": "A bell clapper. Tolland rang every vow in Vaelmoor with this, and then every funeral. It pays well, the way grief does, to those who can bear the weight.",
	&"relic_briar": "The Briar Locket. Elsbet pressed a rose into every one of these for the dead. The rose grew through it. I would not wear it near a window.",
	&"relic_gear": "A gear from the Orrery. Calloway swore it counted the days until the Crown's return. It counts something. I would rather not know what.",
	&"relic_chalice": "The Drowned Chalice. It was used for the last blessing before the nave flooded. It has never been empty since. I hope you do not drink from it.",
	&"relic_oathbreaker": "A ring broken and bound again. Whoever wore it chose the oath and unchose it, repeatedly. It has a kind of wisdom in it. It is not a comfortable one.",
	&"relic_regent": "The Hollow Crown. I had hoped it was a legend. Hold it carefully: it rewards those who strike the moment someone else strikes first.",
	&"sextons_lantern": "The Sexton's lantern. It lit every burial in the Pilgrim's Graveyard for a hundred years. It will light yours too, if you let it - and I would rather you did not.",
}
const VESPER_FIRST := [
	"Oh! A visitor. A living one. Do forgive me - the Gallery has been shut for so long that I had begun to catalogue the dust.",
	"I am Vesper, the archivist. Everything this house ever kept is kept here: letters, portraits, the Candlewrights' last drafts. Show me what you find, and I will tell you what it was.",
]
const VESPER_GREETINGS := [
	"Do bring me anything curious. A catalogue with gaps in it is a wound.",
	"I have read every letter in this room. The best of them were never sent.",
	"The portraits do not mind being looked at. They have had a very long time to get used to it.",
]

static func _quest_for(npc: StringName) -> Dictionary:
	var n := talks(npc)
	if n < 1:
		return {}
	# Story pages come first for the two with a plot to tell.
	if npc == &"ommen":
		var marshal_down := bool(GameState.get_flag(MARSHAL_FLAG, false))
		if n < OMMEN_STORY.size() or not bool(GameState.get_flag(SIGIL_FLAG, false)) \
				or (marshal_down and not bool(GameState.get_flag(&"ommen_heard_after", false))):
			return {}
	if npc == &"aldous" and bool(GameState.get_flag(MARSHAL_FLAG, false)) and not bool(GameState.get_flag(&"aldous_heard_marshal", false)):
		return {}
	return Quests.for_npc(npc, n)


static func _greeting(npc: StringName, field_pool: Array, n: int) -> Array:
	var pool: Array = field_pool
	if Manor.in_manor() and MANOR_GREETINGS.has(npc):
		pool = MANOR_GREETINGS[npc]
	return [pool[n % pool.size()]]


## Items from the archive the player carries and has not yet heard about.
static func _archive_ids() -> Array:
	var ids: Array = ARCHIVE.keys()
	ids.append_array(DescentNpcs.ARCHIVE.keys())
	return ids


static func archive_line(id: StringName) -> String:
	return String(ARCHIVE[id]) if ARCHIVE.has(id) else String(DescentNpcs.ARCHIVE.get(id, ""))


static func archive_pending() -> Array:
	var out := []
	for id in _archive_ids():
		if GameState.item_count(id) > 0 and not bool(GameState.get_flag(StringName("arch_" + String(id)), false)):
			out.append(id)
	return out


## What the prompt calls them: the stranger gives his name on the third talk.
static func display_name(npc: StringName, fallback: String) -> String:
	if npc == &"ommen" and talks(npc) >= 2:
		return "Ommen"
	return fallback


static func talks(npc: StringName) -> int:
	return int(GameState.get_flag(StringName("talks_" + String(npc)), 0))


static func conversation(npc: StringName) -> Dictionary:
	var n := talks(npc)
	if npc == &"vesper":
		var pend := archive_pending()
		if n == 0:
			return {"speaker": "Vesper", "lines": VESPER_FIRST}
		if not pend.is_empty():
			var lines4 := []
			for id in pend.slice(0, 2):
				lines4.append(archive_line(id))
			return {"speaker": "Vesper", "lines": lines4}
		return {"speaker": "Vesper", "lines": [VESPER_GREETINGS[(n - 1) % VESPER_GREETINGS.size()]]}
	var q := _quest_for(npc)
	if not q.is_empty():
		var qd := Quests.def(q.id)
		var qlines: Array
		match q.mode:
			"offer": qlines = qd.offer
			"complete": qlines = qd.complete
			_: qlines = ["%s  (%s)" % [qd.remind, Quests.progress_text(q.id)]]
		return {"speaker": _speaker_for(npc), "lines": qlines, "quest": q}
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
				lines = _greeting(npc, OMMEN_IDLE, n - OMMEN_STORY.size())
			return {"speaker": speaker, "lines": lines}
		&"wenna":
			var lines2: Array = WENNA_FIRST if n == 0 else _greeting(npc, WENNA_GREETINGS, n - 1)
			return {"speaker": "Wenna", "lines": lines2}
		&"hobb":
			return {"speaker": "Hobb", "lines": HOBB_FIRST if n == 0 else _greeting(npc, HOBB_GREETINGS, n - 1)}
		&"ilse":
			return {"speaker": "Sister Ilse", "lines": ILSE_FIRST if n == 0 else _greeting(npc, ILSE_GREETINGS, n - 1)}
		&"pell":
			return {"speaker": "Pell", "lines": PELL_FIRST if n == 0 else [PELL_GREETINGS[(n - 1) % PELL_GREETINGS.size()]]}
		&"hesk":
			return {"speaker": "Hesk", "lines": HESK_FIRST if n == 0 else [HESK_GREETINGS[(n - 1) % HESK_GREETINGS.size()]]}
		&"lantern_man":
			return {"speaker": "The Lantern-Man", "lines": LANTERN_FIRST if n == 0 else [LANTERN_GREETINGS[(n - 1) % LANTERN_GREETINGS.size()]]}
		&"aldous":
			var lines3: Array
			if n == 0:
				lines3 = ALDOUS_FIRST
			elif bool(GameState.get_flag(MARSHAL_FLAG, false)) and not bool(GameState.get_flag(&"aldous_heard_marshal", false)):
				lines3 = ALDOUS_AFTER_MARSHAL
			else:
				lines3 = [ALDOUS_GREETINGS[(n - 1) % ALDOUS_GREETINGS.size()]]
			return {"speaker": "Aldous Vane", "lines": lines3}
	if DescentNpcs.has(npc):
		return DescentNpcs.conversation(npc)
	return {"speaker": "...", "lines": ["..."]}


static func _speaker_for(npc: StringName) -> String:
	return {&"ommen": "Ommen", &"wenna": "Wenna", &"hobb": "Hobb", &"ilse": "Sister Ilse", &"aldous": "Aldous Vane", &"lantern_man": "The Lantern-Man", &"pell": "Pell", &"hesk": "Hesk"}.get(npc, "...")


## Records that the conversation happened (advances the story).
static func finish(npc: StringName) -> void:
	if npc == &"vesper":
		if talks(npc) > 0:
			for id in archive_pending().slice(0, 2):
				GameState.set_flag(StringName("arch_" + String(id)), true)
		GameState.set_flag(&"talks_vesper", talks(npc) + 1)
		return
	var q := _quest_for(npc)
	if not q.is_empty():
		if q.mode == "offer":
			Quests.start(q.id)
		elif q.mode == "complete":
			Quests.complete(q.id)
		GameState.set_flag(StringName("talks_" + String(npc)), talks(npc) + 1)
		return
	if DescentNpcs.has(npc):
		DescentNpcs.finish(npc)
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
