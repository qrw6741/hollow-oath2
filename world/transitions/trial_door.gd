@tool
class_name TrialDoor
extends LevelExit
## The door to the Trial Ring. It opens for anyone who has decided at the Oath Gate.

func try_open() -> bool:
	if Endings.chosen() == &"":
		Audio.sfx(&"door_locked")
		Events.banner_requested.emit("The Ring answers only those who have decided at the Oath Gate.")
		return false
	Audio.sfx(&"door_open")
	Events.interact_prompt_hidden.emit()
	_go()
	return true
