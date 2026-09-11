class_name LevelInstantiator
## 实例化层：把 LevelData 转成场景节点。
##   floor         -> 实例化 floor.tscn，按 fill_rect 铺地板
##   exit          -> 实例化 exit.tscn，摆坐标 + 朝向 + 可选 next_scene / tooltip_offset
##   external_wall -> TileMapLayer，按 dirs 连通性用 16x16 小格拼 32x32 墙节点
##   characters    -> 实例化对应角色场景，支持 Player / Dolos_Black
##
## 依赖场景（路径不同改下面常量即可）：
##   res://item/floor/floor.tscn
##   res://item/exit/exit.tscn
##   res://item/walls/external_wall.tscn
##   res://character/player/player.tscn
##   res://character/npc/Dolos_Black.tscn

const FLOOR_SCENE := preload("res://item/floor/floor.tscn")
const EXIT_SCENE := preload("res://item/exit/exit.tscn")
const EXTERNAL_WALL_SCENE := preload("res://item/walls/external_wall.tscn")
const PLAYER_SCENE := preload("res://character/player/player.tscn")
const DOLOS_BLACK_SCENE := preload("res://character/npc/Dolos_Black.tscn")

const WALL_SOURCE_ID := 0
## 外墙节点自动连接的最大距离（格子单位）。
## 同一行/列上距离在此以内的节点会被认为是连接的，中间自动铺直墙连接段。
## 需要调整时改这个常量即可。
const WALL_CONNECT_MAX_DISTANCE := 50

## 外墙 type -> 图集 Y 偏移（单位：16px 小格行数）。
## blue（缺省）= 0；green=3、red=6、orange=9、white=12（wall.png 每 3 行一个颜色块）。
## 特殊值 null 表示"挖空"：该格不铺墙，且连接段经过此处时断开（不参与连接判断）。
const WALL_TYPE_Y_OFFSETS := {
	"green": 3,
	"red": 6,
	"orange": 9,
	"white": 12,
}

# 方向常量（与 CoordinateSystem 一致，这里局部复用避免循环依赖）
const _DIR_N := Vector2i(0, -1)
const _DIR_S := Vector2i(0, 1)
const _DIR_W := Vector2i(-1, 0)
const _DIR_E := Vector2i(1, 0)

## 把整个关卡实例化到 parent 下。返回是否全部成功。
static func build_level(level: LevelData, parent: Node) -> bool:
	return build_level_with_refs(level, parent).get("ok", true)

## 把整个关卡实例化到 parent 下，返回所有关键节点的引用表。
## 这样关卡加载后不用靠 get_node 猜名字，直接拿引用：
##   var refs := LevelInstantiator.build_level_with_refs(level, self)
##   refs["floor"]          -> Floor | null
##   refs["external_wall"]  -> TileMapLayer | null
##   refs["exit"]           -> Exit | null
##   refs["items"]          -> Array[Node]（所有物品节点）
##   refs["characters"]     -> Array[Node]（所有角色节点）
##   refs["player"]         -> 第一个 Player 节点 | null（便捷）
##   refs["ok"]             -> 是否全部成功
## 另外：可实例化场景（floor / exit / 每个 item / 每个 character）的 JSON 数据里
## 写可选字段 name 时，会以该 name 作为额外引用键加入 refs（见 _register_named_ref）。
static func build_level_with_refs(level: LevelData, parent: Node) -> Dictionary:
	var refs := {
		"ok": true,
		"floor": null,
		"external_wall": null,
		"exit": null,
		"items": [],
		"characters": [],
		"player": null,
	}
	if level.has_floor():
		refs["floor"] = spawn_floor(level, parent, refs)
	if not level.external_walls.is_empty():
		refs["external_wall"] = spawn_external_walls(level, parent)
	if not level.items.is_empty():
		refs["items"] = spawn_items(level, parent, refs)
		# ButtonController 的 name 绑定与顺序无关：所有 items 实例化后统一解析
		_resolve_bc_bindings(level, parent, refs)
	if not level.characters.is_empty():
		refs["characters"] = spawn_characters(level, parent, refs)
		for node in refs["characters"]:
			if refs["player"] == null and node.name == "Player":
				refs["player"] = node
	# mirror 依赖 items/characters 的 name 引用（tomap），在所有节点实例化后统一处理
	var mirrors := spawn_mirrors(level, parent, refs)
	if not mirrors.is_empty():
		for m in mirrors:
			(refs["items"] as Array).append(m)
	if level.has_exit():
		refs["exit"] = spawn_exit(level, parent, refs)
	return refs

## 若数据里写了可选字段 name，把实例化出的节点注册进引用表：refs[name] = node。
## name 要求唯一；若重复，后实例化的覆盖先实例化的（与 Dictionary 行为一致）。
static func _register_named_ref(refs: Dictionary, node: Node, data: Dictionary) -> void:
	if refs.is_empty():
		return
	var n := str(data.get("name", ""))
	if not n.is_empty():
		refs[n] = node

# ============================================================
# floor
# ============================================================

## 地板：JSON {X,Y,W,H,seed?,preset_tile?,name?} -> 瓦片矩形，返回实例化出的 Floor 节点
static func spawn_floor(level: LevelData, parent: Node, refs: Dictionary = {}) -> Floor:
	var floor_node := FLOOR_SCENE.instantiate() as Floor
	floor_node.name = "Floor"  # 稳定节点名，方便 get_node("Floor")
	floor_node.auto_generate = false   # 关掉默认矩形，避免先铺一遍再覆盖
	floor_node.clear_before_fill = false  # 不先清空，保留预制瓦片
	floor_node.only_fill_empty = true     # 只铺空白格，不覆盖预制瓦片
	if level.floor_seed != -1:
		floor_node.seed_value = level.floor_seed  # 固定种子，关卡可复现
	parent.add_child(floor_node)
	_place_preset_tiles(floor_node, level.floor_preset_tiles)
	floor_node.generate_area(level.floor_rect)
	_register_named_ref(refs, floor_node, {"name": level.floor_name})
	return floor_node

## 铺设预制瓦片：先摆指定位置的瓦片（可带朝向/旋转），
## generate_area 因 only_fill_empty=true 不会覆盖这些格子。
static func _place_preset_tiles(floor_node: Floor, presets: Array) -> void:
	if presets.is_empty():
		return
	var source := floor_node.tile_set.get_source(floor_node.source_id) as TileSetAtlasSource
	if source == null:
		push_warning("LevelInstantiator: floor TileSet 找不到 source_id=%d" % floor_node.source_id)
		return
	for preset in presets:
		if typeof(preset) != TYPE_DICTIONARY:
			continue
		var coord := Vector2i(int(preset.get("X", 0)), int(preset.get("Y", 0)))
		var tile_data: Variant = preset.get("tile", [0, 0])
		if typeof(tile_data) != TYPE_ARRAY or tile_data.size() < 2:
			push_warning("LevelInstantiator: 预制瓦片 tile 格式应为 [x,y]，跳过")
			continue
		var atlas := Vector2i(int(tile_data[0]), int(tile_data[1]))
		var facing := str(preset.get("facing", "E"))
		var alt := _preset_alternative_tile(source, atlas, facing)
		floor_node.set_cell(coord, floor_node.source_id, atlas, alt)

## 为预制瓦片获取/创建 alternative tile（实现旋转）。
## 朝向复用 CoordinateSystem 语义：E=0°、S=90°、W=180°、N=-90°。
## 旋转通过 TileData 的 transpose/flip 组合表达（TileMapLayer 无直接旋转参数）。
static func _preset_alternative_tile(source: TileSetAtlasSource, atlas: Vector2i, facing: String) -> int:
	# 先看该瓦片是否已有同朝向的 alternative（共享 TileSet 时避免重复创建）
	var alt_count := source.get_alternative_tiles_count(atlas)
	for i in alt_count:
		var alt_id := source.get_alternative_tile_id(atlas, i)
		var td := source.get_tile_data(atlas, alt_id)
		if _facing_matches_tile_data(td, facing):
			return alt_id
	# 没有则创建一个
	var new_alt := source.create_alternative_tile(atlas)
	var new_td := source.get_tile_data(atlas, new_alt)
	_apply_facing_to_tile_data(new_td, facing)
	return new_alt

## TileData 是否已是指定朝向（N/S/W/E；E=无旋转）
static func _facing_matches_tile_data(td: TileData, facing: String) -> bool:
	match facing:
		"N": return td.transpose and td.flip_v and not td.flip_h
		"S": return td.transpose and td.flip_h and not td.flip_v
		"W": return td.flip_h and td.flip_v and not td.transpose
		_: return not td.transpose and not td.flip_h and not td.flip_v

## 把朝向应用到 TileData 的旋转（transpose/flip 组合）：
##   E=0° 不旋转；S=90°；W=180°；N=-90°（与 facing_to_rotation 一致）
static func _apply_facing_to_tile_data(td: TileData, facing: String) -> void:
	match facing:
		"S":
			td.transpose = true
			td.flip_h = true
		"W":
			td.flip_h = true
			td.flip_v = true
		"N":
			td.transpose = true
			td.flip_v = true
		_: # E 或未知：不旋转
			pass

# ============================================================
# exit
# ============================================================

## 出口：JSON {X,Y,facing,next_scene?,tooltip_offset?} -> 坐标 + 朝向 + 可选属性，返回 Exit 节点
static func spawn_exit(level: LevelData, parent: Node, refs: Dictionary = {}) -> Exit:
	var exit_node := EXIT_SCENE.instantiate() as Exit
	exit_node.name = "Exit"  # 稳定节点名，方便 get_node("Exit")
	parent.add_child(exit_node)
	exit_node.position = world_coord_to_vector2(level.exit, level)
	exit_node.rotation_degrees = CoordinateSystem.facing_to_rotation(str(level.exit.get("facing", "E")))
	# exit._ready() 里的 reset_rotation 在 add_child 时就执行了（此时旋转还是 0），
	# 所以设置完朝向后需要再调一次，让交互组件基于正确朝向重置
	if exit_node.interact_comp:
		exit_node.interact_comp.reset_rotation(false)

	# next_scene（可选）
	var next_path := str(level.exit.get("next_scene", ""))
	if not next_path.is_empty():
		var scene := load(next_path) as PackedScene
		if scene:
			exit_node.next_scene = scene
		else:
			push_warning("LevelInstantiator: 无法加载 next_scene '%s'" % next_path)

	# tooltip_offset（可选，格式 [x, y]，对应 exit 场景的 tooltip_offset 属性）
	var offset_data: Variant = level.exit.get("tooltip_offset", null)
	if offset_data != null and typeof(offset_data) == TYPE_ARRAY and offset_data.size() >= 2:
		exit_node.tooltip_offset = Vector2(
			float(offset_data[0]),
			float(offset_data[1])
		)

	_register_named_ref(refs, exit_node, level.exit)
	return exit_node

# ============================================================
# external_wall（TileMapLayer）
# ============================================================
## 墙节点拼接规则（素材左上角有用区域）：
##   3x3 部分（列0-2, 行0-2）：单方向连接
##   2x2 部分（列3-4, 行0-1）：双方向内角
##
## 一个墙节点 = 2x2 个 16x16 小格。
## 关卡坐标 cell=32px，TileMapLayer tile=16px，所以关卡坐标 (X,Y)
## 对应 TileMapLayer 的 cell (2X,2Y) ~ (2X+1,2Y+1)。
##
## 相邻检测：同一行/列上距离 <= WALL_CONNECT_MAX_DISTANCE 的节点认为连接，
## 中间自动铺直墙连接段。节点显式写了 dirs 则直接用，没写则自动推导。

## 外墙：节点数组 -> TileMapLayer 铺设（含自动连接段），返回 TileMapLayer 节点
static func spawn_external_walls(level: LevelData, parent: Node) -> TileMapLayer:
	if level.external_walls.is_empty():
		return null

	var tile_map := EXTERNAL_WALL_SCENE.instantiate() as TileMapLayer
	tile_map.name = "ExternalWall"  # 稳定节点名，方便 get_node("ExternalWall")
	parent.add_child(tile_map)
	tile_map.clear()  # 场景默认带瓦片，生成前先清空

	# 1. 推导所有节点的 dirs（显式或自动）
	var nodes_with_dirs: Array = _resolve_all_wall_dirs(level.external_walls)

	# 2. 在每对连接的节点之间生成直墙连接段
	var all_nodes: Array = _build_connecting_segments(nodes_with_dirs)

	# 3. 统一铺设（原始节点 + 自动生成的连接段）
	for node in all_nodes:
		if node.has("type") and node["type"] == null:
			continue  # type=null：挖空，不铺设（连接段生成时已因占位跳过该格）
		var coord := Vector2i(int(node.get("X", 0)), int(node.get("Y", 0)))
		var dirs: Dictionary = node.get("dirs", {})
		var type_name := str(node.get("type", "blue")).to_lower()
		_paint_wall_node(tile_map, coord, dirs, _wall_type_y_offset(type_name))
	return tile_map

## 外墙 type -> 图集 Y 偏移（未知值按 blue=0 处理，调用方已做警告）
static func _wall_type_y_offset(type_name: String) -> int:
	return int(WALL_TYPE_Y_OFFSETS.get(type_name, 0))

## 推导所有节点的 dirs：
##   - dirs 中写了的方向，用写的值
##   - dirs 中没写的方向（包括完全不写 dirs 的情况），自动根据相邻节点推导
## 最终每个节点都有完整的 N/S/W/E 四个方向。
static func _resolve_all_wall_dirs(nodes: Array) -> Array:
	var result := []
	for node in nodes:
		var resolved: Dictionary = node.duplicate(true)
		# type=null：挖空节点，不参与连接判断（不推导 dirs），
		# 但保留在列表里占位，连接段生成时经过该格会自动跳过
		if resolved.has("type") and resolved["type"] == null:
			result.append(resolved)
			continue
		# 未知 type 警告一次（按 blue 处理）
		var type_name := str(resolved.get("type", "blue")).to_lower()
		if type_name != "blue" and not WALL_TYPE_Y_OFFSETS.has(type_name):
			push_warning("LevelInstantiator: 未知外墙 type '%s'，按默认 blue 处理" % type_name)
		var resolved_dirs := {}
		var coord := Vector2i(int(resolved.get("X", 0)), int(resolved.get("Y", 0)))
		for dir_name in ["N", "S", "W", "E"]:
			if resolved.has("dirs") and resolved["dirs"].has(dir_name):
				# 写了就用写的值
				resolved_dirs[dir_name] = resolved["dirs"][dir_name]
			else:
				# 没写就自动推导（和完全不写 dirs 行为一致）
				var direction := _dir_name_to_vector(dir_name)
				resolved_dirs[dir_name] = not _find_nearest_in_direction(nodes, coord, direction).is_empty()
		resolved["dirs"] = resolved_dirs
		result.append(resolved)
	return result

## 在每对连接的节点之间生成直墙连接段（不修改原始节点，返回合并后的完整节点列表）
static func _build_connecting_segments(nodes: Array) -> Array:
	var all: Array = nodes.duplicate(true)
	var occupied := {}  # 已占用的格子坐标，避免连接段与原始节点或其他连接段重叠

	for node in nodes:
		var coord := Vector2i(int(node.get("X", 0)), int(node.get("Y", 0)))
		var dirs: Dictionary = node.get("dirs", {})
		occupied["%d,%d" % [coord.x, coord.y]] = true

		for dir_name in ["N", "S", "W", "E"]:
			if not dirs.get(dir_name, false):
				continue
			var direction := _dir_name_to_vector(dir_name)
			var target: Dictionary = _find_nearest_in_direction(nodes, coord, direction)
			if target.is_empty():
				continue
			# 连接需要双方互认：对方的相反方向也必须为 true，否则不生成连接段
			var opposite := _opposite_dir(dir_name)
			if not target.get("dirs", {}).get(opposite, false):
				continue
			var target_coord := Vector2i(int(target.get("X", 0)), int(target.get("Y", 0)))

			# 在中间逐格生成直墙连接段
			# 连接段 type：两端同色则跟随（green-green -> green），异色或缺省则用默认 blue
			var seg_type: Variant = "blue"
			var type_a: Variant = node.get("type", "blue")
			var type_b: Variant = target.get("type", "blue")
			if type_a != null and type_b != null and str(type_a).to_lower() == str(type_b).to_lower():
				seg_type = type_a
			var current := coord + direction
			while current != target_coord:
				var key := "%d,%d" % [current.x, current.y]
				if not occupied.has(key):
					occupied[key] = true
					var segment_dirs := {}
					if direction == _DIR_N or direction == _DIR_S:
						segment_dirs = {"N": true, "S": true}  # 垂直直墙
					else:
						segment_dirs = {"W": true, "E": true}  # 水平直墙
					var seg: Dictionary = {"X": current.x, "Y": current.y, "dirs": segment_dirs}
					if str(seg_type).to_lower() != "blue":
						seg["type"] = seg_type  # 非默认类型才写，保持数据简洁
					all.append(seg)
				current += direction
	return all

## 在指定方向上找最近的节点（同一行/列，距离 <= WALL_CONNECT_MAX_DISTANCE）
## type=null 的挖空节点不参与连接判断，直接跳过
static func _find_nearest_in_direction(nodes: Array, from_coord: Vector2i, direction: Vector2i) -> Dictionary:
	var best := {}
	var best_dist := WALL_CONNECT_MAX_DISTANCE + 1
	for node in nodes:
		if node.has("type") and node["type"] == null:
			continue  # 挖空节点不参与连接
		var coord := Vector2i(int(node.get("X", 0)), int(node.get("Y", 0)))
		if coord == from_coord:
			continue
		var delta := coord - from_coord
		var dist := -1
		if direction == _DIR_N and delta.x == 0 and delta.y < 0:
			dist = -delta.y
		elif direction == _DIR_S and delta.x == 0 and delta.y > 0:
			dist = delta.y
		elif direction == _DIR_W and delta.y == 0 and delta.x < 0:
			dist = -delta.x
		elif direction == _DIR_E and delta.y == 0 and delta.x > 0:
			dist = delta.x
		if dist > 0 and dist < best_dist:
			best_dist = dist
			best = node
	return best

static func _dir_name_to_vector(dir_name: String) -> Vector2i:
	match dir_name:
		"N": return _DIR_N
		"S": return _DIR_S
		"W": return _DIR_W
		"E": return _DIR_E
	return Vector2i.ZERO

## 相反方向：N<->S, W<->E
static func _opposite_dir(dir_name: String) -> String:
	match dir_name:
		"N": return "S"
		"S": return "N"
		"W": return "E"
		"E": return "W"
	return ""

## 铺设一个 32x32 墙节点 = 2x2 个 16x16 cell
## dirs: {"N":bool, "S":bool, "W":bool, "E":bool}
## type_y_offset: 图集行偏移（blue=0，green=3 等），整块素材下移
static func _paint_wall_node(tile_map: TileMapLayer, node_coord: Vector2i, dirs: Dictionary, type_y_offset: int = 0) -> void:
	var n: bool = dirs.get("N", false)
	var s: bool = dirs.get("S", false)
	var w: bool = dirs.get("W", false)
	var e: bool = dirs.get("E", false)
	var y: int = type_y_offset

	# 四个角的素材坐标（Godot atlas_coords: x=列, y=行）
	# _pick_corner(vertical, horizontal, 都不连, 只垂直连, 只水平连, 都连=内角)
	var tl := _pick_corner(n, w, Vector2i(0, 0 + y), Vector2i(0, 1 + y), Vector2i(1, 0 + y), Vector2i(4, 1 + y))
	var _tr := _pick_corner(n, e, Vector2i(2, 0 + y), Vector2i(2, 1 + y), Vector2i(1, 0 + y), Vector2i(3, 1 + y))
	var bl := _pick_corner(s, w, Vector2i(0, 2 + y), Vector2i(0, 1 + y), Vector2i(1, 2 + y), Vector2i(4, 0 + y))
	var br := _pick_corner(s, e, Vector2i(2, 2 + y), Vector2i(2, 1 + y), Vector2i(1, 2 + y), Vector2i(3, 0 + y))

	# 关卡坐标(X,Y) -> TileMapLayer cell(2X,2Y)，因为 tile=16, 关卡 cell=32
	var base := node_coord * 2
	tile_map.set_cell(base + Vector2i(0, 0), WALL_SOURCE_ID, tl)
	tile_map.set_cell(base + Vector2i(1, 0), WALL_SOURCE_ID, _tr)
	tile_map.set_cell(base + Vector2i(0, 1), WALL_SOURCE_ID, bl)
	tile_map.set_cell(base + Vector2i(1, 1), WALL_SOURCE_ID, br)

## 根据垂直/水平两个方向的连接状态，选择对应角的素材坐标
static func _pick_corner(vertical: bool, horizontal: bool,
		none_corner: Vector2i, v_only: Vector2i, h_only: Vector2i, both: Vector2i) -> Vector2i:
	if vertical and horizontal:
		return both
	if vertical:
		return v_only
	if horizontal:
		return h_only
	return none_corner

# ============================================================
# items（通用物体实例化：ButtonController / FakableWall / FakableButton）
# ============================================================
## items 数组中的每个对象根据 Class 字段实例化对应场景。
## 支持的 Class：ButtonController、FakableWall、FakableButton（大写优先匹配）。
## 向量字段（tooltip_offset / size_on / size_off 等）统一支持 [x,y] 数组和 {"x":..,"y":..} 对象。

## 按钮场景路径模板（${color} 替换为实际颜色，空 color 用基类）
const BUTTON_SCENE_PATH := "res://item/button/${color}_button.tscn"
const BUTTON_BASE_SCENE := "res://item/button/button.tscn"
## 墙场景路径模板
const WALL_SCENE_PATH := "res://item/walls/${color}_wall.tscn"
const WALL_BASE_SCENE := "res://item/walls/wall.tscn"
## ButtonController 脚本路径（只有代码，创建空 Node2D 挂载此脚本）
const BUTTON_CONTROLLER_SCRIPT := "res://item/button/button_control_wall.gd"
## Clue（线索）场景路径（路径不同改这里即可）
const CLUE_SCENE := preload("res://item/clue/clue.tscn")
## Bomb（炸弹）场景路径模板（${color} 替换为实际颜色，空 color 用基类）
const BOMB_SCENE_PATH := "res://item/bomb/${color}_bomb.tscn"
const BOMB_BASE_SCENE := "res://item/bomb/bomb.tscn"
## MapMirror（映射镜）场景路径
const MIRROR_SCENE := preload("res://item/mirror/map_mirror.tscn")

## 已知类名（大写优先匹配，小写也能匹配到对应大写类名）
const KNOWN_CLASSES := ["ButtonController", "FakableWall", "FakableButton", "Clue", "FakableBomb", "MapMirror"]

## 实例化所有 items，返回实例化出的节点数组（无则空数组）
static func spawn_items(level: LevelData, parent: Node, refs: Dictionary = {}) -> Array[Node]:
	var spawned: Array[Node] = []
	for item in level.items:
		if typeof(item) == TYPE_DICTIONARY:
			# MapMirror 依赖 items/characters 的 name 引用（tomap），
			# 由 spawn_mirrors 在所有节点实例化后统一处理，这里跳过
			if _resolve_class_name(item) == "MapMirror":
				continue
			var node := _spawn_single_item(item, level, parent, refs)
			if node:
				spawned.append(node)
				_register_named_ref(refs, node, item)
	return spawned

## 根据 Class 字段分发到具体的实例化函数，返回实例化出的节点（未知类型返回 null）
## refs 传给 ButtonController（其 button/wall 数组可能按 name 绑定之前单独实例化的 item）
static func _spawn_single_item(item: Dictionary, level: LevelData, parent: Node, refs: Dictionary = {}) -> Node:
	var item_class := _resolve_class_name(item)
	match item_class:
		"ButtonController":
			return _spawn_button_controller(item, level, parent, refs)
		"FakableWall":
			return _spawn_fakable_wall(item, level, parent)
		"FakableButton":
			return _spawn_fakable_button(item, level, parent)
		"Clue":
			return _spawn_clue(item, level, parent)
		"FakableBomb":
			return _spawn_fakable_bomb(item, level, parent)
		"MapMirror":
			# mirror 由 spawn_mirrors 在 items/characters 之后统一实例化（tomap 依赖 name 引用），这里不处理
			return null
		_:
			push_warning("LevelInstantiator: 未知的 Class '%s'，跳过" % item_class)
			return null

## 解析 Class 字段：大写优先，无大写再看小写（都匹配到已知类名）
static func _resolve_class_name(item: Dictionary) -> String:
	var raw := str(item.get("Class", item.get("class", "")))
	if raw.is_empty():
		return ""
	for name in KNOWN_CLASSES:
		if raw.to_lower() == name.to_lower():
			return name
	return raw

## 解析 item 的世界坐标（X/Y 大写，允许浮点）-> 实际坐标 Vector2（像素，格子中心）
static func world_coord_to_vector2(world: Dictionary, level: LevelData) -> Vector2:
	return level.coord_to_world_center(Vector2(
		float(world.get("X", 0)),
		float(world.get("Y", 0))
	))

## 世界坐标 {X, Y}（允许浮点）-> 实际坐标 {x, y}（像素）
static func world_coord_to_xy(world: Dictionary, level: LevelData) -> Dictionary:
	var v := world_coord_to_vector2(world, level)
	return {"x": v.x, "y": v.y}

## 解析向量字段，支持 [x,y] 数组和 {"x":..,"y":..} 对象（大小写 x/y 都认）
static func _parse_vector2(data: Variant, default: Vector2 = Vector2.ZERO) -> Vector2:
	if typeof(data) == TYPE_ARRAY and data.size() >= 2:
		return Vector2(float(data[0]), float(data[1]))
	if typeof(data) == TYPE_DICTIONARY:
		return Vector2(
			float(data.get("x", data.get("X", default.x))),
			float(data.get("y", data.get("Y", default.y)))
		)
	return default

## 解析尺寸字段：支持 [x,y] 数组、{"x":..,"y":..} 对象、{"W":..,"H":..} 格子单位。
## 格子单位（W/H）通过 level.coord_to_world 转成像素 Vector2。
static func _parse_size(data: Variant, level: LevelData, default: Vector2) -> Vector2:
	if typeof(data) == TYPE_DICTIONARY and data.has("W") and data.has("H"):
		return level.coord_to_world(Vector2(
			float(data["W"]),
			float(data["H"])
		))
	return _parse_vector2(data, default)

## 朝向 -> anchor 映射（伸缩朝向，非按钮 on/off 朝向）
static func _facing_to_anchor(facing: String) -> Vector2:
	match facing:
		"N", "n": return Vector2(0.5, 1)
		"S", "s": return Vector2(0.5, 0)
		"W", "w": return Vector2(1, 0.5)
		"E", "e": return Vector2(0, 0.5)
	return Vector2(0.5, 0.5)

## 应用 fake / fakable 到 FakableObject（用 set_fake 绕过 fakable 限制）
static func _apply_fake(obj: Node, item: Dictionary) -> void:
	if not (obj is FakableObject):
		return
	if item.has("fakable"):
		obj.fakable = item["fakable"]
	if item.has("fake"):
		obj.set_fake(item["fake"])

## 根据 color 生成按钮场景路径（空 color 用基类 button.tscn）
static func _button_scene_path(color: String) -> String:
	if color.is_empty():
		return BUTTON_BASE_SCENE
	return BUTTON_SCENE_PATH.replace("${color}", color)

## 根据 color 生成墙场景路径（空 color 用基类 wall.tscn）
static func _wall_scene_path(color: String) -> String:
	if color.is_empty():
		return WALL_BASE_SCENE
	return WALL_SCENE_PATH.replace("${color}", color)

## 实例化按钮（通用，被 ButtonController 和单独按钮共用）
## 返回实例化后的按钮节点
static func _instantiate_button(btn_data: Dictionary, level: LevelData, parent: Node) -> Node2D:
	var color := str(btn_data.get("color", ""))
	var scene := load(_button_scene_path(color)) as PackedScene
	var btn := scene.instantiate() as Node2D
	parent.add_child(btn)
	btn.global_position = world_coord_to_vector2(btn_data, level)
	# tooltip_offset（支持 [x,y] 数组和 {"x":..,"y":..} 对象）
	if btn_data.has("tooltip_offset"):
		var offset := _parse_vector2(btn_data["tooltip_offset"])
		var ic := btn.get_node_or_null("InteractComponent")
		if ic:
			ic.tooltip_offset = offset

	# fake / fakable
	_apply_fake(btn, btn_data)
	return btn

## 实例化墙（通用，被 ButtonController 和单独墙共用）
## 返回实例化后的墙节点
static func _instantiate_wall(wall_data: Dictionary, level: LevelData, parent: Node) -> Node2D:
	var color := str(wall_data.get("color", ""))
	var scene := load(_wall_scene_path(color)) as PackedScene
	var wall := scene.instantiate() as Node2D

	# 朝向 -> anchor（支持 "facing" 和 "朝向" 两种键名）
	# anchor 赋值需早于尺寸赋值，否则尺寸设置后会出现异常
	var facing := str(wall_data.get("facing", wall_data.get("朝向", "")))
	if not facing.is_empty() and wall.has_method("set"):
		wall.anchor = _facing_to_anchor(facing)

	# 尺寸（支持 [x,y] 数组、{"x":..,"y":..} 对象和 {"W":..,"H":..} 格子单位）
	# 尺寸赋值需早于 add_child（早于 ready 阶段），否则会出现动画异常
	if wall_data.has("size"):
		wall.size = _parse_size(wall_data["size"], level, wall.size)

	parent.add_child(wall)
	wall.global_position = world_coord_to_vector2(wall_data, level)
	# auto_offset：可选字段，默认开——坐标向 facing 反方向偏移半格，
	# 修正墙从格子中心向一侧伸缩导致的半格错位；无 facing 不处理
	if not facing.is_empty() and wall.has_method("set"):
		if bool(wall_data.get("auto_offset", true)):
			wall.global_position += _facing_opposite_half_cell(facing, level.cell_size)

	# fake / fakable
	_apply_fake(wall, wall_data)
	return wall

## facing 反方向的半格偏移量（FakableWall auto_offset 用）。
## N/S/W/E：向伸缩方向的反方向移半格（Y 向下：N 的反方向=下 +y，S=上 -y，W=右 +x，E=左 -x）
static func _facing_opposite_half_cell(facing: String, cell_size: Vector2i) -> Vector2:
	var half := Vector2(cell_size) * 0.5
	match facing:
		"N", "n": return Vector2(0, half.y)
		"S", "s": return Vector2(0, -half.y)
		"W", "w": return Vector2(half.x, 0)
		"E", "e": return Vector2(-half.x, 0)
	return Vector2.ZERO

## ButtonController 子对象（button/wall 数组元素）解析，支持三种形式：
##   1. 普通对象 {X,Y,color,...}      -> 重新实例化（is_button 决定用按钮还是墙场景）
##   2. 字符串 "name"                  -> 绑定单独实例化 item 的节点（refs[name]）
##   3. {"bind": "name"}              -> 同上，显式绑定
## 绑定的 name 若此刻 refs 里还没有（被绑定的 item 写在后面），记进 pending，
## 由 _resolve_bc_bindings 在所有 items 实例化后统一解析，因此与书写顺序无关。
static func _resolve_bc_child(data: Variant, level: LevelData, parent: Node, refs: Dictionary, is_button: bool, pending: Array) -> Node2D:
	var bound_name := ""
	if typeof(data) == TYPE_STRING:
		bound_name = str(data)
	elif typeof(data) == TYPE_DICTIONARY and data.has("bind"):
		bound_name = str(data["bind"])
	if not bound_name.is_empty():
		var node: Variant = refs.get(bound_name)
		if node is Node2D:
			return node
		# 此刻还没有 -> 记入待绑定，稍后统一解析（与顺序无关）
		pending.append(bound_name)
		return null
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("LevelInstantiator: ButtonController 子对象格式无效，跳过：%s" % str(data))
		return null
	if is_button:
		return _instantiate_button(data, level, parent)
	return _instantiate_wall(data, level, parent)

## 解析所有 ButtonController 的待绑定引用（_resolve_bc_child 里未即时解析的 name）。
## 必须在所有 items 实例化完成、refs 引用齐全后调用。
static func _resolve_bc_bindings(_level: LevelData, _parent: Node, refs: Dictionary) -> void:
	for node in (refs.get("items", []) as Array):
		if not (node.has_meta("_pending_buttons") or node.has_meta("_pending_walls")):
			continue
		for name in (node.get_meta("_pending_buttons", []) as Array):
			var target: Variant = refs.get(str(name))
			if target is Node2D:
				node.buttons.append(target)
			else:
				push_warning("LevelInstantiator: ButtonController 绑定 '%s' 未找到（需为单独实例化 item 的 name）" % name)
		for name in (node.get_meta("_pending_walls", []) as Array):
			var target: Variant = refs.get(str(name))
			if target is Node2D:
				node.walls.append(target)
			else:
				push_warning("LevelInstantiator: ButtonController 绑定 '%s' 未找到（需为单独实例化 item 的 name）" % name)

## ButtonController 实例化：空 Node2D + 挂脚本，然后实例化 buttons 和 walls 挂载其下。
## 返回 ButtonController 节点。
## refs 用于按 name 绑定之前单独实例化的按钮/墙（见 _resolve_bc_child）。
static func _spawn_button_controller(item: Dictionary, level: LevelData, parent: Node, refs: Dictionary = {}) -> Node:
	var bc := Node2D.new()
	bc.name = "ButtonController"
	var script := load(BUTTON_CONTROLLER_SCRIPT) as Script
	bc.set_script(script)
	parent.add_child(bc)
	var bc_pos := world_coord_to_vector2(item, level)
	bc.position = bc_pos

	var buttons: Array[Node2D] = []
	var walls: Array[Node2D] = []
	var pending_buttons: Array = []
	var pending_walls: Array = []

	# buttons：JSON 键名单数 button 优先，复数 buttons 兼容。
	# 元素支持三种形式：普通对象（重新实例化）/ 字符串 name / {"bind": name}（绑定单独实例化的按钮）
	for btn_data in item.get("button", item.get("buttons", [])):
		var btn := _resolve_bc_child(btn_data, level, bc, refs, true, pending_buttons)
		if btn:
			buttons.append(btn)

	# walls：同上
	for wall_data in item.get("wall", item.get("walls", [])):
		var wall := _resolve_bc_child(wall_data, level, bc, refs, false, pending_walls)
		if wall:
			walls.append(wall)

	bc.buttons = buttons
	bc.walls = walls

	# 有未即时解析的绑定引用则记入 meta，由 _resolve_bc_bindings 在所有 items 实例化后统一解析
	if not pending_buttons.is_empty():
		bc.set_meta("_pending_buttons", pending_buttons)
	if not pending_walls.is_empty():
		bc.set_meta("_pending_walls", pending_walls)

	# size_on / size_off（支持 [x,y] 数组、{"x":..,"y":..} 对象、{"W":..,"H":..} 格子单位）
	if item.has("size_on"):
		bc.size_on = _parse_size(item["size_on"], level, bc.size_on)
	if item.has("size_off"):
		bc.size_off = _parse_size(item["size_off"], level, bc.size_off)
	return bc

## 单独的 FakableWall
static func _spawn_fakable_wall(item: Dictionary, level: LevelData, parent: Node) -> Node:
	return _instantiate_wall(item, level, parent)

## 单独的 FakableButton
static func _spawn_fakable_button(item: Dictionary, level: LevelData, parent: Node) -> Node:
	return _instantiate_button(item, level, parent)

## 单独的 Clue（线索）：必需字段只有坐标，可选 content / duration / id / facing
## 与 exit 同理，实例化设完旋转后要再调一次 interact_comp.reset_rotation(false)，
## 因为 _ready() 里的 reset_rotation 在 add_child 时就执行了（那时旋转还是 0）。
static func _spawn_clue(item: Dictionary, level: LevelData, parent: Node) -> Node:
	var clue := CLUE_SCENE.instantiate() as Node2D
	parent.add_child(clue)
	clue.global_position = world_coord_to_vector2(item, level)

	# 朝向（缺省 E=不旋转），复用 CoordinateSystem 公式
	var facing := str(item.get("facing", "E"))
	clue.rotation_degrees = CoordinateSystem.facing_to_rotation(facing)
	var ic := clue.get_node_or_null("InteractComponent")
	if ic and ic.has_method("reset_rotation"):
		ic.reset_rotation(false)

	# 可选字段：content / duration / id
	if item.has("content"):
		clue.content = str(item["content"])
	if item.has("duration"):
		clue.duration = float(item["duration"])
	if item.has("id"):
		clue.id = str(item["id"])

	# fake / fakable
	_apply_fake(clue, item)
	return clue

## 单独的 Bomb（炸弹）：color 可选（对应 ${color}_bomb.tscn，缺省用基类 bomb.tscn）
static func _spawn_fakable_bomb(item: Dictionary, level: LevelData, parent: Node) -> Node:
	var color := str(item.get("color", ""))
	var scene := load(_bomb_scene_path(color)) as PackedScene
	var bomb := scene.instantiate() as Node2D
	parent.add_child(bomb)
	bomb.global_position = world_coord_to_vector2(item, level)
	# fake / fakable
	_apply_fake(bomb, item)
	return bomb

## 根据 color 生成炸弹场景路径（空 color 用基类 bomb.tscn）
static func _bomb_scene_path(color: String) -> String:
	if color.is_empty():
		return BOMB_BASE_SCENE
	return BOMB_SCENE_PATH.replace("${color}", color)

# ============================================================
# mirror（映射镜 MapMirror）：axis + tomap
# ============================================================
## 实例化所有 MapMirror。必须在 items 和 characters 实例化完成后调用，
## 因为 mirror 的 tomap 按 name 引用那些节点，且 mirror._ready() 会遍历 nodes_tomap
## 创建映射节点，所以 nodes_tomap 需在 add_child（触发 _ready）前填好。
## 返回实例化出的 mirror 节点数组。
static func spawn_mirrors(level: LevelData, parent: Node, refs: Dictionary = {}) -> Array[Node]:
	var mirrors: Array[Node] = []
	for item in level.items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if _resolve_class_name(item) != "MapMirror":
			continue
		var mirror := _spawn_mirror(item, level, parent, refs)
		if mirror:
			mirrors.append(mirror)
			_register_named_ref(refs, mirror, item)
	return mirrors

## 实例化单个 MapMirror。JSON 特有字段：
##   axis: 可选，X / Y（或 0 / 1），对应 MapMirror.axis，缺省 X
##   tomap: 可选，数组，值为 item / character 的 name（须已有 name 引用）
static func _spawn_mirror(item: Dictionary, level: LevelData, parent: Node, refs: Dictionary) -> MapMirror:
	var mirror := MIRROR_SCENE.instantiate() as MapMirror

	# axis（可选，缺省 X）；int 值需 as 转成枚举类型（Godot 静态类型要求）
	mirror.axis = _parse_mirror_axis(item.get("axis", "X")) as MapMirror.Axis
	# tomap（可选，name 数组 -> 节点；此时 refs 已含全部 item/character 的 name 引用）
	mirror.nodes_tomap = _resolve_tomap(item.get("tomap", []), refs)

	# 位置需在 add_child 前设置：mirror._ready() 创建映射节点时基于 self 位置计算对称轴
	mirror.global_position = world_coord_to_vector2(item, level)
	parent.add_child(mirror)  # 触发 _ready()，此时 nodes_tomap 已就位

	# tooltip_offset（可选，支持 [x,y] 数组和 {"x":..,"y":..} 对象）
	if item.has("tooltip_offset"):
		var offset := _parse_vector2(item["tooltip_offset"])
		var ic := mirror.get_node_or_null("InteractComponent")
		if ic:
			ic.tooltip_offset = offset
	return mirror

## 解析 axis 字段：X / Y 字符串，或 0 / 1 整数（返回枚举类型）
static func _parse_mirror_axis(data: Variant) -> MapMirror.Axis:
	match str(data).to_lower():
		"y", "1":
			return MapMirror.Axis.Y
		_:
			return MapMirror.Axis.X

## 把 tomap 的 name 数组解析成节点数组（从 refs 引用表取，未找到则警告跳过）
static func _resolve_tomap(names: Variant, refs: Dictionary) -> Array[Node2D]:
	var list: Array[Node2D] = []
	if typeof(names) != TYPE_ARRAY:
		return list
	for name in names:
		var target: Variant = refs.get(str(name))
		if target is Node2D:
			list.append(target)
		else:
			push_warning("LevelInstantiator: mirror 的 tomap 引用 '%s' 未找到（需为 item/character 的 name）" % name)
	return list

# ============================================================
# characters（角色实例化：Player / Dolos_Black）
# ============================================================

## 实例化所有角色，返回实例化出的节点数组（无则空数组）
static func spawn_characters(level: LevelData, parent: Node, refs: Dictionary = {}) -> Array[Node]:
	var spawned: Array[Node] = []
	for char_data in level.characters:
		if typeof(char_data) == TYPE_DICTIONARY:
			var node := _spawn_single_character(char_data, level, parent)
			if node:
				spawned.append(node)
				_register_named_ref(refs, node, char_data)

				# 注册演员表，服务于事件系统
				var n := str(char_data.get("name", ""))
				if not n.is_empty() and "actors" in parent:
					parent.actors[n] = node
	return spawned

## 根据 type 字段分发到具体角色的实例化函数，返回实例化出的节点（未知类型返回 null）
static func _spawn_single_character(char_data: Dictionary, level: LevelData, parent: Node) -> Node:
	var char_type := str(char_data.get("type", char_data.get("Type", char_data.get("class", ""))))
	match char_type.to_lower():
		"player":
			return _spawn_player(char_data, level, parent)
		"dolos_black", "dolosblack":
			return _spawn_dolos_black(char_data, level, parent)
		_:
			push_warning("LevelInstantiator: 未知角色类型 '%s'，跳过" % char_type)
			return null

## 应用角色朝向（facing: N/S/W/E，缺省 E=不旋转）
static func _apply_character_facing(node: Node2D, char_data: Dictionary) -> void:
	var facing := str(char_data.get("facing", "E"))
	if not facing.is_empty():
		node.rotation_degrees = CoordinateSystem.facing_to_rotation(facing)

## 实例化 Player 角色
static func _spawn_player(char_data: Dictionary, level: LevelData, parent: Node) -> CharacterBody2D:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.name = "Player"  # 稳定节点名，方便 get_node / 场景树里找
	parent.add_child(player)

	# 基础坐标（格子中心对齐）
	player.position = level.coord_to_world_center(Vector2(
		float(char_data.get("X", 0)),
		float(char_data.get("Y", 0))
	))

	# 朝向（缺省 E）
	_apply_character_facing(player, char_data)

	# 可选：是否可移动（依赖 player.gd 有 movable 属性）
	if char_data.has("movable"):
		if "movable" in player:
			player.movable = char_data["movable"]

	# 可选：是否可交互（控制分组 + 交互组件）
	if char_data.has("interactable"):
		var interactable = char_data["interactable"]
		if interactable:
			player.add_to_group("interactable")
		else:
			player.remove_from_group("interactable")
		var interact_comp := player.get_node_or_null("InteractComponent")
		if interact_comp and interact_comp.has("disabled"):
			interact_comp.disabled = not interactable

	# 可选：视野角度（设置 view_area 组件的 angle_deg）
	if char_data.has("view_angle"):
		var view_area := player.get_node_or_null("sprite/eyes/view_area")
		if view_area:
			view_area.angle_deg = float(char_data["view_angle"])
	return player

## 实例化 Dolos_Black 角色
static func _spawn_dolos_black(char_data: Dictionary, level: LevelData, parent: Node) -> Node2D:
	var npc := DOLOS_BLACK_SCENE.instantiate() as Node2D
	npc.name = "Dolos_Black"  # 稳定节点名（多个时会自动加 @ 后缀区分）
	parent.add_child(npc)

	# 基础坐标（格子中心对齐）
	npc.position = level.coord_to_world_center(Vector2(
		float(char_data.get("X", 0)),
		float(char_data.get("Y", 0))
	))

	# 朝向（缺省 E）
	_apply_character_facing(npc, char_data)
	return npc
