class_name ForgeMenu
extends CanvasLayer
## The two smithing stations, one menu.
##   forge  - the Blacksmith: tabs WEAPONS / ARMOUR. Upgrade what you own (+1..+5) or forge
##            something new. Cost: embers + Forge Scrap (and a relic shown to the smith).
##   vials  - the Vial-Keeper: upgrade the Ember Vials. Cost: embers + Hollow Resin.
## Opened with Events.station_requested(kind); pauses the game. Rules live in Forge.

var is_open := false
var kind: StringName = &"forge"
var tab := "weapon"   ## "weapon" or "armor" (forge only)
var rows: Array = []  ## [{"id": StringName, "kind": String, "button": Button, "slot": IconSlot}]
var _panel: ColorRect
var _title: Label
var _funds: Label
var _list: VBoxContainer
var _desc: Label
var _msg: Label
var _tabs: HBoxContainer
var _tab_btns: Array[Button] = []
var _leave: Button


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(Palette.INK, 0.92)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	_panel.visible = false
	add_child(_panel)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	c.add_child(v)
	v.draw.connect(func(): UITheme.draw_panel(v, Rect2(Vector2(-22, -12), v.size + Vector2(44, 24))))
	v.resized.connect(v.queue_redraw)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(_title, 14)
	v.add_child(_title)
	v.add_child(UITheme.rule(280))
	_tabs = HBoxContainer.new()
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_theme_constant_override(&"separation", 14)
	v.add_child(_tabs)
	for i in 2:
		var b := FancyButton.new()
		b.text = ["WEAPONS", "ARMOUR"][i]
		b.custom_minimum_size = Vector2(90, 15)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(show_tab.bind(["weapon", "armor"][i]))
		UITheme.compact(b)
		_tabs.add_child(b)
		_tab_btns.append(b)
	_funds = Label.new()
	_funds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_funds.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	v.add_child(_funds)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 1)
	v.add_child(_list)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(280, 30)
	_desc.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	v.add_child(_desc)
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.custom_minimum_size.y = 10
	_msg.add_theme_color_override(&"font_color", Palette.GOLD)
	v.add_child(_msg)
	_leave = FancyButton.new()
	_leave.text = "Leave"
	_leave.custom_minimum_size = Vector2(280, 15)
	_leave.pressed.connect(close)
	UITheme.compact(_leave)
	v.add_child(_leave)
	Events.station_requested.connect(open)
	Events.embers_changed.connect(func(_n): _refresh())
	Events.inventory_changed.connect(_refresh)
	Events.loadout_changed.connect(_refresh)


func open(station: StringName) -> void:
	if is_open or GameState.ui_modal:
		return
	kind = station
	is_open = true
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	_title.text = "THE BLACKSMITH'S FORGE" if kind == &"forge" else "THE VIAL-KEEPER"
	_tabs.visible = kind == &"forge"
	_panel.visible = true
	_msg.text = ""
	tab = "weapon"
	_build_rows()


func show_tab(t: String) -> void:
	if kind != &"forge" or t == tab and not rows.is_empty():
		return
	tab = t
	_msg.text = ""
	_build_rows()
	Audio.sfx(&"ui_move", -4.0)


func _build_rows() -> void:
	for r in rows:
		(r.row as Node).queue_free()
	rows.clear()
	var ids: Array = [&"vials"] if kind == &"vials" else Forge.entries(tab)
	for id in ids:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 3)
		var slot := IconSlot.new()
		slot.custom_minimum_size = Vector2(16, 16)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.icon_id = &"vial" if id == &"vials" else (id if tab == "weapon" else StringName("armor_" + String(id)))
		row.add_child(slot)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(261, 16)
		UITheme.compact(b)
		b.pressed.connect(act.bind(id))
		b.focus_entered.connect(_describe.bind(id))
		row.add_child(b)
		_list.add_child(row)
		rows.append({"id": id, "kind": "vials" if id == &"vials" else tab, "button": b, "slot": slot, "row": row})
	_tab_btns[0].add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if tab == "weapon" else Palette.STONE_LIGHT)
	_tab_btns[1].add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if tab == "armor" else Palette.STONE_LIGHT)
	_refresh()
	if not rows.is_empty():
		(rows[0].button as Button).grab_focus()
		_describe(rows[0].id)
	else:
		_leave.grab_focus()


func _name_of(id: StringName) -> String:
	if id == &"vials":
		return "Ember Vials"
	if tab == "weapon":
		return Weapons.get_weapon(id).display_name
	return Armors.get_armor(id).display_name


func _cost_text(c: Dictionary, material: StringName) -> String:
	return "%d embers, %d %s" % [c.embers, c.mat, "scrap" if material == Forge.SCRAP else "resin"]


## One row's label, exposed for tests.
func row_text(id: StringName) -> String:
	if id == &"vials":
		var lv := GameState.flask_level
		var c := Forge.vial_cost()
		return "Ember Vials +%d      %s" % [lv, "at their finest" if c.is_empty() else "Upgrade: " + _cost_text(c, Forge.RESIN)]
	if Forge.owns(tab, id):
		var lv2 := Forge.level_of(tab, id)
		var c2 := Forge.upgrade_cost(tab, id)
		return "%s +%d      %s" % [_name_of(id), lv2, "at its finest" if c2.is_empty() else "Upgrade: " + _cost_text(c2, Forge.SCRAP)]
	var rc := Forge.recipe(id)
	var t := "%s      Forge: %s" % [_name_of(id), _cost_text(rc, Forge.SCRAP)]
	if rc.has("relic") and GameState.item_count(rc.relic) <= 0:
		t += " + " + Items.get_item(rc.relic).display_name
	return t


func _affordable(id: StringName) -> bool:
	var c: Dictionary
	var material := Forge.SCRAP
	if id == &"vials":
		c = Forge.vial_cost()
		material = Forge.RESIN
	elif Forge.owns(tab, id):
		c = Forge.upgrade_cost(tab, id)
	else:
		c = Forge.recipe(id)
		if c.has("relic") and GameState.item_count(c.relic) <= 0:
			return false
	return not c.is_empty() and GameState.embers >= int(c.embers) and GameState.item_count(material) >= int(c.mat)


func _refresh() -> void:
	if not is_open:
		return
	var m := Forge.RESIN if kind == &"vials" else Forge.SCRAP
	_funds.text = "Embers: %d      %s: %d" % [GameState.embers, Items.get_item(m).display_name, GameState.item_count(m)]
	for r in rows:
		(r.button as Button).text = row_text(r.id)
		(r.button as Button).modulate = Color.WHITE if _affordable(r.id) else Color(1, 1, 1, 0.55)


## What the focused row would give you.
func _describe(id: StringName) -> void:
	_desc.text = describe(id)


func describe(id: StringName) -> String:
	if id == &"vials":
		var lv := GameState.flask_level
		var pr := Presets.get_preset(GameState.preset_id)
		var heal0 := pr.flask_heal + Forge.vial_heal_bonus(lv)
		var n0 := pr.flasks + Forge.vial_extra(lv)
		if lv >= Forge.MAX_LEVEL:
			return "Each vial heals %d. You carry %d." % [roundi(heal0), n0]
		return "Each vial heals %d -> %d. You carry %d -> %d. Extra vials at +2 and +5." % [
			roundi(heal0), roundi(pr.flask_heal + Forge.vial_heal_bonus(lv + 1)), n0, pr.flasks + Forge.vial_extra(lv + 1)]
	if tab == "weapon":
		var w := Weapons.get_weapon(id)
		var lv2 := Forge.level_of("weapon", id)
		var str_bonus := 1.0 + int(GameState.stats.get("strength", 0)) * GameState.STRENGTH_DAMAGE
		var now := WeaponStats.summary(w, str_bonus * Weapons.level_mult(lv2))
		var t := w.description + "\n"
		if Forge.owns("weapon", id) and lv2 < Forge.MAX_LEVEL:
			var nxt := WeaponStats.summary(w, str_bonus * Weapons.level_mult(lv2 + 1))
			t += "Light combo %d -> %d   Heavy %d -> %d" % [now.light_total, nxt.light_total, now.heavy, nxt.heavy]
		else:
			t += "Light combo %d   Heavy %d" % [now.light_total, now.heavy]
		if w.skill:
			t += "\nSkill: %s (%d focus)" % [w.skill.display_name, roundi(w.skill_cost)]
		if w.status != &"":
			t += "   Inflicts %s" % StatusFx.name_of(w.status)
		return t
	var a := Armors.get_armor(id)
	var lv3 := Forge.level_of("armor", id)
	var d_now := roundi(Armors.damage_mult(id, lv3) * 100.0)
	var t2 := a.description + "\n"
	if Forge.owns("armor", id) and lv3 < Forge.MAX_LEVEL:
		t2 += "Damage taken %d%% -> %d%%   Speed %d%%" % [d_now, roundi(Armors.damage_mult(id, lv3 + 1) * 100.0), roundi(a.run_speed_mult * 100.0)]
	else:
		t2 += "Damage taken %d%%   Speed %d%%" % [d_now, roundi(a.run_speed_mult * 100.0)]
	var rs := StatusFx.resist_text(a.resist)
	if rs != "":
		t2 += "\nResists: " + rs
	return t2


## Upgrade / forge / vial upgrade for a row. Returns Forge's result (also shown in the message).
func act(id: StringName) -> Dictionary:
	var res: Dictionary
	if id == &"vials":
		res = Forge.upgrade_vials()
	elif Forge.owns(tab, id):
		res = Forge.upgrade(tab, id)
	else:
		res = Forge.make(id)
	_msg.text = res.msg
	Audio.sfx(&"coin" if res.ok else &"fizzle", -4.0)
	_refresh()
	_describe(id)
	return res


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = false
	GameState.ui_modal = false
	Events.station_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
	elif kind == &"forge" and (event.is_action_pressed(&"parry") or event.is_action_pressed(&"heal")):
		show_tab("armor" if tab == "weapon" else "weapon")
		get_viewport().set_input_as_handled()
