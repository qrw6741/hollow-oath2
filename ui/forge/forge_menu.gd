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
var _chip: EmberChip
var _mat_lbl: Label
var _big: IconSlot
var _d_name: Label
var _d_sub: Label
var _d_cost: Label
var _infuse_btn: Button
var _focus_id: StringName = &""
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
	var head := HBoxContainer.new()
	head.custom_minimum_size.x = 380
	v.add_child(head)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.title(_title, 14)
	head.add_child(_title)
	_mat_lbl = Label.new()
	_mat_lbl.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	_mat_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_mat_lbl)
	_chip = EmberChip.new()
	head.add_child(_chip)
	v.add_child(UITheme.rule(380))
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override(&"separation", 6)
	v.add_child(_tabs)
	for i in 2:
		var b := FancyButton.new()
		b.text = ["WEAPONS", "ARMOUR"][i]
		b.custom_minimum_size = Vector2(80, 15)
		b.add_theme_font_override(&"font", UITheme.title_font())
		b.add_theme_font_size_override(&"font_size", 10)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(show_tab.bind(["weapon", "armor"][i]))
		UITheme.compact(b)
		_tabs.add_child(b)
		_tab_btns.append(b)
	var hint := HintBar.new()
	hint.spec = "parry:prev tab,heal:next tab"
	_tabs.add_child(hint)
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 8)
	v.add_child(body)
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(176, 118)
	body.add_child(left)
	UITheme.frame(left)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 1)
	left.add_child(_list)
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(196, 118)
	body.add_child(right)
	UITheme.frame(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 2)
	right.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 7)
	rv.add_child(top)
	_big = IconSlot.new()
	_big.custom_minimum_size = Vector2(38, 38)
	_big.focus_mode = Control.FOCUS_NONE
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_big)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override(&"separation", 0)
	top.add_child(tv)
	_d_name = Label.new()
	UITheme.title(_d_name, 11, Palette.GOLD_BRIGHT)
	tv.add_child(_d_name)
	_d_sub = Label.new()
	_d_sub.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	tv.add_child(_d_sub)
	_d_cost = Label.new()
	_d_cost.add_theme_color_override(&"font_color", Palette.GOLD)
	tv.add_child(_d_cost)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(180, 60)
	_desc.add_theme_color_override(&"font_color", Palette.BONE)
	_desc.add_theme_constant_override(&"line_spacing", -2)
	rv.add_child(_desc)
	_infuse_btn = FancyButton.new()
	_infuse_btn.custom_minimum_size = Vector2(180, 14)
	_infuse_btn.pressed.connect(func(): infuse_focused())
	UITheme.compact(_infuse_btn)
	rv.add_child(_infuse_btn)
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.custom_minimum_size.y = 10
	_msg.add_theme_color_override(&"font_color", Palette.GOLD)
	v.add_child(_msg)
	_leave = FancyButton.new()
	_leave.text = "Leave"
	_leave.custom_minimum_size = Vector2(380, 15)
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
	_title.text = "THE BLACKSMITH'S FORGE"
	_chip.set_value(GameState.embers, true) if kind == &"forge" else "THE VIAL-KEEPER"
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
		b.custom_minimum_size = Vector2(98, 16)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UITheme.compact(b)
		b.pressed.connect(act.bind(id))
		b.focus_entered.connect(_describe.bind(id))
		b.mouse_entered.connect(_describe.bind(id))
		row.add_child(b)
		var pl := Label.new()
		pl.custom_minimum_size = Vector2(52, 16)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pl)
		_list.add_child(row)
		rows.append({"id": id, "kind": "vials" if id == &"vials" else tab, "button": b, "slot": slot, "row": row, "price": pl})
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


func _short_cost(id: StringName) -> String:
	var c: Dictionary
	if id == &"vials":
		c = Forge.vial_cost()
	elif Forge.owns(tab, id):
		c = Forge.upgrade_cost(tab, id)
	else:
		c = Forge.recipe(id)
	return "MAX" if c.is_empty() else "%d + %d" % [c.embers, c.mat]


func _refresh() -> void:
	if not is_open:
		return
	var m := Forge.RESIN if kind == &"vials" else Forge.SCRAP
	_chip.set_value(GameState.embers)
	_mat_lbl.text = "%s %d   " % [Items.get_item(m).display_name, GameState.item_count(m)]
	for r in rows:
		var ok := _affordable(r.id)
		var lv := GameState.flask_level if r.id == &"vials" else (Forge.level_of(tab, r.id) if Forge.owns(tab, r.id) else -1)
		var nm := "Ember Vials" if r.id == &"vials" else _name_of(r.id)
		(r.button as Button).text = nm + ("  +%d" % lv if lv >= 0 else "  new")
		(r.button as Button).tooltip_text = row_text(r.id)
		var pl := r.price as Label
		pl.text = _short_cost(r.id)
		pl.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if ok else Palette.CRIMSON_BRIGHT)
		(r.button as Button).modulate = Color.WHITE if ok else Color(1, 1, 1, 0.6)


## What the focused row would give you.
## Infuses (or cycles the infusion of) the highlighted weapon.
func infuse_focused() -> Dictionary:
	if kind != &"forge" or tab != "weapon" or not Forge.owns("weapon", _focus_id):
		return {"ok": false, "msg": ""}
	var nxt := Forge.next_infusion(_focus_id)
	var res := Forge.infuse(_focus_id, nxt)
	_msg.text = res.msg
	Audio.sfx(&"coin" if res.ok else &"fizzle", -4.0)
	_refresh()
	_describe(_focus_id)
	return res


func _describe(id: StringName) -> void:
	_focus_id = id
	var can := kind == &"forge" and tab == "weapon" and Forge.owns("weapon", id)
	_infuse_btn.visible = can
	if can:
		var nxt := Forge.next_infusion(id)
		var cur := Forge.infusion_of(id)
		_infuse_btn.text = "Infusion: %s   ->   %s (%d embers + %d resin)" % [
			StatusFx.name_of(cur) if cur != &"" else "none",
			"clean" if nxt == &"" else StatusFx.name_of(nxt), Forge.INFUSE_COST.embers, Forge.INFUSE_COST.mat] if nxt != &"" else "Infusion: %s   ->   clean (free)" % StatusFx.name_of(cur)
	_desc.text = describe(id)
	_big.icon_id = &"vial" if id == &"vials" else (id if tab == "weapon" else StringName("armor_" + String(id)))
	_d_name.text = "Ember Vials" if id == &"vials" else _name_of(id)
	var owned := id == &"vials" or Forge.owns(tab, id)
	var lv := GameState.flask_level if id == &"vials" else (Forge.level_of(tab, id) if owned else 0)
	_d_sub.text = ("Level +%d of +%d" % [lv, Forge.MAX_LEVEL]) if owned else "Not yet forged"
	var sc := _short_cost(id)
	_d_cost.text = "At its finest" if sc == "MAX" else ("Upgrade: " if owned else "Forge: ") + sc.replace(" + ", " embers + ") + (" resin" if id == &"vials" else " scrap")


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
		var fx := Forge.effective_status(w)
		if fx.kind != &"":
			t += "   Inflicts %s%s" % [StatusFx.name_of(fx.kind), " (infused)" if Forge.infusion_of(id) != &"" else ""]
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
