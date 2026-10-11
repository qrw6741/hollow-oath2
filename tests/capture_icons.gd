extends Node
## Renders every icon on one sheet for review.
##   xvfb-run godot --path . res://tests/capture_icons.tscn -- <out_dir>
const IDS := [&"ash_bandage", &"ember_shard", &"stamina_tonic", &"rusted_key", &"warden_bell_shard", &"penitents_tear",
	&"candlewright_note", &"canon_seal", &"oathblade", &"twin_blades", &"sword_and_shield", &"fists",
	&"armor_sworn_knight", &"armor_duelist", &"armor_bulwark", &"armor_unsworn", &"status"]

func _ready() -> void:
	var out := "user://screens"
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var layer := CanvasLayer.new()
	add_child(layer)
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(func():
		c.draw_rect(Rect2(Vector2.ZERO, Vector2(480, 270)), Color(0.08, 0.07, 0.09))
		for i in IDS.size():
			var r := Rect2(Vector2(14 + (i % 6) * 76, 14 + (i / 6) * 84), Vector2(56, 56))
			c.draw_rect(r, Color(0.12, 0.11, 0.14))
			IconArt.draw(c, IDS[i], r.grow(-6))
			c.draw_string(ThemeDB.fallback_font, r.position + Vector2(0, 68), String(IDS[i]), HORIZONTAL_ALIGNMENT_LEFT, 76, 7, Color(0.8, 0.8, 0.8)))
	layer.add_child(c)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("icons.png"))
	get_tree().quit()
