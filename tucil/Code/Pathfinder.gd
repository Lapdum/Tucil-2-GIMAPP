class_name Pathfinder
extends Node2D

const SQRT2: float = 1.41421356
const INVALID: Vector2i = Vector2i(2147483647, 2147483647)

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

@export var tilemap: Node
@export var tilemap_layer: int = 0
@export var solid_custom_data: StringName = &"solid"
@export var use_physics_as_solid: bool = true
@export var empty_cell_blocked: bool = false
@export var manual_bounds: Rect2i = Rect2i()

@export_group("Algoritma")
@export var allow_diagonal: bool = true
@export var smooth_path: bool = true
@export var max_search_nodes: int = 4000
@export_range(0, 10) var agent_radius_cells: int = 3

@export_group("Debug")
@export var debug_draw: bool = false

var last_path: PackedVector2Array = PackedVector2Array()

var _map
var _is_layer: bool = false
var _bounds: Rect2i = Rect2i()
var _blocked_cache: Dictionary = {}
var _solid_cache: Dictionary = {}


func _enter_tree() -> void:
	add_to_group(&"pathfinder")


func _ready() -> void:
	z_index = 100
	refresh()


func _process(_delta: float) -> void:
	if debug_draw:
		queue_redraw()


func refresh() -> void:
	_blocked_cache.clear()
	_solid_cache.clear()
	_map = tilemap
	if _map == null:
		push_warning("Pathfinder: properti 'tilemap' belum diisi.")
		_bounds = Rect2i()
		return
	_is_layer = _map.is_class("TileMapLayer")
	if manual_bounds.has_area():
		_bounds = manual_bounds
	else:
		_bounds = _map.get_used_rect()


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return _map.local_to_map(_map.to_local(world_pos))


func cell_to_world(cell: Vector2i) -> Vector2:
	return _map.to_global(_map.map_to_local(cell))


func is_blocked(cell: Vector2i) -> bool:
	if not _bounds.has_point(cell):
		return true
	if _blocked_cache.has(cell):
		return _blocked_cache[cell]
	var blocked := _is_solid(cell) or _near_solid(cell)
	_blocked_cache[cell] = blocked
	return blocked


func _is_solid(cell: Vector2i) -> bool:
	if _solid_cache.has(cell):
		return _solid_cache[cell]
	var solid := _compute_solid(cell)
	_solid_cache[cell] = solid
	return solid


func _near_solid(cell: Vector2i) -> bool:
	var r := agent_radius_cells
	if r <= 0:
		return false
	var r2 := r * r
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx * dx + dy * dy > r2:
				continue
			var c := cell + Vector2i(dx, dy)
			if _bounds.has_point(c) and _is_solid(c):
				return true
	return false


func _compute_solid(cell: Vector2i) -> bool:
	var data: TileData
	if _is_layer:
		data = _map.get_cell_tile_data(cell)
	else:
		data = _map.get_cell_tile_data(tilemap_layer, cell)
	if data == null:
		return empty_cell_blocked

	var tile_set: TileSet = _map.tile_set
	if tile_set.get_custom_data_layer_by_name(solid_custom_data) != -1:
		if bool(data.get_custom_data(solid_custom_data)):
			return true
	if use_physics_as_solid and tile_set.get_physics_layers_count() > 0:
		if data.get_collision_polygons_count(0) > 0:
			return true
	return false


func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	last_path = PackedVector2Array()
	if _map == null:
		return last_path

	var goal_raw := world_to_cell(to_world)
	var start := _nearest_walkable(world_to_cell(from_world))
	var goal := _nearest_walkable(goal_raw)
	if start == INVALID or goal == INVALID:
		return last_path

	var cells := _astar(start, goal)
	if cells.is_empty():
		return last_path

	if smooth_path:
		cells = _smooth(cells)

	for i in range(1, cells.size()):
		last_path.append(cell_to_world(cells[i]))
	if goal == goal_raw:
		if last_path.is_empty():
			last_path.append(to_world)
		else:
			last_path[last_path.size() - 1] = to_world
	return last_path


func _astar(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start_id := _to_id(start)
	var goal_id := _to_id(goal)

	var g_score: Dictionary = {start_id: 0.0}
	var parent: Dictionary = {}
	var closed: Dictionary = {}
	var open := MinHeap.new()
	open.push(_heuristic(start, goal), start_id)

	var expanded: int = 0
	var found: bool = false
	var dir_count: int = 8 if allow_diagonal else 4

	while not open.is_empty():
		var cur_id: int = open.pop()
		if closed.has(cur_id):
			continue
		closed[cur_id] = true
		if cur_id == goal_id:
			found = true
			break
		expanded += 1
		if expanded > max_search_nodes:
			break

		var cur := _from_id(cur_id)
		var cur_g: float = g_score[cur_id]
		for i in dir_count:
			var d: Vector2i = DIRS[i]
			var next := cur + d
			if is_blocked(next):
				continue
			var diagonal := d.x != 0 and d.y != 0
			if diagonal and (is_blocked(cur + Vector2i(d.x, 0)) or is_blocked(cur + Vector2i(0, d.y))):
				continue
			var next_id := _to_id(next)
			if closed.has(next_id):
				continue
			var new_g := cur_g + (SQRT2 if diagonal else 1.0)
			if not g_score.has(next_id) or new_g < float(g_score[next_id]):
				g_score[next_id] = new_g
				parent[next_id] = cur_id
				open.push(new_g + _heuristic(next, goal), next_id)

	if not found:
		return result

	var id := goal_id
	while id != start_id:
		result.append(_from_id(id))
		id = parent[id]
	result.append(start)
	result.reverse()
	return result


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	if not allow_diagonal:
		return float(dx + dy)
	return float(dx + dy) + (SQRT2 - 2.0) * float(mini(dx, dy))


func _to_id(cell: Vector2i) -> int:
	return (cell.y - _bounds.position.y) * _bounds.size.x + (cell.x - _bounds.position.x)


@warning_ignore("integer_division")
func _from_id(id: int) -> Vector2i:
	var w := _bounds.size.x
	return Vector2i(id % w + _bounds.position.x, id / w + _bounds.position.y)


func _nearest_walkable(cell: Vector2i, max_radius: int = -1) -> Vector2i:
	if not is_blocked(cell):
		return cell
	if max_radius < 0:
		max_radius = agent_radius_cells + 3
	for r in range(1, max_radius + 1):
		var best := INVALID
		var best_d := INF
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := cell + Vector2i(dx, dy)
				if not is_blocked(c):
					var d := float(dx * dx + dy * dy)
					if d < best_d:
						best_d = d
						best = c
		if best != INVALID:
			return best
	return INVALID


func _smooth(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.size() <= 2:
		return cells
	var out: Array[Vector2i] = [cells[0]]
	var anchor := 0
	while anchor < cells.size() - 1:
		var furthest := anchor + 1
		for j in range(cells.size() - 1, anchor, -1):
			if _line_clear(cells[anchor], cells[j]):
				furthest = j
				break
		out.append(cells[furthest])
		anchor = furthest
	return out


func _line_clear(a: Vector2i, b: Vector2i) -> bool:
	var fa := Vector2(a)
	var fb := Vector2(b)
	var steps := int(ceil(fa.distance_to(fb) * 4.0))
	for s in range(steps + 1):
		var p := fa.lerp(fb, float(s) / float(maxi(steps, 1)))
		var xs := [roundi(p.x - 0.01), roundi(p.x + 0.01)]
		var ys := [roundi(p.y - 0.01), roundi(p.y + 0.01)]
		for x in xs:
			for y in ys:
				if is_blocked(Vector2i(x, y)):
					return false
	return true


class MinHeap:
	var _f := PackedFloat64Array()
	var _id := PackedInt32Array()

	func is_empty() -> bool:
		return _id.is_empty()

	func push(f: float, id: int) -> void:
		_f.append(f)
		_id.append(id)
		var i := _id.size() - 1
		while i > 0:
			var p := (i - 1) >> 1
			if _f[p] <= _f[i]:
				break
			_swap(i, p)
			i = p

	func pop() -> int:
		var top := _id[0]
		var last := _id.size() - 1
		_f[0] = _f[last]
		_id[0] = _id[last]
		_f.resize(last)
		_id.resize(last)
		var i := 0
		while true:
			var l := 2 * i + 1
			var r := l + 1
			var m := i
			if l < last and _f[l] < _f[m]:
				m = l
			if r < last and _f[r] < _f[m]:
				m = r
			if m == i:
				break
			_swap(i, m)
			i = m
		return top

	func _swap(a: int, b: int) -> void:
		var tf := _f[a]
		_f[a] = _f[b]
		_f[b] = tf
		var ti := _id[a]
		_id[a] = _id[b]
		_id[b] = ti


func _draw() -> void:
	if not debug_draw or _map == null:
		return
	var tile_size := Vector2(_map.tile_set.tile_size)
	for x in range(_bounds.position.x, _bounds.end.x):
		for y in range(_bounds.position.y, _bounds.end.y):
			var cell := Vector2i(x, y)
			var color := Color(0, 0, 0, 0)
			if _is_solid(cell):
				color = Color(1, 0, 0, 0.35)
			elif is_blocked(cell):
				color = Color(1, 0.6, 0, 0.18)
			if color.a > 0.0:
				var center := to_local(cell_to_world(cell))
				draw_rect(Rect2(center - tile_size * 0.5, tile_size), color, true)
	if last_path.size() >= 2:
		var pts := PackedVector2Array()
		for p in last_path:
			pts.append(to_local(p))
		draw_polyline(pts, Color(1, 1, 0, 0.9), 2.0)
	for p in last_path:
		draw_circle(to_local(p), 3.0, Color(0, 1, 1, 0.9))
