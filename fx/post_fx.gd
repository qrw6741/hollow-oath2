class_name PostFx
extends CanvasLayer
## Full-screen finishing pass (bloom, colour grade, grain). Sits above the world and below the vignette
## and HUD. Switched by Settings.glow_active() ("Glow & grading"); costs one full-screen draw.

var _rect: ColorRect


func _ready() -> void:
	layer = 7
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://fx/post_fx.gdshader")
	_rect.material = m
	add_child(_rect)
	refresh()


func refresh() -> void:
	if _rect:
		_rect.visible = Settings.glow_active()


func _process(_dt: float) -> void:
	if _rect and _rect.visible != Settings.glow_active():
		refresh()
