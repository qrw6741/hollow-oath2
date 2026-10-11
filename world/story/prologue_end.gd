class_name PrologueEnd
extends Node
## Placed in the true Vaelmoor. On first arrival it marks the prologue (the tutorial
## world) as complete, announces it, and saves.

const FLAG := &"prologue_complete"


func _ready() -> void:
	if GameState.get_flag(FLAG, false):
		return
	GameState.set_flag(FLAG, true)
	_announce.call_deferred()


func _announce() -> void:
	await get_tree().create_timer(4.0, false).timeout
	if not is_inside_tree():
		return
	Events.banner_requested.emit("PROLOGUE COMPLETE")
	Audio.sfx(&"levelup")
	SaveSystem.autosave()
