class_name HintBar
extends HBoxContainer
## A row of "[button] label" pairs that rebuilds when the input device changes.
## spec: comma-separated "action:label" entries, e.g. "attack_light:light,heal:heal".
## A fixed token can be given as "pad_id|Key text:label", e.g. "dpad|Arrows:move".

@export var spec := ""
@export var font_size := 8
@export var tint := Color(0.651, 0.616, 0.541, 0.9)


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 4)
	InputPrompts.device_changed.connect(_build)
	_build()


func set_spec(s: String) -> void:
	spec = s
	if is_inside_tree():
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
		remove_child(c)
	for entry in spec.split(","):
		var parts := entry.split(":")
		if parts.size() < 2:
			continue
		var g := Glyph.new()
		if parts[0].contains("|"):
			var tk := parts[0].split("|")
			g.pad_id = tk[0]
			g.key_text = tk[1]
		else:
			g.action = StringName(parts[0])
		add_child(g)
		var l := Label.new()
		l.text = parts[1]
		l.add_theme_font_size_override(&"font_size", font_size)
		l.add_theme_color_override(&"font_color", tint)
		l.add_theme_constant_override(&"outline_size", 2)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		var gap := Control.new()
		gap.custom_minimum_size.x = 6
		add_child(gap)
