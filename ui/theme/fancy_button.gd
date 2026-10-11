class_name FancyButton
extends Button
## Button with small gold diamonds beside it while focused or hovered, so the current
## choice is obvious from across the room (and for gamepad users). Same API as Button.


func _ready() -> void:
	pressed.connect(func(): Audio.sfx(&"ui_select", -3.0))
	focus_entered.connect(func(): if is_visible_in_tree(): Audio.sfx(&"ui_move", -6.0))


func _draw() -> void:
	if disabled or not (has_focus() or is_hovered()):
		return
	var cy := size.y / 2.0
	for x in [3.0, size.x - 3.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 2.5, cy), Vector2(x, cy - 2.5), Vector2(x + 2.5, cy), Vector2(x, cy + 2.5)]), Palette.GOLD_BRIGHT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT \
		or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()
