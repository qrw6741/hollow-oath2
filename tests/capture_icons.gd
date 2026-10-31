extends Control
## Contact sheet of every talisman icon (big and inventory size). xvfb-run godot --path . res://tests/capture_icons.tscn -- <out.png>
var out := "/tmp/icons.png"
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	size = Vector2(480, 270)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.06, 0.09))
	var i := 0
	for id in TalismanData.IDS:
		var x := 4 + (i % 12) * 39
		var y := 10 + (i / 12) * 62
		IconArt.draw(self, id, Rect2(x, y, 36, 36), 1.0)
		IconArt.draw(self, id, Rect2(x + 7, y + 38, 22, 22), 1.0)
		i += 1
