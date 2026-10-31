extends Node
## Player-facing options (accessibility, audio). Persisted to user://settings.cfg.
## Options change presentation only — they never alter combat timing or difficulty.

signal changed

const PATH := "user://settings.cfg"

var screen_shake := 1.0      ## 0 = off, 1 = full.
var flashes := true          ## Full-screen / hit flashes.
var hit_stop := true         ## Freeze-frame on impact.
var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.9
var show_debug := false
var vibration := true
## Accessibility: swap status colours for a palette that separates for red-green colour blindness.
var colorblind := false
## First-time tips.
var tutorial_hints := true
## Difficulty / accessibility. These DO change combat, on purpose, and are labelled so.
const DAMAGE_STEPS := [50, 75, 100, 125, 150, 200]
const ENEMY_HP_STEPS := [50, 75, 100, 125, 150]
var damage_taken_pct := 100
var enemy_health_pct := 100
## Adds PARRY_ASSIST_FRAMES to every parry window.
var parry_assist := false
const PARRY_ASSIST_FRAMES := 4
## Open the candle (level-up) menu automatically after resting. Not saved; tests turn it off.
var candle_menu_on_rest := true
var pad_style := 0           ## Controller icons: 0 auto-detect, 1 PlayStation, 2 Xbox.

## Video. Presentation only; gameplay always simulates at a fixed 60 Hz.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const FPS_CAPS: Array[int] = [30, 60, 120, 144, 240, 0]   ## 0 = unlimited
var fullscreen := false
var resolution_index := 2        ## 1920x1080 when windowed.
var damage_numbers := true       ## Floating damage numbers.
var glow := true                 ## Bloom / colour grade / grain finishing pass.
var hires := true                ## true: render at native resolution; false: chunky 480x270 pixels.
## Default 60: an unlimited default made the game render thousands of frames a second whenever vsync was
## not honoured by the driver/window mode, which can max out the GPU and make the whole PC stutter.
var fps_cap := 60
const FPS_BG := 20   ## frame cap while the window is not focused (game is paused-ish anyway)
var vsync := true


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		apply_video()
		return
	screen_shake = clampf(float(cfg.get_value("accessibility", "screen_shake", screen_shake)), 0.0, 1.0)
	flashes = bool(cfg.get_value("accessibility", "flashes", flashes))
	hit_stop = bool(cfg.get_value("accessibility", "hit_stop", hit_stop))
	colorblind = bool(cfg.get_value("accessibility", "colorblind", colorblind))
	tutorial_hints = bool(cfg.get_value("accessibility", "tutorial_hints", tutorial_hints))
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	vibration = bool(cfg.get_value("controller", "vibration", vibration))
	var dt := int(cfg.get_value("gameplay", "damage_taken_pct", damage_taken_pct))
	damage_taken_pct = dt if DAMAGE_STEPS.has(dt) else 100
	var eh := int(cfg.get_value("gameplay", "enemy_health_pct", enemy_health_pct))
	enemy_health_pct = eh if ENEMY_HP_STEPS.has(eh) else 100
	parry_assist = bool(cfg.get_value("gameplay", "parry_assist", parry_assist))
	pad_style = clampi(int(cfg.get_value("controller", "pad_style", pad_style)), 0, 2)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	resolution_index = clampi(int(cfg.get_value("video", "resolution_index", resolution_index)), 0, RESOLUTIONS.size() - 1)
	hires = bool(cfg.get_value("video", "hires", hires))
	glow = bool(cfg.get_value("video", "glow", glow))
	damage_numbers = bool(cfg.get_value("accessibility", "damage_numbers", damage_numbers))
	# Config v2: before it, "unlimited" (0) was the untouched default, so an old 0 is not a choice: use 60.
	var cap := int(cfg.get_value("video", "fps_cap", fps_cap))
	if int(cfg.get_value("video", "fps_cap_version", 1)) < 2 and cap == 0:
		cap = 60
	fps_cap = cap if FPS_CAPS.has(cap) else 60
	vsync = bool(cfg.get_value("video", "vsync", vsync))
	apply_audio()
	apply_video()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("accessibility", "screen_shake", screen_shake)
	cfg.set_value("accessibility", "flashes", flashes)
	cfg.set_value("accessibility", "hit_stop", hit_stop)
	cfg.set_value("accessibility", "colorblind", colorblind)
	cfg.set_value("accessibility", "tutorial_hints", tutorial_hints)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("controller", "vibration", vibration)
	cfg.set_value("gameplay", "damage_taken_pct", damage_taken_pct)
	cfg.set_value("gameplay", "enemy_health_pct", enemy_health_pct)
	cfg.set_value("gameplay", "parry_assist", parry_assist)
	cfg.set_value("controller", "pad_style", pad_style)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("video", "hires", hires)
	cfg.set_value("video", "glow", glow)
	cfg.set_value("accessibility", "damage_numbers", damage_numbers)
	cfg.set_value("video", "fps_cap", fps_cap)
	cfg.set_value("video", "fps_cap_version", 2)
	cfg.set_value("video", "vsync", vsync)
	cfg.save(PATH)
	apply_audio()
	apply_video()
	changed.emit()


func apply_audio() -> void:
	var audio := get_node_or_null(^"/root/Audio")
	if audio:
		audio.apply_volumes()
	else:
		var bus := AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))


## Applies window mode, resolution, render mode, frame cap and vsync. Safe to call
## repeatedly; does nothing to the window when running headless (tests).
func apply_video() -> void:
	Engine.max_fps = fps_cap if get_window() == null or get_window().has_focus() or DisplayServer.get_name() == "headless" else FPS_BG
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var w := get_window()
	w.content_scale_size = Vector2i(480, 270)
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if hires:
		w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	else:
		w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	if fullscreen:
		w.mode = Window.MODE_FULLSCREEN
	else:
		w.mode = Window.MODE_WINDOWED
		var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		var size := RESOLUTIONS[resolution_index]
		# Never open a window bigger than the desktop (title bar and taskbar included).
		var fit := minf(float(screen.size.x) / size.x, float(screen.size.y - 40) / size.y)
		if fit < 1.0:
			size = Vector2i(int(size.x * fit), int(size.y * fit))
		w.size = size
		w.position = screen.position + (screen.size - size) / 2


## Window focus: drop to a low frame cap while another window is in front (so alt-tabbing out of the game
## never leaves a GPU-hungry loop running behind your other programs), restore it when focus returns.
func _notification(what: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Engine.max_fps = FPS_BG
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Engine.max_fps = fps_cap
