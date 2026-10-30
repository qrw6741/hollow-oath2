class_name StatusComponent
extends Node2D
## Tracks status buildup and active effects for one actor (enemy or player) and draws small
## pips above its head. The owner must expose a `health` HealthComponent.

signal triggered(kind: StringName)
signal changed

var health: HealthComponent
## kind -> fraction (see Status). Owners set this.
var resist := {}
var buildup := {}
var active := {}
var _idle := {}
var _tick := 0.0
var tint_owner := true


func _ready() -> void:
	z_index = 20
	position = Vector2(0, -52)
	for k in StatusFx.KINDS:
		buildup[k] = 0.0


func is_active(kind: StringName) -> bool:
	return active.has(kind)


func any_active() -> bool:
	return not active.is_empty()


## Movement multiplier from frost (1.0 when none).
func speed_mult() -> float:
	return StatusFx.FROST_SLOW if active.has(StatusFx.FROST) else 1.0


func resist_of(kind: StringName) -> float:
	return StatusFx.lookup(resist, kind)


## Adds buildup. Returns true if the effect triggered this call.
func apply(kind: StringName, amount: float) -> bool:
	if not StatusFx.is_kind(kind) or amount <= 0.0 or health == null or health.is_dead:
		return false
	var r := resist_of(kind)
	if r >= 1.0 or active.has(kind):
		return false
	buildup[kind] = float(buildup.get(kind, 0.0)) + amount * (1.0 - r)
	Events.tip_requested.emit(&"status")
	_idle[kind] = 0.0
	changed.emit()
	if buildup[kind] >= StatusFx.THRESHOLD:
		buildup[kind] = 0.0
		_trigger(kind)
		return true
	queue_redraw()
	return false


func clear() -> void:
	for k in StatusFx.KINDS:
		buildup[k] = 0.0
	active.clear()
	_idle.clear()
	changed.emit()
	queue_redraw()


func _trigger(kind: StringName) -> void:
	active[kind] = float(StatusFx.DURATIONS[kind])
	var at := (get_parent() as Node2D).global_position + Vector2(0, -20) if get_parent() is Node2D else global_position
	GameFeel.spark(at, StatusFx.color_of(kind), 16)
	if kind == StatusFx.BLEED:
		_hurt(health.max_health * StatusFx.BLEED_BURST, true)
	triggered.emit(kind)
	if not (get_parent() is Player):
		Events.status_triggered.emit(kind)
	changed.emit()


func _hurt(amount: float, burst := false) -> void:
	var applied := health.take_damage(maxf(1.0, amount))
	var p := get_parent()
	if p is Node2D and p.is_in_group(&"enemies"):
		GameFeel.damage_number((p as Node2D).global_position + Vector2(0, -44), applied, burst)
	if p and p.has_method(&"on_status_damage"):
		p.on_status_damage(applied)


func _physics_process(delta: float) -> void:
	if health == null or health.is_dead:
		if not active.is_empty():
			clear()
		return
	var dirty := false
	for k in StatusFx.KINDS:
		if active.has(k):
			active[k] -= delta
			if active[k] <= 0.0:
				active.erase(k)
				dirty = true
		elif float(buildup[k]) > 0.0:
			_idle[k] = float(_idle.get(k, 0.0)) + delta
			if _idle[k] > 3.0:
				buildup[k] = maxf(0.0, float(buildup[k]) - 20.0 * delta)
				dirty = true
	_tick += delta
	if _tick >= 1.0:
		_tick -= 1.0
		if active.has(StatusFx.POISON):
			_hurt(health.max_health * StatusFx.POISON_PER_SEC)
		if active.has(StatusFx.BURN):
			_hurt(health.max_health * StatusFx.BURN_PER_SEC)
	if dirty or not active.is_empty():
		changed.emit()
		queue_redraw()


func _draw() -> void:
	var shown: Array[StringName] = []
	for k in StatusFx.KINDS:
		if active.has(k) or float(buildup.get(k, 0.0)) > 1.0:
			shown.append(k)
	if shown.is_empty():
		return
	var x0 := -(shown.size() - 1) * 4.0
	for i in shown.size():
		var k := shown[i]
		var c: Color = StatusFx.color_of(k)
		var at := Vector2(x0 + i * 8.0, 0)
		if active.has(k):
			draw_circle(at, 3.0, c)
			draw_arc(at, 3.8, 0, TAU, 12, Color(1, 1, 1, 0.6), 0.8)
		else:
			draw_arc(at, 3.0, -PI / 2.0, -PI / 2.0 + TAU * float(buildup[k]) / StatusFx.THRESHOLD, 12, c, 1.6)
