class_name BuffBar
extends Control
## Small list of active potion buffs with their time left, under the status row of the HUD.

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_size_override(&"font_size", 7)
	_label.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	_label.add_theme_constant_override(&"outline_size", 2)
	_label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	add_child(_label)


func _process(_delta: float) -> void:
	if Buffs.active.is_empty():
		_label.text = ""
		return
	var lines := PackedStringArray()
	for id in Buffs.active:
		lines.append("%s  %s" % [Buffs.DEFS[id].title, Buffs.clock(Buffs.remaining(id))])
	_label.text = "\n".join(lines)
