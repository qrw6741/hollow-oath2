class_name WorldMap
extends RefCounted
## World-map data. Every level is listed here with nothing else to configure: the map
## reads each level scene once (geometry, water, candles, exits, boss arenas) and places
## it at its Level.map_origin. Exploration is stored per level as 64 px cells in
## GameState.explored; only explored cells are drawn.

const LEVELS := [
	"res://world/levels/test_arena.tscn",
	"res://world/levels/forsaken_village.tscn",
	"res://world/levels/drowned_catacombs.tscn",
	"res://world/levels/vaelmoor_awake.tscn",
	"res://world/levels/vaelmoor_road.tscn",
	"res://world/levels/hollowmere_manor.tscn",
	"res://world/levels/hollowmere_cellar.tscn",
	"res://world/levels/hollowmere_gallery.tscn",
	"res://world/levels/pilgrims_graveyard.tscn",
	"res://world/levels/ashen_chapel.tscn",
	"res://world/levels/sunken_reliquary.tscn",
	"res://world/levels/hollow_keep.tscn",
]
const CELL := 64.0
const REVEAL_RADIUS := 3     # cells around the player revealed as you walk

static var _cache := {}


static func cell_key(cx: int, cy: int) -> int:
	return cy * 2048 + cx


static func key_cell(k: int) -> Vector2i:
	return Vector2i(k % 2048, k / 2048)


static func cells_around(p: Vector2, r: int) -> Array:
	var cx := int(floor(p.x / CELL))
	var cy := int(floor(p.y / CELL))
	var out := []
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x >= 0 and y >= 0 and (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r + 1:
				out.append(cell_key(x, y))
	return out


## Static description of one level, read from its scene (cached).
static func info(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var d := {"path": path, "blocks": [], "planks": [], "water": [], "candles": [], "exits": [], "bosses": []}
	var scene := load(path) as PackedScene
	if scene == null:
		return d
	var root := scene.instantiate()
	d["level_id"] = String(root.get("level_id"))
	d["name"] = String(root.get("display_name"))
	d["origin"] = root.get("map_origin")
	d["bounds"] = root.get("bounds")
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is Node2D) or n == root:
			continue
		var pos := _pos_in(n, root)
		if n is StoneBlock:
			var r := Rect2(pos, n.size)
			if n.one_way:
				d.planks.append(r)
			else:
				d.blocks.append(r)
		elif n is BreakableWall:
			d.blocks.append(Rect2(pos, n.size))
		elif n is WaterZone:
			d.water.append(Rect2(pos, n.size))
		elif n is OathCandle:
			d.candles.append({"pos": pos, "id": String(n.checkpoint_id), "name": n.display_name})
		elif n is LevelExit:
			d.exits.append({"pos": pos, "target": n.target_level, "door": n.mode == LevelExit.Mode.DOOR, "sealed": n.sealed})
		elif n is BossArena and n.boss_scene:
			d.bosses.append({"pos": pos + n.boss_offset, "id": String(n._boss_id())})
	root.free()
	_cache[path] = d
	return d


static func _pos_in(n: Node, root: Node) -> Vector2:
	var p := Vector2.ZERO
	var c := n
	while c and c != root:
		if c is Node2D:
			p += (c as Node2D).position
		c = c.get_parent()
	return p


static func all() -> Array:
	var out := []
	for p in LEVELS:
		out.append(info(p))
	return out


## Fraction (0..1) of a level's cells that have been explored, for the map legend.
static func explored_fraction(d: Dictionary) -> float:
	var b: Rect2 = d.bounds
	var total := int(ceil(b.size.x / CELL)) * int(ceil(b.size.y / CELL))
	var seen: Dictionary = GameState.explored.get(d.level_id, {})
	return clampf(float(seen.size()) / maxf(1.0, total), 0.0, 1.0)
