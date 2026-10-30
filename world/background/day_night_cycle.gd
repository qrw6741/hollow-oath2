class_name DayNightCycle
extends Node
## Put one in an outdoor level. Every half second it tints the level's CanvasModulate and
## sky from DayNight, announces dusk / night / dawn, and tells spawners when night begins
## or ends (Events.daynight_changed).

@export var light_path: NodePath = ^"../Light"
@export var sky_path: NodePath = ^"../Background/Sky/SkyDraw"

var _light: CanvasModulate
var _sky: Node
var _timer := 0.0
var _was_night := false
var _was_phase := -1


func _ready() -> void:
	_light = get_node_or_null(light_path) as CanvasModulate if not light_path.is_empty() else null
	_sky = get_node_or_null(sky_path) if not sky_path.is_empty() else null
	_was_night = DayNight.is_night()
	_was_phase = DayNight.phase()
	apply()


func _process(delta: float) -> void:
	_timer += delta
	if _timer < 0.5:
		return
	_timer = 0.0
	apply()
	var night := DayNight.is_night()
	if night != _was_night:
		if _was_night and not night:
			GameState.set_flag(&"night_survived", true)
			Deeds.check_all()
		_was_night = night
		Events.daynight_changed.emit(night)
	var p := DayNight.phase()
	if p != _was_phase:
		_was_phase = p
		if GameState.in_game:
			Events.banner_requested.emit(["Day breaks", "Dusk falls", "Night on the road", "Dawn"][p])


func apply() -> void:
	var d := DayNight.darkness()
	if _light:
		_light.color = DayNight.tint(d)
	if _sky and "darkness" in _sky:
		_sky.darkness = snappedf(d, 0.02)
