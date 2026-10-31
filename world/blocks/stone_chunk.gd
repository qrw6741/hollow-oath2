class_name StoneChunk
extends Node2D
## One slice of a wide StoneBlock. Separate canvas items let the renderer skip the slices that are off screen
## (a 3,000 px floor used to be submitted whole every frame, thousands of draw calls).

var block: StoneBlock
var x0 := 0.0
var x1 := 0.0


func _draw() -> void:
	if block:
		block._paint(self, x0, x1)
