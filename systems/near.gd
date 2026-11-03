class_name Near
extends RefCounted
## Cheap "is this thing close enough to the player to be worth redrawing / animating?" test, so a very long
## level does not redraw hundreds of far-away props every frame.

const RANGE := 900.0


static func player(n: Node) -> bool:
	if not n.is_inside_tree():
		return true
	var p := n.get_tree().get_first_node_in_group(&"player") as Node2D
	if p == null:
		return true
	return absf(p.global_position.x - (n as Node2D).global_position.x) < RANGE
