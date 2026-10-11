class_name HealthComponent
extends Node
## Hit points for any actor. Emits signals; never decides what death means.

signal changed(current: float, maximum: float)
signal damaged(amount: float)
signal healed(amount: float)
signal died

@export var max_health := 100.0

var current := 100.0
var is_dead := false


func _ready() -> void:
	current = max_health


## Returns the damage actually applied.
func take_damage(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied := minf(amount, current)
	current -= applied
	damaged.emit(applied)
	changed.emit(current, max_health)
	if current <= 0.0:
		current = 0.0
		is_dead = true
		died.emit()
	return applied


## Returns the health actually restored.
func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied := minf(amount, max_health - current)
	current += applied
	healed.emit(applied)
	changed.emit(current, max_health)
	return applied


func restore_full() -> void:
	is_dead = false
	current = max_health
	changed.emit(current, max_health)


func set_max(value: float, refill := true) -> void:
	max_health = maxf(1.0, value)
	current = max_health if refill else minf(current, max_health)
	changed.emit(current, max_health)


func ratio() -> float:
	return current / max_health
