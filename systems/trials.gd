class_name Trials
extends RefCounted
## Post-ending challenge content in the Trial Ring (Hollowmere Manor's cellar stair).
##   Boss Rush: the bosses back to back, a short rest between.   Gauntlet: ten waves.
## Records are world flags (no save change): trial_rush_best (seconds), trial_gauntlet_best (wave).
## Rewards are paid once per mode (flag trial_<mode>_done); later runs only improve records.

const RUSH_BOSSES: Array[String] = [
	"res://actors/bosses/bell_warden.tscn", "res://actors/bosses/cellarer_grume.tscn",
	"res://actors/bosses/hollow_marshal.tscn", "res://actors/bosses/sexton_hale.tscn",
	"res://actors/bosses/mother_cinder.tscn", "res://actors/bosses/salt_abbot.tscn",
	"res://actors/bosses/gaoler_vess.tscn", "res://actors/bosses/foundrymaster_brand.tscn", "res://actors/bosses/hollow_regent.tscn", "res://actors/bosses/last_ringer.tscn", "res://actors/bosses/crownless_king.tscn", "res://actors/bosses/drowned_bishop.tscn", "res://actors/bosses/orrerist.tscn", "res://actors/bosses/thornmother.tscn",
	"res://actors/bosses/ser_ashfall.tscn",
]
const E := "res://actors/enemies/"
## Each wave: scene file names (in actors/enemies).
const WAVES: Array = [
	["hollow_penitent", "hollow_penitent"],
	["roadside_pikeman", "hollow_archer", "hollow_penitent"],
	["ember_acolyte", "ember_acolyte", "oathguard"],
	["drowned_pilgrim", "drowned_pilgrim", "candle_cantor"],
	["gilded_penitent", "hollow_archer", "hollow_archer"],
	["oathguard", "oathguard", "pike_sergeant"],
	["drowned_pilgrim", "bell_bearer", "candle_cantor", "gloam_moth"],
	["gilded_penitent", "pike_sergeant", "hollow_archer"],
	["oathguard_captain", "gilded_penitent", "candle_cantor"],
	["oathguard_captain", "pike_sergeant", "gilded_penitent", "bell_bearer"],
]
const RUSH_REWARD := 6000
const GAUNTLET_REWARD := 3500


static func unlocked() -> bool:
	return Endings.chosen() != &"" or (not Endings.enabled and bool(GameState.get_flag(Endings.MARSHAL_FLAG, false)))


static func best_rush() -> float:
	return float(GameState.get_flag(&"trial_rush_best", 0.0))


static func best_gauntlet() -> int:
	return int(GameState.get_flag(&"trial_gauntlet_best", 0))


static func done(mode: StringName) -> bool:
	return bool(GameState.get_flag(StringName("trial_%s_done" % mode), false))


## Records a finished run; returns {"reward": embers paid, "record": bool}.
static func record_rush(seconds: float) -> Dictionary:
	var rec := best_rush() == 0.0 or seconds < best_rush()
	if rec:
		GameState.set_flag(&"trial_rush_best", snappedf(seconds, 0.1))
	return _pay(&"rush", RUSH_REWARD, rec)


static func record_gauntlet(wave_reached: int, cleared: bool) -> Dictionary:
	var rec := wave_reached > best_gauntlet()
	if rec:
		GameState.set_flag(&"trial_gauntlet_best", wave_reached)
	return _pay(&"gauntlet", GAUNTLET_REWARD, rec) if cleared else {"reward": 0, "record": rec}


static func _pay(mode: StringName, reward: int, rec: bool) -> Dictionary:
	var paid := 0
	if not done(mode):
		GameState.set_flag(StringName("trial_%s_done" % mode), true)
		paid = reward
		GameState.add_embers(paid)
	Deeds.check_all()
	return {"reward": paid, "record": rec}


static func fmt_time(s: float) -> String:
	return "%d:%04.1f" % [int(s) / 60, fmod(s, 60.0)]
