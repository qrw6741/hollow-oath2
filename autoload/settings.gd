extends Node
## Player-facing options (accessibility, audio). Persisted to user://settings.cfg.
## Options change presentation only — they never alter combat timing or difficulty.

signal changed

const PATH := "user://settings.cfg"

var screen_shake := 1.0      ## 0 = off, 1 = full.
var flashes := true          ## Full-screen / hit flashes.
var hit_stop := true         ## Freeze-frame on impact.
var master_volume := 0.8
var show_debug := false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	screen_shake = clampf(float(cfg.get_value("accessibility", "screen_shake", screen_shake)), 0.0, 1.0)
	flashes = bool(cfg.get_value("accessibility", "flashes", flashes))
	hit_stop = bool(cfg.get_value("accessibility", "hit_stop", hit_stop))
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	_apply_audio()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("accessibility", "screen_shake", screen_shake)
	cfg.set_value("accessibility", "flashes", flashes)
	cfg.set_value("accessibility", "hit_stop", hit_stop)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(PATH)
	_apply_audio()
	changed.emit()


func _apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
