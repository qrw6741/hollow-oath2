"""Data for the 'Wayfarers of the Descent' update: one NPC, one armour and one keepsake per Descent map,
new consumables and three new shops. Consumed by gen_descent2.py and levels/gen_side_levels.py.

STORY (the Descent): the First Oath was not a law. It was two people in a barrow: Aure, the first
Candlewright, and Wend, a soldier, who swore 'I will not leave you in the dark.' The kingdom copied the
words and lost the meaning. At the bottom, Wend still stands where he promised to stay, and the promise
has been keeping him there for a thousand years. The Oath Eternal is not a monster. It is a kindness
that was never allowed to end."""

# look indices of Npc.Look: PEDLAR 0, FIGURE 1, SMITH 2, KEEPER 3, STEWARD 4, ARCHIVIST 5
NPCS = [
    dict(map=0, id="marn_bonewife", name="Marn the Bone-Wife", look=3, x=1560,
         first=["Mind the shelves. They are not decoration. They are tenants.",
                "I was the last to be paid for burying the dead here. Then the dead stopped being buried and started being counted, and nobody paid me for that.",
                "Below this place the road goes on, down, further than any map. The old stories call it the Descent. I call it the long way home."],
         greet=["Skarn counts to the end and finds one more. It is always me.", "Ide feeds the shelves. They are never full. That is not hunger, that is grief with a mouth.", "If you see a king in the dark, bow. It costs nothing, and he has very little left."],
         after=["You put Veyl down. He was the first buried here, you know. He never let another grave be dug without his leave.", "He kept the leave because the first oath asked him to keep watch over the dead. Nobody told him when the watch was over.", "Take this. It was in his hand. I think he meant it for whoever came after."],
         gift=("keepsake_bone_ring", "Veyl's Ring", "A ring of yellowed bone, worn smooth by a thumb. It was the first thing buried here.")),
    dict(map=1, id="tallow_marn", name="Wick-Wife Ouse", look=0, x=1560, shop="tallow",
         first=["Candles! Honest ones. Don't ask what they're rendered from. It is better for both of us.",
                "My husband was Wickmaster Dorr. He lit the first flame in the mine and kept lighting them after he stopped being able to put them out.",
                "I sell what I can make. It burns slow. It burns true. Sometimes it screams a little. That is the wax remembering."],
         greet=["The wax is warm today. That is rarely good.", "Grise was a good dog. Before. Don't pity the thing she became. Pity the dog.", "Ulme swore to light the whole kingdom. Look what it costs to keep a promise that size."],
         after=["Ulme's gone out, then. Quietly, the way a candle does when it finally has nothing left to give.", "I won't pretend I'm sorry. He burned a great deal of people to keep the light going. But I'm glad it was you who stopped it and not the mine.", "There. For the road. It burns for exactly as long as you need it to."],
         gift=("keepsake_last_wick", "Ulme's Last Wick", "A short wick that has been lit and never consumed. It is warm in the hand.")),
    dict(map=2, id="quill_archivist", name="Inkwell", look=5, x=1560,
         first=["Do not touch the shelves. Do not breathe on the shelves. Do not, if you can help it, read the shelves.",
                "These are the records of everyone who swore the Hollow Oath. All of them. Each page is a person. Each person is a page that has been turned.",
                "The Chancellor keeps the index. The Index keeps the Chancellor. They are very close. It is unhealthy."],
         greet=["Everything is filed under its worst moment. It is easier to find that way.", "Pell-Os never forgets a single page. That is the problem with Pell-Os.", "There is a page in here with your name. I have not read it. I would suggest you don't either."],
         after=["The Chancellor is down. The index just lost the one thing that read it aloud.", "Most of these people will remain unread. That is perhaps the kindest thing that could happen to them.", "Here. A page I was never meant to keep. It is the first oath, written down, before the kingdom was ashamed of it."],
         gift=("keepsake_first_page", "The First Page", "A page, slightly scorched at one corner. It reads: 'I will not leave you in the dark.' The ink is two hands, not one.")),
    dict(map=3, id="graft_gardener", name="Old Hob", look=4, x=1560,
         first=["Shh. You'll wake the ones that sleep standing up.",
                "This was an orchard before the Descent. We grafted the apple to the pear, the pear to the wild thorn. We should have asked what the tree wanted.",
                "It wanted company. It is very good at getting it."],
         greet=["The fruit is ripe. The fruit is always ripe. I would not eat it.", "The Twins are not two people. They are one fall and its echo.", "Sylve was a gardener once. She grafted herself in to hold the roots still. They thanked her by never letting go."],
         after=["The Last Tree stills. I felt it in the ground, a kind of exhale.", "Sylve did what she did out of love for the soil. Remember that, whatever you remember of how she ended.", "Plant this somewhere that wants it. I never found such a place. Perhaps you will."],
         gift=("keepsake_black_seed", "A Black Seed", "A seed no larger than a tooth, dark as a bruise. It has been trying to sprout for a very long time.")),
    dict(map=4, id="haggle_pawn", name="Haggle", look=0, x=1560, shop="market",
         first=["Buy, sell, or move along, the Auctioneer likes a quiet room.",
                "Everything in the Bone Market has a price. Even the things that shouldn't. Even you, if you stand still long enough.",
                "I trade in what the dead leave behind. They have no use for it. I have a great deal of use for it. It is a perfectly clean arrangement."],
         greet=["Hask takes the pawn tickets. I take the receipts. Between us we own most of what is left.", "Mordant sells lots. Never ask what he does with the ones that don't sell.", "Everything is on sale. That includes the warning I'm about to give you: nothing here is a bargain."],
         after=["The Auctioneer is silenced. That is a loss of trade, I want you to know. A heavy one.", "He once sold the same sunrise to four different families. They each wept when it set. He could not see the problem.", "Keep this. I owe you a commission and I owe myself the discomfort of paying it."],
         gift=("keepsake_gavel", "Mordant's Gavel", "A small auction gavel, its head worn flat. It makes no sound when struck. It has sold everything it ever could.")),
    dict(map=5, id="eun_drowned", name="The Tide-Reader", look=1, x=1560,
         first=["The water goes up and down twice a day. Down here it goes up and down once a year, and the year is a great deal longer.",
                "I read the tide for the Drowned Fleet. Sorrel trusted the tables. The tables said the sea would never come this far inland.",
                "It did not come inland. We went down to it. The Vaults were always at the bottom of everything."],
         greet=["Calder's armour is rusted shut. He is not in it any more, but the armour doesn't know.", "Eun still sings the hymn the Fleet sailed to. Nobody remembers the words. Eun sings them anyway.", "A tide is a promise the moon keeps. I find that comforting. Most people don't."],
         after=["The Admiral has struck her colours. The Fleet, the last of it, can finally go down with the ship.", "That was all any of us wanted. Not to sail. To be allowed to finish sinking.", "Keep this tide-glass. It will tell you, one day, when it is safe to rest."],
         gift=("keepsake_tide_glass", "Sorrel's Tide-Glass", "A glass float with a pearl of water trapped inside. The water moves against the tilt of the glass.")),
    dict(map=6, id="orm_apprentice", name="Fay's Apprentice", look=5, x=1560,
         first=["Careful. Everything in here sees you. That is the point of the place.",
                "Glasswright Orm taught us to grind a lens that could show a person their own face with total honesty. It was a mistake. Nobody can bear it.",
                "The Gallery shattered itself rather than keep doing it. Every shard is still looking."],
         greet=["Fay grinds lenses. Ysolde guards the mirror she was made to guard. Both think they are saving something.", "Look straight ahead. Never look down. The floor has opinions.", "Orm made the Gallery out of regret. It is a very fine kind of glass."],
         after=["The Glasswright is gone, and the Gallery has, at last, gone quiet.", "It was never trying to hurt anyone. It only wanted to show them what it saw. That is the cruelest thing a mirror can do.", "Here. A shard of the first lens, ground by Orm before it all went wrong. It still shows kindly."],
         gift=("keepsake_kind_shard", "The Kind Shard", "A sliver of glass that shows whoever holds it a slightly better version of themselves. It is the only honest thing in the Gallery.")),
    dict(map=7, id="tove_ashmaid", name="Ashmaid Tove", look=2, x=1560, shop="forgevows",
         first=["Stand back from the anvil. It is still warm. It has been warm for four hundred years.",
                "Every oath in Vaelmoor was struck here, hot, one at a time. The Vowsmith would hammer one into a ring and press it on a hand and say: this is yours, this is forever.",
                "I keep what's left. It burns, a little. I sell it cheap to anyone who isn't afraid of a hot thing that has a memory."],
         greet=["Brask melts what is left over. Imre prays over it. Both think they are doing the right thing.", "A vow is a metal that remembers how it was bent.", "Anaxe could close a ring on a finger so tight it never came off. They called that devotion."],
         after=["Anaxe is silenced and the anvil, for the first time, is cooling.", "All those rings. All those hands. He believed it was a gift to give people something to hold forever.", "Here. The last ring he made, the one he made for himself. He never put it on."],
         gift=("keepsake_vowsmiths_ring", "The Vowsmith's Own Ring", "A plain iron ring, unfinished on one side. He never closed it. It is the only open ring in the forge.")),
    dict(map=8, id="silent_novice", name="Novice Hush", look=1, x=1560,
         first=["...", "Oh. You speak. Please, quietly.",
                "The Cloister keeps a vow of silence. It has kept it so long that it has forgotten there was ever anything to keep quiet about."],
         greet=["Sister Quiet moves without a sound. Brother Lull has not blinked in a hundred years.", "The Prioress hears everything. That is the only noise she has left.", "If you must speak, do it while I'm not listening. I cannot promise I won't remember."],
         after=["The Prioress is silent. Truly silent, not the held-breath kind.", "I did not know the quiet could be so large. I think I used to be afraid of it.", "Take this. It is the Prioress's bell, which she never rang. It rings, now, when it likes."],
         gift=("keepsake_hush_bell", "The Hush Bell", "A tiny bronze handbell with no clapper. It rings, faintly, only for people who have stopped talking.")),
    dict(map=9, id="rook_herald", name="The Last Herald", look=4, x=1560,
         first=["Hear ye. Hear ye. Hear nobody. There is nobody left to hear.",
                "I announce the kings of the Barrow. There are twelve, and a thirteenth niche still empty. The Sovereign is pale because he is keeping the niche for someone.",
                "He is waiting to hand the crown to the one who comes down. I do not think he knows it is already hollow."],
         greet=["Rook still carries the banner. The banner has no cloth. He carries it with great ceremony.", "The Hound-King is not a king. He was the hound the king was buried with. The title was a joke the barrow forgot.", "Twelve kings. One empty niche. Please do not look at the niche. It looks back."],
         after=["The Pale Sovereign has stepped down. The thirteenth niche has stopped waiting.", "He told me once the crown was only a promise to hold the kingdom up. He never noticed it was holding him up instead.", "This is the roll of the kings. Every name, in order. You may add the thirteenth, if you like."],
         gift=("keepsake_roll_of_kings", "The Roll of Twelve Kings", "A scroll listing twelve names. A thirteenth line at the bottom is blank, and slightly warm.")),
    dict(map=10, id="wend_echo", name="An Echo of Aure", look=1, x=1560,
         first=["You made it. Few do. I am not here, you understand. This is only the part of me that stayed to wait.",
                "My name was Aure. I wrote the first oath. It was nine words long. I wrote it for one person.",
                "Wend was a soldier. He was afraid of the dark. I promised I would not leave him in it, and he promised he would not leave me. Then I died, and he kept his promise. He is still keeping it."],
         greet=["Do not hate him. He is being faithful. It is simply that faithfulness has no off switch.", "The Keeper and the Unsworn are what's left of his doubt. He needed them to keep standing. He did not know he was building a prison.", "You can break the promise, or you can finish it. I cannot tell you which is kinder."],
         after=["He is at rest. Or he is released, which is not the same thing, and I find I am glad of either.", "Thank you. The oath was nine words. I never imagined it would cost so many people so much.", "Take this. It is the candle I promised I would keep lit. It can go out now. You can carry it up."],
         gift=("keepsake_aures_candle", "Aure's Candle", "A stub of white candle that has been burning for a thousand years. It gives light but no heat, and it can finally be put out.")),
]

# New wearable armour, one per map: (id, name, look 1 LIGHT / 2 KNIGHT / 3 HEAVY, damage mult, speed mult, resist, dodge, cloth, light, accent, description)
ARMORS = [
    ("ossuary_plate", "Ossuary Plate", 3, 0.74, 0.86, {"bleed": 0.5, "poison": 0.2}, 0.0, "#d8d0b8", "#f0e8d0", "#6a5a40", "Plate cut from the old shelving of the Weeping Ossuary. It rattles like a counting."),
    ("tallow_cowl", "Tallow Cowl", 1, 0.94, 1.08, {"burn": 0.5}, -2.0, "#c8b890", "#e6d8a8", "#ffb050", "A cowl dipped in hard wax so many times it has become a second skin. Wick-Wives swear by it."),
    ("archivists_robe", "Archivist's Robe", 2, 0.88, 1.0, {"frost": 0.3, "poison": 0.3}, 0.0, "#6a5a30", "#a8903c", "#f0e0a0", "A scholar's robe stiff with gilt thread. It smells of vellum and of nobody asking questions."),
    ("thornwood_mantle", "Thornwood Mantle", 1, 0.92, 1.05, {"poison": 0.6}, -1.0, "#3a4a30", "#5a7040", "#a8c070", "A mantle of braided bark and thorns that has learned not to cut its wearer."),
    ("market_finery", "Market Finery", 1, 0.96, 1.1, {"bleed": 0.2}, -3.0, "#7a4a5a", "#b07088", "#ffd080", "A trader's coat, deliberately showy. The Bone Market respects what it can be seen wearing."),
    ("brine_hauberk", "Brine Hauberk", 2, 0.8, 0.96, {"frost": 0.5, "burn": 0.2}, 0.0, "#40607a", "#6a90a8", "#a8e0f0", "Salt-crusted mail from the Drowned Fleet. It has not rusted in a thousand years, which is more worrying than it sounds."),
    ("glasswrights_vest", "Glasswright's Vest", 1, 0.9, 1.06, {"frost": 0.2, "burn": 0.2, "poison": 0.2}, -2.0, "#8a80a8", "#b8b0d8", "#f0f0ff", "A vest of sewn glass scales, ground thin. It catches light and, occasionally, a blade."),
    ("vowsmith_plate", "Vowsmith Plate", 3, 0.72, 0.84, {"burn": 0.6, "bleed": 0.3}, 1.0, "#6a3a28", "#a8603c", "#ffb060", "Plate struck in the oath-forge itself, warm to the touch. Very heavy. Very sure of itself."),
    ("hush_habit", "Hush Habit", 1, 0.9, 1.1, {"poison": 0.3, "frost": 0.3}, -4.0, "#9aa8b6", "#c4d0dc", "#ffffff", "A grey habit that muffles every step. Dodging in it costs almost nothing, the Cloister made sure of that."),
    ("barrow_regalia", "Barrow Regalia", 2, 0.78, 0.94, {"bleed": 0.3, "frost": 0.3, "burn": 0.3}, 0.0, "#4a4458", "#706888", "#e0c860", "The grave-regalia of a king long dead. Heavy with honour, and with the weight of everyone who is still owed it."),
    ("aures_vigil", "Aure's Vigil", 2, 0.7, 1.0, {"bleed": 0.4, "poison": 0.4, "frost": 0.4, "burn": 0.4}, -2.0, "#a06070", "#d08898", "#fff0c0", "The oldest armour in the kingdom: a soldier's coat re-sewn by a candlewright's hand. It remembers being loved."),
]

# New consumables: (id, name, description, colour, effect 1 HEAL / 2 STAMINA / 3 EMBERS, amount, stack)
ITEMS = [
    ("salt_of_the_dead", "Salt of the Dead", "A pinch of grave-salt, stirred into whatever water you have. Restores 110 health. It tastes of everyone who ever grieved.", "Color(0.85, 0.85, 0.8, 1)", 1, 110.0, 5),
    ("grave_wax_balm", "Grave-Wax Balm", "Rendered tallow with a little ash. Restores 55 health. Sticky, warm, faintly reassuring.", "Color(0.9, 0.78, 0.5, 1)", 1, 55.0, 9),
    ("marrow_broth", "Marrow Broth", "A thin, hot broth. Restores a good measure of stamina. Do not ask whose marrow.", "Color(0.8, 0.72, 0.6, 1)", 2, 70.0, 7),
    ("glass_tonic", "Glass Tonic", "Clear, cold and slightly bright. Restores a great deal of stamina. The glasswrights brew it for steady hands.", "Color(0.7, 0.85, 0.95, 1)", 2, 110.0, 5),
    ("ember_pip", "Ember Pip", "A pip of spent ember. Crush it for 500 embers.", "Color(1, 0.6, 0.25, 1)", 3, 500.0, 9),
    ("ember_cluster", "Ember Cluster", "A knot of bright embers fused together. Crush it for 1500 embers.", "Color(1, 0.7, 0.3, 1)", 3, 1500.0, 5),
    ("kings_wine", "King's Wine", "Dark, old and excellent. Restores 170 health. Sealed in a barrow for a thousand years, and not one bit sour.", "Color(0.6, 0.15, 0.3, 1)", 1, 170.0, 3),
    ("hush_draught", "Hush Draught", "Silent as snowfall. Restores 140 stamina all at once. Your breathing will be very quiet for a while.", "Color(0.8, 0.88, 0.95, 1)", 2, 140.0, 3),
]
SHOPS = {
    "tallow": ("OUSE'S WARES", [("grave_wax_balm", 60), ("salt_of_the_dead", 150), ("marrow_broth", 90), ("hollow_resin", 150), ("ember_pip", 450)]),
    "market": ("HAGGLE'S WARES", [("salt_of_the_dead", 160), ("glass_tonic", 170), ("kings_wine", 380), ("ember_cluster", 1300), ("ember_shard", 250), ("forge_scrap", 95)]),
    "forgevows": ("TOVE'S WARES", [("forge_scrap", 80), ("hush_draught", 300), ("glass_tonic", 160), ("kings_wine", 360), ("ember_cluster", 1250), ("ember_shard", 230)]),
}

# What Vesper the archivist says about each keepsake (the story of the Descent, told sideways).
VESPER = {
    "keepsake_bone_ring": "A bone ring from the Ossuary. The first burial there was not a king. He was only the first to be buried, and the first to refuse to be dug up again. Titles come later.",
    "keepsake_last_wick": "Ulme's wick. He did not set out to burn the kingdom. He set out to light one room, once, for one person. I think that is where the first oath comes from: a light kept for someone.",
    "keepsake_first_page": "The First Page! It is in two hands. One is a soldier's, blocky and careful. One is a candlewright's, fine and fast. They wrote it together. The oath was a letter before it was a law.",
    "keepsake_black_seed": "A grafted seed. Sylve held the roots still because the orchard was dying of loneliness. I do not think the tree ever understood that she was a gift. It only understood that she stayed.",
    "keepsake_gavel": "Mordant's gavel. He sold everything, in the end, including the one thing he was never able to price: the first oath. Nobody bid. He took that as an insult.",
    "keepsake_tide_glass": "A tide-glass. The Drowned Fleet was not lost at sea. It sailed down, on purpose, to find the bottom of the oath. They never came back up. Sorrel gave the order and then, I think, regretted it.",
    "keepsake_kind_shard": "The Kind Shard. It is the only lens in the Gallery that shows you as someone who is loved. Orm ground it first and could not bear that all the others were so cruel in comparison.",
    "keepsake_vowsmiths_ring": "An open ring. Anaxe forged ten thousand closed ones. His own he left open, because he knew, from the very first, that a vow you cannot step out of is not a vow. He kept making them anyway.",
    "keepsake_hush_bell": "The Hush Bell, no clapper. The Cloister fell silent so that the oath could be heard clearly. Nobody noticed that it had stopped saying anything worth hearing.",
    "keepsake_roll_of_kings": "Twelve kings, and a thirteenth line, empty. Every king of Vaelmoor swore the oath and kept it badly. The thirteenth niche was kept for the one who would keep it well. That is why the Sovereign is so pale. He is waiting for a better king than himself.",
    "keepsake_aures_candle": "Aure's candle! A thousand years alight, and you carried it up. I will not ask how. I will say this: all the candles in Vaelmoor were lit from this one. You are holding where the light came from.",
}

RELIC_NAMES = ["Veyl's Knucklebone", "Ulme's Drip-Candle", "Vorne's Seal", "Sylve's Heartwood", "Mordant's Ledger", "Sorrel's Compass",
               "Orm's Eyepiece", "Anaxe's Hammer-Charm", "Silence's Veil-Pin", "The Sovereign's Pale Crown", "Wend's Oath-Knot"]
