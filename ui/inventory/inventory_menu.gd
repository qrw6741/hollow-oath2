class_name InventoryMenu
extends CanvasLayer
## The character screen. Two tabs:
##   EQUIPMENT — your character drawn large (current preset, armour and weapon), level and
##               embers; slots for Weapon, Armour, Quick item and Status. Selecting a slot
##               shows its numbers: weapon damage per hit (Strength included), speed, reach,
##               stamina; armour damage taken, health, stamina, vials, handling; full status.
##   ITEMS     — the pack: carried items, descriptions, Use and "Set as quick item".
## Opens with Inventory (Tab / Create) or from the pause and candle menus; pauses the game.
## Switch tabs with Parry / Heal (L1 / R1) or by clicking. Keyboard, mouse and gamepad.

enum Tab { EQUIPMENT, ITEMS }

var is_open := false
var tab := Tab.EQUIPMENT
var _was_paused := false
var _prev_modal := false
var _panel: ColorRect
var _tab_btns: Array[Button] = []
var _pages: Array[Control] = []
var _close_btn: Button
# Equipment tab
var _preview: Node2D
var _char_name: Label
var _char_level: Label
var _slots := {}               # key -> Button
var _slot_sel := "weapon"
var _d_title: Label
var _d_sub: Label
var _d_grid: GridContainer
var _d_desc: Label
# Items tab (names kept for tests and other menus)
var _list: VBoxContainer
var _name: Label
var _kind: Label
var _desc: Label
var _msg: Label
var _use_btn: Button
var _quick_btn: Button
var _selected: StringName = &""


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false
	Events.inventory_menu_requested.connect(open)
	Events.inventory_changed.connect(func(): if is_open: _rebuild(); _refresh_equipment())
	Events.stats_changed.connect(func(): if is_open: _refresh_equipment())


# ------------------------------------------------------------------ building

func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(Palette.INK, 0.96)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	add_child(_panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -14
	_panel.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 4)
	center.add_child(v)
	# Tabs
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override(&"separation", 18)
	v.add_child(tabs)
	for i in 2:
		var b := FancyButton.new()
		b.text = ["EQUIPMENT", "ITEMS"][i]
		b.custom_minimum_size = Vector2(110, 18)
		b.add_theme_font_override(&"font", UITheme.title_font())
		b.add_theme_font_size_override(&"font_size", 12)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(show_tab.bind(i))
		tabs.add_child(b)
		_tab_btns.append(b)
	v.add_child(UITheme.rule(300))
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(460, 194)
	v.add_child(stack)
	_pages.append(_build_equipment(stack))
	_pages.append(_build_items(stack))
	_close_btn = FancyButton.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(110, 15)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_btn.pressed.connect(close)
	UITheme.compact(_close_btn)
	v.add_child(_close_btn)
	var hint := HintBar.new()
	hint.spec = "inventory:close,parry:prev tab,heal:next tab,use_item:quick item"
	v.add_child(hint)


func _framed(parent: Control, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = size
	parent.add_child(p)
	UITheme.frame(p)
	return p


func _build_equipment(stack: Control) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 6)
	stack.add_child(h)
	# A — the character
	var a := _framed(h, Vector2(118, 194))
	var av := VBoxContainer.new()
	av.add_theme_constant_override(&"separation", 2)
	a.add_child(av)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(100, 128)
	stage.clip_contents = true
	stage.draw.connect(func():
		var c := Vector2(50, 116)
		for r in [30.0, 22.0, 14.0]:
			stage.draw_circle(c + Vector2(0, -50), r * 1.6, Color(Palette.GOLD, 0.035))
		stage.draw_set_transform(c, 0.0, Vector2(1.0, 0.25))
		stage.draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.45))
		stage.draw_circle(Vector2.ZERO, 30.0, Color(Palette.STONE, 0.35))
		stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	av.add_child(stage)
	_preview = Node2D.new()
	_preview.set_script(load("res://actors/player/player_visual.gd"))
	_preview.set("preview", true)
	_preview.position = Vector2(50, 116)
	_preview.scale = Vector2(3.4, 3.4)
	stage.add_child(_preview)
	_char_name = Label.new()
	_char_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(_char_name, 11, Palette.GOLD_BRIGHT)
	av.add_child(_char_name)
	_char_level = Label.new()
	_char_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_level.add_theme_color_override(&"font_color", Palette.BONE)
	av.add_child(_char_level)
	# B — slots
	var b := _framed(h, Vector2(124, 194))
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override(&"separation", 3)
	b.add_child(bv)
	for key in ["weapon", "armour", "quick", "status"]:
		var head := Label.new()
		head.text = {"weapon": "WEAPON", "armour": "ARMOUR", "quick": "QUICK ITEM", "status": "STATUS"}[key]
		UITheme.title(head, 8, Palette.BONE_DIM)
		bv.add_child(head)
		var s := FancyButton.new()
		s.name = "Slot_" + key
		s.alignment = HORIZONTAL_ALIGNMENT_LEFT
		s.custom_minimum_size = Vector2(112, 18)
		s.clip_text = true
		UITheme.compact(s)
		s.focus_entered.connect(_select_slot.bind(key))
		s.mouse_entered.connect(s.grab_focus)
		bv.add_child(s)
		_slots[key] = s
	# C — details
	var c := _framed(h, Vector2(206, 194))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override(&"separation", 2)
	c.add_child(cv)
	_d_title = Label.new()
	UITheme.title(_d_title, 12, Palette.GOLD_BRIGHT)
	cv.add_child(_d_title)
	_d_sub = Label.new()
	_d_sub.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	cv.add_child(_d_sub)
	_d_grid = GridContainer.new()
	_d_grid.columns = 2
	_d_grid.add_theme_constant_override(&"h_separation", 10)
	_d_grid.add_theme_constant_override(&"v_separation", 0)
	cv.add_child(_d_grid)
	_d_desc = Label.new()
	_d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_desc.custom_minimum_size = Vector2(190, 0)
	_d_desc.add_theme_constant_override(&"line_spacing", -2)
	_d_desc.add_theme_font_size_override(&"font_size", 7)
	_d_desc.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	cv.add_child(_d_desc)
	return h


func _build_items(stack: Control) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	stack.add_child(h)
	var left := _framed(h, Vector2(170, 194))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 1)
	left.add_child(_list)
	var right := _framed(h, Vector2(282, 194))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 4)
	right.add_child(rv)
	_name = Label.new()
	UITheme.title(_name, 13, Palette.GOLD_BRIGHT)
	rv.add_child(_name)
	_kind = Label.new()
	_kind.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	rv.add_child(_kind)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(262, 60)
	_desc.add_theme_constant_override(&"line_spacing", -2)
	rv.add_child(_desc)
	_msg = Label.new()
	_msg.add_theme_color_override(&"font_color", Palette.CRIMSON_BRIGHT)
	_msg.custom_minimum_size.y = 10
	rv.add_child(_msg)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(spacer)
	_use_btn = _btn(rv, "Use", _on_use)
	_quick_btn = _btn(rv, "Set as quick item", _on_quick)
	return h


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := FancyButton.new()
	b.text = text
	b.custom_minimum_size = Vector2(130, 15)
	b.pressed.connect(cb)
	UITheme.compact(b)
	parent.add_child(b)
	return b


# ------------------------------------------------------------------ open / close / tabs

func _unhandled_input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"inventory") or event.is_action_pressed(&"pause"):
			close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"parry") or event.is_action_pressed(&"heal"):
			show_tab(Tab.ITEMS if tab == Tab.EQUIPMENT else Tab.EQUIPMENT)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"inventory") and GameState.in_game and not GameState.ui_modal and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()


func open(start_tab := Tab.EQUIPMENT) -> void:
	if is_open:
		return
	is_open = true
	_was_paused = get_tree().paused
	_prev_modal = GameState.ui_modal
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	_msg.text = ""
	_panel.visible = true
	_rebuild()
	show_tab(start_tab)


func close() -> void:
	if not is_open:
		return
	Audio.sfx(&"ui_back")
	is_open = false
	_panel.visible = false
	get_tree().paused = _was_paused
	GameState.ui_modal = _prev_modal
	Events.inventory_menu_closed.emit()


func show_tab(t: int) -> void:
	tab = t as Tab
	for i in _pages.size():
		_pages[i].visible = i == t
		_tab_btns[i].add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if i == t else Palette.STONE_LIGHT)
	if tab == Tab.EQUIPMENT:
		_refresh_equipment()
		(_slots[_slot_sel] as Button).grab_focus()
	else:
		_rebuild()
	Audio.sfx(&"ui_move", -4.0)


# ------------------------------------------------------------------ equipment tab

func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _preset() -> PresetData:
	var p := _player()
	if p and p.preset:
		return p.preset
	return Presets.get_preset(GameState.preset_id)


func _strength_bonus() -> float:
	return 1.0 + int(GameState.stats.get("strength", 0)) * GameState.STRENGTH_DAMAGE


func _refresh_equipment() -> void:
	var pr := _preset()
	_preview.set("preset", pr)
	_char_name.text = pr.display_name
	_char_level.text = "Level %d      %d embers" % [GameState.level(), GameState.embers]
	(_slots.weapon as Button).text = pr.weapon.display_name if pr.weapon else "-"
	(_slots.armour as Button).text = pr.armor_name if pr.armor_name != "" else "-"
	var qi := Items.get_item(GameState.quick_item)
	(_slots.quick as Button).text = ("%s  x%d" % [qi.display_name, GameState.item_count(GameState.quick_item)]) if qi and GameState.item_count(GameState.quick_item) > 0 else "(none)"
	(_slots.status as Button).text = "Level %d" % GameState.level()
	_select_slot(_slot_sel)


func _select_slot(key: String) -> void:
	_slot_sel = key
	for c in _d_grid.get_children():
		_d_grid.remove_child(c)
		c.queue_free()
	var pr := _preset()
	var p := _player()
	match key:
		"weapon":
			var s := WeaponStats.summary(pr.weapon, _strength_bonus())
			_d_title.text = s.name
			_d_sub.text = "Weapon  -  %s, %s reach" % [s.speed, (s.reach as String).to_lower()]
			var light: Array = s.light
			_row("Light combo", " / ".join(light.map(func(x): return str(x))) + "  (%d total)" % s.light_total)
			_row("Heavy", "%d" % s.heavy)
			_row("Aerial", "%d" % s.aerial)
			_row("Riposte", "%d" % s.riposte)
			_row("Stamina per swing", "%d  (heavy %d)" % [s.stamina, s.heavy_stamina])
			_row("Poise damage", "%d" % s.poise)
			_row("Strength bonus", "+%d%%" % roundi((_strength_bonus() - 1.0) * 100.0))
			_d_desc.text = pr.weapon.description if pr.weapon else ""
		"armour":
			_d_title.text = pr.armor_name
			_d_sub.text = "Armour  -  " + ("none" if pr.armor_look == PresetData.ArmorLook.BARE else ["", "light", "medium", "heavy"][pr.armor_look])
			var taken := roundi(pr.damage_taken_mult * 100.0)
			_row("Damage taken", "%d%%  %s" % [taken, "(less)" if taken < 100 else ("(more)" if taken > 100 else "")])
			_row("Base health", "%d" % roundi(pr.max_health))
			_row("Base stamina", "%d" % roundi(pr.max_stamina))
			_row("Ember Vials", "%d  (heal %d each)" % [pr.flasks, roundi(pr.flask_heal)])
			_row("Run speed", "%d%%" % roundi(pr.run_speed_mult * 100.0))
			_row("Dodge cost", "%d stamina" % roundi(pr.dodge_stamina))
			_row("Parry window", "%d frames" % pr.parry_window_frames)
			_d_desc.text = pr.armor_description
		"quick":
			var it := Items.get_item(GameState.quick_item)
			if it and GameState.item_count(GameState.quick_item) > 0:
				_d_title.text = it.display_name
				_d_sub.text = "Quick item  -  use with the quick item button"
				_row("Carried", "%d / %d" % [GameState.item_count(GameState.quick_item), it.max_stack])
				var eff: String = ["-", "Restores %d health", "Restores %d stamina", "Grants %d embers"][it.effect]
				_row("Effect", eff % roundi(it.effect_amount) if it.effect != ItemData.Effect.NONE else "-")
				_d_desc.text = it.description
			else:
				_d_title.text = "No quick item"
				_d_sub.text = "Choose one in the Items tab"
				_d_desc.text = ""
		"status":
			_d_title.text = "Status"
			_d_sub.text = "%s  -  Level %d" % [pr.display_name, GameState.level()]
			var vig := int(GameState.stats.get("vigor", 0))
			var endu := int(GameState.stats.get("endurance", 0))
			var stre := int(GameState.stats.get("strength", 0))
			var hp_now := p.health.current if p else pr.max_health
			var hp_max := p.health.max_health if p else pr.max_health + vig * GameState.VIGOR_HEALTH
			var st_max := p.stamina.max_stamina if p else pr.max_stamina + endu * GameState.ENDURANCE_STAMINA
			_row("Health", "%d / %d" % [roundi(hp_now), roundi(hp_max)])
			_row("Stamina", "%d" % roundi(st_max))
			_row("Vigor", "%d   (+%d health)" % [vig, roundi(vig * GameState.VIGOR_HEALTH)])
			_row("Endurance", "%d   (+%d stamina)" % [endu, roundi(endu * GameState.ENDURANCE_STAMINA)])
			_row("Strength", "%d   (+%d%% damage)" % [stre, roundi(stre * GameState.STRENGTH_DAMAGE * 100.0)])
			_row("Embers", "%d   (next level %d)" % [GameState.embers, GameState.level_cost()])
			var secs := int(GameState.play_time)
			_row("Deaths  /  time", "%d   /   %02d:%02d" % [GameState.deaths, secs / 3600, (secs / 60) % 60])
			_d_desc.text = "Raise Vigor, Endurance and Strength by resting at an Oath Candle."


func _row(label: String, value: String) -> void:
	var a := Label.new()
	a.text = label
	a.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	_d_grid.add_child(a)
	var b := Label.new()
	b.text = value
	b.add_theme_color_override(&"font_color", Palette.BONE)
	_d_grid.add_child(b)


# ------------------------------------------------------------------ items tab

func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var first: Button
	var found := false
	for id in Items.IDS:
		var n := GameState.item_count(id)
		if n <= 0:
			continue
		var item := Items.get_item(id)
		var b := FancyButton.new()
		b.text = "%s%s%s" % [item.display_name, "  x%d" % n if n > 1 else "", "   [quick]" if id == GameState.quick_item else ""]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(160, 14)
		UITheme.compact(b)
		b.focus_entered.connect(_select.bind(id))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_select.bind(id))
		_list.add_child(b)
		if first == null:
			first = b
		if id == _selected:
			first = b
			found = true
	if _list.get_child_count() == 0:
		var l := Label.new()
		l.text = "Your pack is empty."
		l.add_theme_color_override(&"font_color", Palette.BONE_DIM)
		_list.add_child(l)
		_selected = &""
		_show_detail()
		if tab == Tab.ITEMS:
			_close_btn.grab_focus()
		return
	if not found:
		_selected = &""
	if tab == Tab.ITEMS:
		first.grab_focus()
	_show_detail()


func _select(id: StringName) -> void:
	_selected = id
	_msg.text = ""
	_show_detail()


func _show_detail() -> void:
	var item := Items.get_item(_selected)
	_use_btn.visible = item != null and item.is_usable()
	_quick_btn.visible = _use_btn.visible
	if item == null:
		_name.text = ""
		_kind.text = ""
		_desc.text = ""
		return
	_name.text = item.display_name
	_kind.text = ["Consumable", "Key item", "Lore"][item.kind]
	_desc.text = item.description
	_quick_btn.disabled = _selected == GameState.quick_item
	_quick_btn.text = "Quick item (set)" if _quick_btn.disabled else "Set as quick item"


func _on_use() -> void:
	var p := _player()
	if Items.use(_selected, p):
		_msg.text = ""
	else:
		_msg.text = "That would have no effect right now."


func _on_quick() -> void:
	GameState.quick_item = _selected
	Events.inventory_changed.emit()
