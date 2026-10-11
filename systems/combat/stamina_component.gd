class_name StaminaComponent
extends Node
## Stamina pool. An action is allowed while stamina is above zero; the cost may
## overdraw into zero (classic Soulslike leniency), followed by a regen delay.

signal changed(current: float, maximum: float)
signal exhausted

@export var max_stamina := 100.0
@export var regen_per_second := 55.0
## Seconds after spending before regeneration resumes.
@export var regen_delay := 0.55
## Extra delay when the pool hits zero.
@export var exhausted_delay := 1.0

var current := 100.0
## Multiplier set by the owner (e.g. 0.3 while healing).
var regen_multiplier := 1.0
var _delay_left := 0.0


func _ready() -> void:
	current = max_stamina


func can_spend() -> bool:
	return current > 0.0


func spend(cost: float) -> bool:
	if not can_spend():
		return false
	current = maxf(0.0, current - cost)
	_delay_left = regen_delay
	if current <= 0.0:
		_delay_left = exhausted_delay
		exhausted.emit()
	changed.emit(current, max_stamina)
	return true


func refund(amount: float) -> void:
	current = minf(max_stamina, current + amount)
	changed.emit(current, max_stamina)


func restore_full() -> void:
	current = max_stamina
	_delay_left = 0.0
	changed.emit(current, max_stamina)


func _physics_process(delta: float) -> void:
	if _delay_left > 0.0:
		_delay_left -= delta
		return
	if current < max_stamina:
		current = minf(max_stamina, current + regen_per_second * regen_multiplier * delta)
		changed.emit(current, max_stamina)
