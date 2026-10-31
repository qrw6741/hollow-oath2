class_name BossLines
extends RefCounted
## Spoken lines for every boss, shown as subtitles by BossSpeech. Data only: boss_id ->
## [intro 1, intro 2, half health, defeated, you fell]. Missing ids fall back to a generic set.

const LINES := {
	&"bell_warden": ["The bell is still ringing. Can you not hear it?", "Every oath-breaker passes my gate. None pass twice.", "Louder! LOUDER! Let the whole yard know!", "Ring it... for me... once... and let it end.", "Another sleeper for the yard. Rest well."],
	&"drowned_canon": ["The liturgy runs backwards down here. So do the prayers.", "Kneel. The water is only a very patient floor.", "Ah. You have not drowned. How rude.", "The tide... goes out... at last.", "Down you go. The water was always your answer."],
	&"hollow_marshal": ["Halt. The crossroads are held. Name your business, or die in it.", "I swore to stop everything that comes. You are everything.", "My oath has no end. Neither, I think, has your patience.", "Stand down... I can stand down... can I?", "Held. As ever. Go back, pilgrim."],
	&"gravewarden": ["Every grave on this road, I dug. I will dig yours.", "Stand still. It is easier for the spade.", "Your hole is half dug already, friend.", "Fill it... fill it in... I have kept my word.", "Good. Lie still. The earth is warm."],
	&"cellarer": ["The key stays with me. You will not have it.", "Forty years I guarded it. What are you, to ask?", "My hands remember the lock. Do yours remember the door?", "Take... the key. I am so tired of holding it.", "The cellar keeps all things. Including you."],
	&"salt_abbot": ["Welcome, little drowning. Come, be blessed.", "I signed each one. Yours shall be a fine hand.", "The water is restless. It wants a congregation.", "Amen... Let the book close... it is finished.", "Blessed be the water. And blessed be your end."],
	&"hollow_regent": ["Kneel. This court has sat for a hundred years without a subject standing.", "You wear no crown. How very dangerous of you.", "The court rises! The court always rises!", "The court... adjourns. The oath is lifted from my head.", "The court is amused. It adjourns for your burial."],
	&"last_ringer": ["I rang for the vows. I rang for the dead. Now I ring for me.", "There is no clapper. I am the clapper.", "Hear it? The bell has found its note.", "Silence at last. How loud it is.", "Toll, toll. The bell tolls for you."],
	&"thornmother": ["My roses know your name. They are so very hungry.", "Come into the garden. The soil is soft.", "Bloom! Bloom! Feed me, my darlings!", "The thorns... let go... how bright the sun.", "A fine fertiliser. Thank you, dear."],
	&"orrerist": ["Eleven minutes until the Crown returns. I always say eleven.", "Please do not touch the gears. They are very particular.", "It is running! Look, it is running again!", "The machine stops... and so, finally, do I.", "A broken part. I shall replace you."],
	&"drowned_bishop": ["Brethren, rise. We have a guest for the sermon.", "Let us pray. Let us pray. Let us pray.", "The nave floods! The faithful sing!", "My flock... you may breathe. Breathe, my flock.", "The sermon must go on. Without you."],
	&"crownless_king": ["I was promised a crown. I am still waiting. Kneel while you wait with me.", "A throne is just a chair with ambitions.", "Do you hear them cheer? No? Neither do I.", "No crown. No kingdom. Only... peace?", "Long live the king. Though not you."],
	&"ossuary_king_veyl": ["I was buried first. No grave is dug without my leave.", "Count your bones, traveller. I shall count them too.", "Rise, my shelves! The living are rude!", "A hole in the wall... for me, if you would.", "Another for the shelf. Number one thousand and one."],
	&"chandler_ulme": ["Light for the kingdom. Light for everyone. I am so very bright.", "Do you feel the warmth? It is not a kindness.", "Burn! Burn so they can see!", "Dim... it is dim... how peaceful the dark.", "A wick for the next candle. You will burn well."],
	&"chancellor_vorne": ["The law is the law. You are, I regret, in breach of it.", "Clause nine: all trespassers will be corrected.", "Objection! I object to your continued existence!", "The... precedent... was wrong? Impossible.", "Case closed. Sentence: carried out."],
	&"mother_sylve": ["Come under my branches. It is cold out in the light.", "I have forgotten why I stand. Perhaps for you.", "The fruit falls. It always falls on someone.", "The leaves... let go... so quiet, the ground.", "Roots take what the sky refuses."],
	&"auctioneer_mordant": ["Lot one: you. Do I hear an offer?", "Going once... I never say the third.", "Sold! To the highest bidder, who is not you!", "Going... twice... and... no... I cannot say it.", "Sold. Your remains go to the lowest bidder."],
	&"admiral_sorrel": ["Fleet, hold formation! A boarder on deck!", "I have not lost a ship. I will not lose this one.", "All hands! Fire at will! At every will!", "The fleet... may sail... Dismissed, all of you.", "Overboard. As is the custom."],
	&"glasswright_orm": ["Look at yourself. No, closer. Closer.", "I built it to show the world. It showed me you.", "Shatter, shatter. Seven years of bad luck apiece.", "A crack. How very... clear.", "Reflected, and found wanting."],
	&"vowsmith_anaxe": ["Another vow to forge. Hold out your hand.", "I have never unmade one. I do not know how.", "The anvil is warm. It likes you.", "Break it, then. I never knew it could be broken.", "A vow is a chain. I only make the links."],
	&"prioress_silence": ["Hush.", "The rule is silence. The rule is mine.", "Do not speak. Do not breathe. Do not stay.", "...", "Silence. As it should be."],
	&"pale_sovereign": ["The twelfth king does not need a crown. Only a subject.", "Bow. The oath is already on your head.", "You will wear it too, in the end.", "The weight... lifts... I am only a man?", "Another subject. Welcome to the long reign."],
	&"the_oath_eternal": ["I am the sentence that is still being said. I am what you swore.", "Every road led here. You walked them willingly.", "You cannot break what you are made of.", "A sentence ends. How strange. How... quiet.", "Say it again. Say it forever."],
	&"ser_ashfall": ["I refused the oath. It refused me a grave. Fight me for it.", "Show me your steel, or your knees.", "Not bad. The Guard would have taken you.", "A grave... at last... thank you, stranger.", "Rise and try again. The Guard never quit."],
	&"the_unsworn": ["You... speak? You are not one of them. Not yet.", "I refused. It was lonely. It was right.", "Do not pity me. I chose this.", "Alone is not the worst thing. Remember that.", "Back to the dark, then. I will wait."],
	&"archivist_pellos": ["Do not read. Do not read. Do not read. I read all of it!", "The pages scream. Do you not hear them?", "Silence the library! Silence it!", "Quiet... the pages... are quiet...", "Another volume for the shelf. You will not be read."],
	&"bannerbearer_rook": ["For the Crown! For the kingdom that is no longer there!", "The banner stands. So do I.", "Rally! Rally to the colours!", "The flag... falls... let it fall.", "The banner needs no one. Not even you."],
	&"barker_quill": ["Step right up! I have exactly what you will need!", "A potion? A prayer? A coffin? All fairly priced!", "Special offer! Today, you are the product!", "Never wrong... I was never wrong... and I was wrong.", "Told you you would need a coffin."],
	&"brineknight_calder": ["The water-gate stays shut. The water will not ask twice.", "It was here first. So was I.", "The tide turns. It is turning on you.", "Let it in... it was always going to come.", "The sea takes its due."],
	&"brother_lull": ["Shh. Rest. Nothing hurts when you sleep.", "Listen... a lullaby. Only for you.", "Do not fight it. Sleep is so very kind.", "The song... stops. I forgot... the last verse.", "Sleep well, little one."],
	&"cinderpriest_imre": ["Bless this forge. Bless this fire. Bless this fool.", "It answers me. It will answer you too.", "Burn brighter! The forge is hungry!", "The fire... dims... I am only ash.", "A fine offering. The forge is grateful."],
	&"drowned_cantor_eun": ["The tide has learned the words. Sing along.", "Low notes first. Then the water.", "Higher! Higher! Let the sea hear!", "My voice... goes out... with the tide.", "A fine chorus, lost to the deep."],
	&"foundrymaster_brand": ["Chains, then bells, then crowns. Next, you.", "The furnace has not gone out. Neither have I.", "Hotter! Pour it hotter!", "The furnace... cools. I should have looked up.", "Into the mould, then. You will make a fine bell."],
	&"gaoler_vess": ["No one is ever released. That is the rule of the keys.", "One link per year. Yours will be long.", "Chains! Wrap the cells! Wrap the world!", "The chain... breaks. It is only iron.", "In you go. Cell seven. It is always cell seven."],
	&"gardener_hobthorne": ["The trees do not need tending. They do not mind, either.", "Mind the roots, friend. They are shy.", "Pruning time! Everyone must be pruned!", "A cut... a clean one... the garden rests.", "Good mulch. Good mulch indeed."],
	&"hollow_houndking": ["The kings kept hounds. The hounds kept the dead.", "Heel. No? Then fight.", "The pack comes! The pack always comes!", "Quiet, now... quiet... old boy... good...", "Good dog. Take it back to the kennel."],
	&"keeper_first_oath": ["The first promise reads: do not leave. I keep it.", "You are leaving. I cannot allow that.", "Stay! Stay! It is for your own good!", "Go, then... the promise... was a cage.", "Stay. You will be very comfortable."],
	&"lensgrinder_fay": ["Hold still. I am grinding a lens for your soul.", "Do not look. Do not look in the glass.", "Clearer! The picture is too clear!", "I see... myself... oh. Oh no.", "A perfect lens. Perfectly cracked."],
	&"marrow_mother_ide": ["Feed the shelves, my dears. Dinner is served.", "They take. They always ask for more.", "More! They are hungry! Give them more!", "Enough... enough, my dears... eat nothing more.", "A fine dish. The shelves are grateful."],
	&"mirror_knight_ysolde": ["I fight as you do. I have had so much practice.", "Your guard is my guard. Your fear is my fear.", "Ha! I learned that from you!", "Defeated by myself. How elegant.", "You swing like all the rest. I know you now."],
	&"mother_cinder": ["The censer is lit. Nothing is left to burn but you.", "Child, the incense never goes out.", "Smoke! Let the smoke carry you!", "The censer... falls... it is cold, at last.", "Ash to ash. Your name is already in the censer."],
	&"pawnbroker_hask": ["I will take anything in exchange. Your name, for a start.", "Do you know what you have? I do. I want it.", "No refunds! No returns! No mercy!", "The ledger... is empty? When did that happen?", "Pawned. Forever. No redemption."],
	&"sister_quiet": ["...", "(She raises one finger to her lips.)", "(Her hands tremble. The silence deepens.)", "...thank you.", "..."],
	&"skarn_bone_counter": ["One, two, three... one more than I counted. One more.", "I must start again. Stand still while I count you.", "Fifty-one, fifty-two... no, that is wrong! Again!", "At last. The count... ends. It ends.", "Plus one. The count is always plus one."],
	&"smelter_brask": ["Broken promises, melted down. There is so much metal in a promise.", "Yours will make a fine ingot.", "Into the crucible! Everything melts!", "The crucible... cracks. Cool. It is cool.", "Poured, and cooled. Thank you for your promise."],
	&"tallow_hound_grise": ["(A wet growl. The shape of a dog, poured and set.)", "(It circles, leaving a greasy trail.)", "(It howls, and the wax drips faster.)", "(It lies down. It is only wax now.)", "(It licks the wax from its jaws.)"],
	&"the_index": ["Entry: you. Condition: living. Pending revision.", "Cross-reference: the dead. Please remain in alphabetical order.", "Error! Error! The entry resists cataloguing!", "Last... entry... struck. The page is blank.", "Entry updated: deceased. Filed."],
	&"wickmaster_dorr": ["I lit the first candle. I never lived to put one out.", "Mind the wick. It is shorter than it looks.", "Light them all! Every one!", "Out... at last... the last wick... out.", "Another light snuffed. They are so very many."],
	&"windfall_twins": ["We fell together. We have been one thing since.", "He says hello. She says die. We disagree.", "We argue! We fight! We win!", "We... agree... on one thing... it is enough.", "We say: fall. We agree on that."],
}

const GENERIC := ["You should not have come.", "The oath binds us both.", "Enough. I will end this.", "It... ends.", "Rise and try again."]


static func lines(boss_id: StringName) -> Array:
	return LINES.get(boss_id, GENERIC)


static func intro(boss_id: StringName) -> Array:
	var l := lines(boss_id)
	return [l[0], l[1]]


static func half(boss_id: StringName) -> String:
	return lines(boss_id)[2]


static func defeated(boss_id: StringName) -> String:
	return lines(boss_id)[3]


static func fallen(boss_id: StringName) -> String:
	return lines(boss_id)[4]
