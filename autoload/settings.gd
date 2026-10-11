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

## Video. Presentation only; gameplay always simulates at a fixed 60 Hz.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const FPS_CAPS: Array[int] = [30, 60, 120, 144, 240, 0]   ## 0 = unlimited
var fullscreen := false
var resolution_index := 2        ## 1920x1080 when windowed.
var hires := true                ## true: render at native resolution; false: chunky 480x270 pixels.
var fps_cap := 0
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
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	resolution_index = clampi(int(cfg.get_value("video", "resolution_index", resolution_index)), 0, RESOLUTIONS.size() - 1)
	hires = bool(cfg.get_value("video", "hires", hires))
	var cap := int(cfg.get_value("video", "fps_cap", fps_cap))
	fps_cap = cap if FPS_CAPS.has(cap) else 0
	vsync = bool(cfg.get_value("video", "vsync", vsync))
	apply_audio()
	apply_video()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("accessibility", "screen_shake", screen_shake)
	cfg.set_value("accessibility", "flashes", flashes)
	cfg.set_value("accessibility", "hit_stop", hit_stop)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("video", "hires", hires)
	cfg.set_value("video", "fps_cap", fps_cap)
	cfg.set_value("video", "vsync", vsync)
	cfg.save(PATH)
	apply_audio()
	apply_video()
	changed.emit()


func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))


## Applies window mode, resolution, render mode, frame cap and vsync. Safe to call
## repeatedly; does nothing to the window when running headless (tests).
func apply_video() -> void:
	Engine.max_fps = fps_cap
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
