class_name InventoryMenu
extends CanvasLayer
## The character screen. Two tabs:
##   EQUIPMENT — your character drawn large (current preset, armour and weapon), level and
##               embers; slots for Weapon, Armour, Quick item and Status. Selecting a slot
##               shows its numbers: weapon damage per hit (Strength included), speed, reach,
##               stamina; armour damage taken, health, stamina, vials, handling; full status.
##   ITEMS     — the pack: carried items, descriptions, Use and "Set as quick item".
## Opens with Inventory (Tab / Create) or from the pause and candle menus; pauses the game.
## A JOURNAL tab lists open errands (see Quests).
## Switch tabs with Parry / Heal (L1 / R1) or by clicking. Keyboard, mouse and gamepad.

enum Tab { EQUIPMENT, ITEMS, WEAPONS, JOURNAL, BESTIARY, DEEDS, RELICS, ARTS, TALISMANS, ALCHEMY }

var is_open := false
var tab := Tab.EQUIPMENT
var _was_paused := false
var _prev_modal := false
var _panel: ColorRect
var _tab_btns: Array[Button] = []
var _w_slots: Array[IconSlot] = []
var _w_head: Label
var _w_big: IconSlot
var _w_name: Label
var _w_state: Label
var _w_text: Label
var _relic_list: VBoxContainer
var _relic_head: Label
var _relic_btns: Array[Button] = []
var _tal_list: VBoxContainer
var _tal_head: Label
var _tal_btns: Array[Button] = []
var _alc_list: VBoxContainer
var _alc_head: Label
var _alc_buffs: Label
var _alc_btns: Array[Button] = []
var _bestiary_label: Label
var _deeds_label: Label
var _pages: Array[Control] = []
var _close_btn: Button
# Equipment tab
var _preview: Node2D
var _char_name: Label
var _char_level: Label
var _slots := {}               # key -> Button
var _slot_sel := "weapon"
var _d_title: Label
var _d_icon: Control
var _d_icon_id: StringName = &""
var _i_icon: Control
var _i_icon_id: StringName = &""
var _d_sub: Label
var _d_grid: GridContainer
var _d_desc: Label
var _picker: VBoxContainer
var _picking := ""            # "" | "weapon" | "armour"
var picker_buttons: Array = []   # [{"id": StringName, "button": Button}]
# Items tab (names kept for tests and other menus)
var _list: GridContainer
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
	Events.loadout_changed.connect(func(): if is_open and _picking == "": _refresh_equipment())


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
	tabs.add_theme_constant_override(&"separation", 2)
	v.add_child(tabs)
	for i in 10:
		var b := FancyButton.new()
		b.text = ["GEAR", "ITEMS", "WEAPONS", "JOURNAL", "BESTIARY", "DEEDS", "RELICS", "ARTS", "TALISMANS", "ALCHEMY"][i]
		b.custom_minimum_size = Vector2(36, 18)
		b.add_theme_font_override(&"font", UITheme.title_font())
		b.add_theme_font_size_override(&"font_size", 6)
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
	_pages.append(_build_weapons(stack))
	_pages.append(_build_journal(stack))
	_pages.append(_build_scroll_text(stack, "_bestiary_label"))
	_pages.append(_build_scroll_text(stack, "_deeds_label"))
	_pages.append(_build_relics(stack))
	_pages.append(_build_arts(stack))
	_pages.append(_build_talismans(stack))
	_pages.append(_build_alchemy(stack))
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
	# B — slots: icons, not text
	var b := _framed(h, Vector2(124, 194))
	var bv := VBoxContainer.new()
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(bv)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bv.add_child(grid)
	for key in ["weapon", "armour", "quick", "status"]:
		var s := IconSlot.new()
		s.name = "Slot_" + key
		s.custom_minimum_size = Vector2(48, 58)
		s.caption = {"weapon": "Weapon", "armour": "Armour", "quick": "Item", "status": "Status"}[key]
		s.focus_entered.connect(_select_slot.bind(key))
		if key == "weapon" or key == "armour":
			s.pressed.connect(open_picker.bind(key))
		s.mouse_entered.connect(s.grab_focus)
		grid.add_child(s)
		_slots[key] = s
	# C — details
	var c := _framed(h, Vector2(206, 194))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override(&"separation", 2)
	c.add_child(cv)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 6)
	cv.add_child(head)
	_d_icon = Control.new()
	_d_icon.custom_minimum_size = Vector2(26, 26)
	_d_icon.draw.connect(func(): if _d_icon_id != &"": IconArt.draw(_d_icon, _d_icon_id, Rect2(Vector2.ZERO, _d_icon.size)))
	head.add_child(_d_icon)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override(&"separation", 0)
	head.add_child(hv)
	_d_title = Label.new()
	UITheme.title(_d_title, 12, Palette.GOLD_BRIGHT)
	hv.add_child(_d_title)
	_d_sub = Label.new()
	_d_sub.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	hv.add_child(_d_sub)
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
	_picker = VBoxContainer.new()
	_picker.add_theme_constant_override(&"separation", 1)
	_picker.visible = false
	cv.add_child(_picker)
	return h


func _build_items(stack: Control) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	stack.add_child(h)
	var left := _framed(h, Vector2(170, 194))
	_list = GridContainer.new()
	_list.columns = 5
	_list.add_theme_constant_override(&"h_separation", 3)
	_list.add_theme_constant_override(&"v_separation", 3)
	left.add_child(_list)
	var right := _framed(h, Vector2(282, 194))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 4)
	right.add_child(rv)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override(&"separation", 8)
	rv.add_child(ih)
	_i_icon = Control.new()
	_i_icon.custom_minimum_size = Vector2(36, 36)
	_i_icon.draw.connect(func(): if _i_icon_id != &"": IconArt.draw(_i_icon, _i_icon_id, Rect2(Vector2.ZERO, _i_icon.size)))
	ih.add_child(_i_icon)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override(&"separation", 0)
	ih.add_child(iv)
	_name = Label.new()
	UITheme.title(_name, 13, Palette.GOLD_BRIGHT)
	iv.add_child(_name)
	_kind = Label.new()
	_kind.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	iv.add_child(_kind)
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


var _journal_label: Label


func _build_journal(stack: Control) -> Control:
	var p := _framed(stack, Vector2(460, 194))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	_journal_label = Label.new()
	_journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_label.custom_minimum_size = Vector2(440, 0)
	_journal_label.add_theme_constant_override(&"line_spacing", -2)
	sc.add_child(_journal_label)
	return p


func _build_weapons(stack: Control) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 6)
	stack.add_child(h)
	var left := _framed(h, Vector2(230, 194))
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override(&"separation", 4)
	left.add_child(lv)
	_w_head = Label.new()
	UITheme.title(_w_head, 10, Palette.GOLD_BRIGHT)
	_w_head.add_theme_font_override(&"font", UITheme.body_font())
	lv.add_child(_w_head)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	lv.add_child(grid)
	for id in Weapons.IDS:
		var s := IconSlot.new()
		s.custom_minimum_size = Vector2(38, 38)
		s.pressed.connect(_weapon_pressed.bind(id))
		s.focus_entered.connect(_show_weapon.bind(id))
		s.mouse_entered.connect(_show_weapon.bind(id))
		grid.add_child(s)
		_w_slots.append(s)
	var right := _framed(h, Vector2(224, 194))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 3)
	right.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 7)
	rv.add_child(top)
	_w_big = IconSlot.new()
	_w_big.custom_minimum_size = Vector2(44, 44)
	_w_big.focus_mode = Control.FOCUS_NONE
	_w_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_w_big)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override(&"separation", 0)
	top.add_child(tv)
	_w_name = Label.new()
	UITheme.title(_w_name, 11, Palette.GOLD_BRIGHT)
	tv.add_child(_w_name)
	_w_state = Label.new()
	_w_state.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	tv.add_child(_w_state)
	_w_text = Label.new()
	_w_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_w_text.custom_minimum_size = Vector2(206, 0)
	_w_text.add_theme_color_override(&"font_color", Palette.BONE)
	_w_text.add_theme_constant_override(&"line_spacing", -2)
	rv.add_child(_w_text)
	return h


## Every weapon in the game: ones you have are drawn, the rest stay a grey "?".
func _refresh_weapons() -> void:
	var have := 0
	for i in Weapons.IDS.size():
		var id: StringName = Weapons.IDS[i]
		var owned := GameState.owns_weapon(id)
		have += 1 if owned else 0
		_w_slots[i].icon_id = id if owned else &""
		_w_slots[i].locked = not owned
		_w_slots[i].marked = id == GameState.weapon_id
	_w_head.text = "WEAPONS    found %d / %d" % [have, Weapons.IDS.size()]
	_show_weapon(GameState.weapon_id if GameState.owns_weapon(GameState.weapon_id) else Weapons.IDS[0])
	_w_slots[0].grab_focus.call_deferred()


func _show_weapon(id: StringName) -> void:
	var owned := GameState.owns_weapon(id)
	_w_big.icon_id = id if owned else &""
	_w_big.locked = not owned
	if not owned:
		_w_name.text = "???"
		_w_state.text = "Not yet found"
		_w_text.text = "Somewhere in Vaelmoor there is a weapon for this slot. Explore, defeat what guards it, or ask the smith."
		if Weapons.HINTS.has(id):
			_w_text.text = "Where to find it: " + String(Weapons.HINTS[id])
		return
	var w := Weapons.get_weapon(id)
	var lvl := GameState.weapon_level(id)
	_w_name.text = w.display_name
	_w_state.text = "Equipped" if id == GameState.weapon_id else "Found  (+%d)   press to equip" % lvl
	var b := (1.0 + int(GameState.stats.get("strength", 0)) * GameState.STRENGTH_DAMAGE) * Weapons.level_mult(lvl) * w.damage_mult
	var sm := WeaponStats.summary(w, b)
	var t := w.description + "\n\nLight combo %d   Heavy %d" % [sm.light_total, sm.heavy]
	if w.skill:
		t += "\nSkill: %s (%d focus)" % [w.skill.display_name, roundi(w.skill_cost)]
	var fx := Forge.effective_status(w)
	if fx.kind != &"":
		t += "\nInflicts %s" % StatusFx.name_of(fx.kind)
	_w_text.text = t


func _weapon_pressed(id: StringName) -> void:
	if GameState.owns_weapon(id) and Loadout.equip_weapon(id):
		_msg.text = "Equipped %s." % Weapons.get_weapon(id).display_name
		_refresh_weapons()
		_show_weapon(id)


## A vertical list inside a scroll area (focus scrolls it), for tabs that can grow long.
func _scroll_list(parent: Control) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(430, 150)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	parent.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 2)
	sc.add_child(list)
	return list


func _build_talismans(stack: Control) -> Control:
	var p := _framed(stack, Vector2(460, 194))
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	p.add_child(v)
	_tal_head = Label.new()
	UITheme.title(_tal_head, 10, Palette.GOLD_BRIGHT)
	_tal_head.add_theme_font_override(&"font", UITheme.body_font())
	v.add_child(_tal_head)
	_tal_list = _scroll_list(v)
	return p


## Every talisman you carry, [x] when worn. Press to wear / remove (up to Talismans.SLOTS).
func _refresh_talismans() -> void:
	for c in _tal_list.get_children():
		_tal_list.remove_child(c)
		c.queue_free()
	_tal_btns.clear()
	_tal_head.text = "TALISMANS    worn %d / %d    %d found" % [Talismans.equipped().size(), Talismans.SLOTS, _talisman_count()]
	for id in TalismanData.IDS:
		if not Talismans.owned(id):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var slot := IconSlot.new()
		slot.custom_minimum_size = Vector2(22, 22)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.icon_id = id
		row.add_child(slot)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(396, 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s  %s    %s" % ["[x]" if Talismans.is_worn(id) else "[ ]", Talismans.title(id), Talismans.describe(Talismans.effects_of(id))]
		UITheme.compact(b)
		b.pressed.connect(func():
			var r := Talismans.toggle(id)
			_msg.text = r.msg
			_refresh_talismans())
		row.add_child(b)
		_tal_list.add_child(row)
		_tal_btns.append(b)
	if _tal_btns.is_empty():
		var l := Label.new()
		l.text = "No talismans yet. Bosses always leave one; elite foes sometimes do."
		l.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
		_tal_list.add_child(l)
	else:
		_tal_btns[0].grab_focus.call_deferred()


func _talisman_count() -> int:
	var n := 0
	for id in TalismanData.IDS:
		if Talismans.owned(id):
			n += 1
	return n


func _build_alchemy(stack: Control) -> Control:
	var p := _framed(stack, Vector2(460, 194))
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	p.add_child(v)
	_alc_head = Label.new()
	UITheme.title(_alc_head, 10, Palette.GOLD_BRIGHT)
	_alc_head.add_theme_font_override(&"font", UITheme.body_font())
	v.add_child(_alc_head)
	_alc_list = _scroll_list(v)
	_alc_buffs = Label.new()
	_alc_buffs.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	v.add_child(_alc_buffs)
	return p


## Potion recipes: press to brew when you have the materials. Drink potions from the Items tab.
func _refresh_alchemy() -> void:
	for c in _alc_list.get_children():
		_alc_list.remove_child(c)
		c.queue_free()
	_alc_btns.clear()
	_alc_head.text = "ALCHEMY    brew potions for timed buffs    %d embers" % GameState.embers
	for id in Alchemy.ORDER:
		var item := Items.get_item(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var slot := IconSlot.new()
		slot.custom_minimum_size = Vector2(22, 22)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.icon_id = id
		row.add_child(slot)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(396, 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var can := Alchemy.can_craft(id)
		b.text = "%s  (have %d)    %s" % [item.display_name, GameState.item_count(id), Alchemy.ingredients_text(id)]
		b.tooltip_text = item.description
		b.modulate.a = 1.0 if can else 0.55
		UITheme.compact(b)
		b.pressed.connect(func():
			var r := Alchemy.craft(id)
			_msg.text = r.msg
			_refresh_alchemy())
		row.add_child(b)
		_alc_list.add_child(row)
		_alc_btns.append(b)
	var lines := PackedStringArray()
	for id in Buffs.active:
		lines.append("%s %s" % [Buffs.DEFS[id].title, Buffs.clock(Buffs.remaining(id))])
	_alc_buffs.text = "Active: " + (", ".join(lines) if not lines.is_empty() else "none") + "    (drink potions from the ITEMS tab)"
	if not _alc_btns.is_empty():
		_alc_btns[0].grab_focus.call_deferred()


func _build_relics(stack: Control) -> Control:
	var p := _framed(stack, Vector2(460, 194))
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	p.add_child(v)
	_relic_head = Label.new()
	UITheme.title(_relic_head, 10, Palette.GOLD_BRIGHT)
	_relic_head.add_theme_font_override(&"font", UITheme.body_font())
	v.add_child(_relic_head)
	_relic_list = _scroll_list(v)
	return p


## Rebuilds the relic rows: every relic you carry, [x] when worn. Press to wear / remove.
func _refresh_relics() -> void:
	for c in _relic_list.get_children():
		_relic_list.remove_child(c)
		c.queue_free()
	_relic_btns.clear()
	_relic_head.text = "RELICS    worn %d / %d" % [Relics.equipped().size(), Relics.SLOTS]
	var any := false
	for id in Relics.IDS:
		if not Relics.owned(id):
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var slot := IconSlot.new()
		slot.custom_minimum_size = Vector2(22, 22)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.icon_id = id
		row.add_child(slot)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(400, 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s  %s    %s" % ["[x]" if Relics.is_worn(id) else "[ ]", Relics.DEFS[id].title, Relics.DEFS[id].desc]
		UITheme.compact(b)
		b.pressed.connect(func():
			var r := Relics.toggle(id)
			_msg.text = r.msg
			_refresh_relics())
		row.add_child(b)
		_relic_list.add_child(row)
		_relic_btns.append(b)
	if not any:
		var l := Label.new()
		l.text = "You carry no relics yet. Errands, bosses and hidden chests give them."
		l.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
		_relic_list.add_child(l)
	if not _relic_btns.is_empty():
		_relic_btns[0].grab_focus.call_deferred()


var _art_head: Label
var _art_list: VBoxContainer
var _art_btns: Array[Button] = []


func _build_arts(stack: Control) -> Control:
	var p := _framed(stack, Vector2(460, 194))
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	p.add_child(v)
	_art_head = Label.new()
	UITheme.title(_art_head, 10, Palette.GOLD_BRIGHT)
	_art_head.add_theme_font_override(&"font", UITheme.body_font())
	v.add_child(_art_head)
	_art_list = VBoxContainer.new()
	_art_list.add_theme_constant_override(&"separation", 2)
	v.add_child(_art_list)
	return p


## Every art: learned ones can be equipped (one at a time); the rest show who teaches them.
func _refresh_arts() -> void:
	for c in _art_list.get_children():
		_art_list.remove_child(c)
		c.queue_free()
	_art_btns.clear()
	var eq := Arts.equipped()
	_art_head.text = "ARTS    learned %d / %d    equipped: %s    (%s casts it)" % [Arts.learned_count(), Arts.ORDER.size(),
		Arts.title(eq) if eq != &"" else "none", "Art button"]
	var first: Button = null
	for id in Arts.ORDER:
		var d := Arts.def(id)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(440, 26)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UITheme.compact(b)
		if Arts.unlocked(id):
			b.text = "%s  %s  (%d focus)\n     %s" % ["[x]" if id == eq else "[ ]", d.title, int(d.cost), d.desc]
			b.pressed.connect(func():
				Arts.equip(id)
				_msg.text = "%s equipped." % d.title
				_refresh_arts())
			if first == null or id == eq:
				first = b
		else:
			b.text = "[ ]  ? ? ?\n     Taught by a boss you have not yet defeated."
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.5)
		_art_list.add_child(b)
		_art_btns.append(b)
	if first:
		first.grab_focus.call_deferred()
	else:
		_close_btn.grab_focus()


func _build_scroll_text(stack: Control, field: String) -> Control:
	var p := _framed(stack, Vector2(460, 194))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(440, 0)
	l.add_theme_constant_override(&"line_spacing", -2)
	sc.add_child(l)
	set(field, l)
	return p


## The journal text: open errands first, then finished ones.
func journal_text() -> String:
	var open_lines := PackedStringArray()
	var done_lines := PackedStringArray()
	for id in Quests.ORDER:
		var d := Quests.def(id)
		match Quests.state(id):
			"active":
				var tag := "READY - speak to them" if Quests.is_ready(id) else Quests.progress_text(id)
				open_lines.append("%s  [%s]\n   %s\n   Reward: %s" % [d.title, tag, d.summary, Quests.reward_text(id)])
			"done":
				done_lines.append("%s" % d.title)
	var t := "ERRANDS\n"
	t += "\n".join(open_lines) if not open_lines.is_empty() else "None open. Talk to the people of the road and the manor."
	if not done_lines.is_empty():
		t += "\n\nDONE:  " + ",  ".join(done_lines)
	return t


func _refresh_journal() -> void:
	_journal_label.text = journal_text()


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
		if _picking != "" and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
			close_picker()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"inventory") or event.is_action_pressed(&"pause"):
			close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"parry") or event.is_action_pressed(&"heal"):
			var step := -1 if event.is_action_pressed(&"parry") else 1
			show_tab((int(tab) + step + _pages.size()) % _pages.size())
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
	_picking = ""
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
	elif tab == Tab.WEAPONS:
		_refresh_weapons()
	elif tab == Tab.JOURNAL:
		_refresh_journal()
		_close_btn.grab_focus()
	elif tab == Tab.BESTIARY:
		_bestiary_label.text = Bestiary.text()
		_close_btn.grab_focus()
	elif tab == Tab.DEEDS:
		_deeds_label.text = Deeds.text()
		_close_btn.grab_focus()
	elif tab == Tab.RELICS:
		_refresh_relics()
	elif tab == Tab.ARTS:
		_refresh_arts()
	elif tab == Tab.TALISMANS:
		_refresh_talismans()
	elif tab == Tab.ALCHEMY:
		_refresh_alchemy()
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


## Strength and the weapon's upgrade level together.
func _strength_bonus() -> float:
	return (1.0 + int(GameState.stats.get("strength", 0)) * GameState.STRENGTH_DAMAGE) * Loadout.weapon_mult()


func _weapon_id() -> StringName:
	var w := Loadout.weapon()
	return w.id if w else &""


func _armor_icon() -> StringName:
	return &"" if GameState.armor_id == Armors.NONE or GameState.armor_id == &"" else StringName("armor_" + String(GameState.armor_id))


func _refresh_equipment() -> void:
	var pr := _preset()
	_preview.set("preset", Loadout.compose_look(pr))
	_char_name.text = pr.display_name
	_char_level.text = "Level %d      %d embers" % [GameState.level(), GameState.embers]
	(_slots.weapon as IconSlot).icon_id = _weapon_id()
	(_slots.armour as IconSlot).icon_id = _armor_icon()
	var qn := GameState.item_count(GameState.quick_item)
	(_slots.quick as IconSlot).icon_id = GameState.quick_item if qn > 0 else &""
	(_slots.quick as IconSlot).count = qn
	(_slots.status as IconSlot).icon_id = &"status"
	_select_slot(_slot_sel)


func _select_slot(key: String) -> void:
	_slot_sel = key
	for c in _d_grid.get_children():
		_d_grid.remove_child(c)
		c.queue_free()
	var pr := _preset()
	var p := _player()
	_d_icon_id = {"weapon": _weapon_id(), "armour": _armor_icon(),
		"quick": GameState.quick_item if GameState.item_count(GameState.quick_item) > 0 else &"", "status": &"status"}[key]
	_d_icon.queue_redraw()
	match key:
		"weapon":
			var cur := Loadout.weapon()
			var s := WeaponStats.summary(cur, _strength_bonus())
			var wl := GameState.weapon_level(GameState.weapon_id)
			_d_title.text = s.name + (" +%d" % wl if wl > 0 else "")
			_d_sub.text = "Weapon  -  %s, %s reach  -  Select to change" % [s.speed, (s.reach as String).to_lower()]
			var light: Array = s.light
			_row("Light combo", " / ".join(light.map(func(x): return str(x))) + "  (%d total)" % s.light_total)
			_row("Heavy", "%d" % s.heavy)
			_row("Aerial", "%d" % s.aerial)
			_row("Riposte", "%d" % s.riposte)
			_row("Stamina per swing", "%d  (heavy %d)" % [s.stamina, s.heavy_stamina])
			_row("Poise damage", "%d" % s.poise)
			_row("Bonus (Strength, upgrade)", "+%d%%" % roundi((_strength_bonus() - 1.0) * 100.0))
			if cur and cur.skill:
				_row("Skill", "%s  (%d focus)" % [cur.skill.display_name, roundi(cur.skill_cost)])
			if cur:
				var win := maxi(2, (pr.parry_window_frames if pr else 8) + cur.parry_window_bonus)
				_row("Parry window", "%d frames" % win)
				if cur.block_reduction > 0.0:
					_row("Guard (hold Parry)", "blocks %d%% damage" % roundi(cur.block_reduction * 100.0))
				if cur.status != &"":
					_row("Inflicts", "%s  (+%d per hit)" % [StatusFx.name_of(cur.status), roundi(cur.status_amount)])
			_d_desc.text = cur.description if cur else ""
		"armour":
			var arm := Armors.get_armor(GameState.armor_id)
			var alv := GameState.armor_level(GameState.armor_id)
			_d_title.text = (arm.display_name + (" +%d" % alv if alv > 0 else "")) if arm else "No armour"
			var look_kind: int = arm.look if arm else PresetData.ArmorLook.BARE
			_d_sub.text = "Armour  -  " + ("none" if look_kind == PresetData.ArmorLook.BARE else ["", "light", "medium", "heavy"][look_kind]) + "  -  Select to change"
			var taken := roundi(Armors.damage_mult(GameState.armor_id, alv) * 100.0)
			_row("Damage taken", "%d%%  %s" % [taken, "(less)" if taken < 100 else ("(more)" if taken > 100 else "")])
			_row("Run speed", "%d%%" % roundi(Armors.speed_mult(GameState.armor_id) * 100.0))
			_row("Dodge cost", "%d stamina" % roundi(pr.dodge_stamina + Armors.dodge_add(GameState.armor_id)))
			_row("Base health", "%d" % roundi(pr.max_health))
			_row("Base stamina", "%d" % roundi(pr.max_stamina))
			var fl: int = p.max_flasks if p else pr.flasks
			var fh: float = p.flask_heal if p else pr.flask_heal
			_row("Ember Vials", "%d  (heal %d each)" % [fl, roundi(fh)])
			var rt := StatusFx.resist_text(Armors.resist_of(GameState.armor_id, alv))
			_row("Resists", rt if rt != "" else "nothing")
			_d_desc.text = arm.description if arm else "You wear nothing. Select to put something on."
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


## Opens the weapon / armour chooser in the details pane (Select on the slot).
func open_picker(key: String) -> void:
	if key != "weapon" and key != "armour":
		return
	_picking = key
	for c in _picker.get_children():
		_picker.remove_child(c)
		c.queue_free()
	picker_buttons.clear()
	_d_grid.visible = false
	_d_desc.visible = false
	_picker.visible = true
	_d_icon_id = _weapon_id() if key == "weapon" else _armor_icon()
	_d_icon.queue_redraw()
	_d_title.text = "Choose a weapon" if key == "weapon" else "Choose armour"
	_d_sub.text = "Confirm to equip   -   Cancel to go back"
	var bonus := 1.0 + int(GameState.stats.get("strength", 0)) * GameState.STRENGTH_DAMAGE
	if key == "weapon":
		for id in Weapons.IDS:
			if not GameState.owns_weapon(id):
				continue
			var w := Weapons.get_weapon(id)
			var lv := GameState.weapon_level(id)
			var total: int = WeaponStats.summary(w, bonus * Weapons.level_mult(lv)).light_total
			var tag := "   (equipped)" if id == GameState.weapon_id else ""
			_picker_row(id, "%s +%d    combo %d%s" % [w.display_name, lv, total, tag], id == GameState.weapon_id)
	else:
		var bare := GameState.armor_id == Armors.NONE
		_picker_row(Armors.NONE, "Take off all armour" + ("   (nothing worn)" if bare else "") + "    taken %d%%" % roundi(Armors.NAKED_DAMAGE * 100.0), bare)
		for id in Armors.IDS:
			if not GameState.owns_armor(id):
				continue
			var ar := Armors.get_armor(id)
			var lvl := GameState.armor_level(id)
			var tag2 := "   (worn)" if id == GameState.armor_id else ""
			_picker_row(id, "%s +%d    taken %d%%%s" % [ar.display_name, lvl, roundi(Armors.damage_mult(id, lvl) * 100.0), tag2], id == GameState.armor_id)
	var focus: Button = picker_buttons[0].button
	for r in picker_buttons:
		if r.current:
			focus = r.button
	focus.grab_focus()


func _picker_row(id: StringName, text: String, current: bool) -> void:
	var b := FancyButton.new()
	b.text = text
	b.custom_minimum_size = Vector2(190, 14)
	UITheme.compact(b)
	b.pressed.connect(choose.bind(id))
	_picker.add_child(b)
	picker_buttons.append({"id": id, "button": b, "current": current})


## Equips (or, for armour, takes off with Armors.NONE) while the chooser is open.
func choose(id: StringName) -> void:
	if _picking == "weapon":
		Loadout.equip_weapon(id)
	elif _picking == "armour":
		Loadout.equip_armor(id)
	Audio.sfx(&"ui_move", -2.0)
	close_picker()


func close_picker() -> void:
	if _picking == "":
		return
	var slot := _picking
	_picking = ""
	_picker.visible = false
	_d_grid.visible = true
	_d_desc.visible = true
	_slot_sel = slot
	_refresh_equipment()
	(_slots[slot] as Button).grab_focus()


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

const ITEM_SLOTS := 20


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var first: IconSlot
	var found := false
	var used := 0
	for id in Items.IDS:
		var n := GameState.item_count(id)
		if n <= 0:
			continue
		var b := IconSlot.new()
		b.icon_id = id
		b.count = n
		b.marked = id == GameState.quick_item
		b.custom_minimum_size = Vector2(29, 29)
		b.focus_entered.connect(_select.bind(id))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_select.bind(id))
		_list.add_child(b)
		used += 1
		if first == null:
			first = b
		if id == _selected:
			first = b
			found = true
	# Empty slots fill out the grid.
	for i in maxi(0, ITEM_SLOTS - used):
		var e := IconSlot.new()
		e.custom_minimum_size = Vector2(29, 29)
		e.focus_mode = Control.FOCUS_NONE
		e.disabled = true
		e.modulate.a = 0.6
		_list.add_child(e)
	if used == 0:
		_selected = &""
		_show_detail()
		_name.text = "Your pack is empty."
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
	_i_icon_id = _selected if item else &""
	_i_icon.queue_redraw()
	_use_btn.visible = item != null and item.is_usable()
	_use_btn.text = "Use" if item == null or item.effect != ItemData.Effect.TRAVEL else ("Return" if Manor.in_manor() else "Travel to Hollowmere")
	_quick_btn.visible = _use_btn.visible and item.effect != ItemData.Effect.TRAVEL
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
	var travels := Items.get_item(_selected) != null and Items.get_item(_selected).effect == ItemData.Effect.TRAVEL
	if travels and not Manor.can_travel(p).ok:
		_msg.text = Manor.can_travel(p).msg
	elif Items.use(_selected, p):
		_msg.text = ""
		if travels:
			close()
	else:
		_msg.text = "That would have no effect right now."


func _on_quick() -> void:
	GameState.quick_item = _selected
	Events.inventory_changed.emit()
