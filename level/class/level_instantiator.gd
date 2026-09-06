class_name LevelInstantiator
## 实例化层：把 LevelData 转成场景节点。
##   floor         -> 实例化 floor.tscn，按 fill_rect 铺地板
##   exit          -> 实例化 exit.tscn，摆坐标 + 朝向 + 可选 next_scene / tooltip_offset
##   external_wall -> TileMapLayer，按 dirs 连通性用 16x16 小格拼 32x32 墙节点
##
## 依赖场景（路径不同改下面常量即可）：
##   res://item/floor/floor.tscn
##   res://item/exit/exit.tscn
##   res://item/walls/external_wall.tscn

const FLOOR_SCENE := preload("res://item/floor/floor.tscn")
const EXIT_SCENE := preload("res://item/exit/exit.tscn")
const EXTERNAL_WALL_SCENE := preload("res://item/walls/external_wall.tscn")

const WALL_SOURCE_ID := 0
## 外墙节点自动连接的最大距离（格子单位）。
## 同一行/列上距离在此以内的节点会被认为是连接的，中间自动铺直墙连接段。
## 需要调整时改这个常量即可。
const WALL_CONNECT_MAX_DISTANCE := 50

# 方向常量（与 CoordinateSystem 一致，这里局部复用避免循环依赖）
const _DIR_N := Vector2i(0, -1)
const _DIR_S := Vector2i(0, 1)
const _DIR_W := Vector2i(-1, 0)
const _DIR_E := Vector2i(1, 0)

## 把整个关卡实例化到 parent 下。返回是否全部成功。
static func build_level(level: LevelData, parent: Node) -> bool:
	var ok := true
	if level.has_floor():
		ok = spawn_floor(level, parent) and ok
	if not level.external_walls.is_empty():
		ok = spawn_external_walls(level, parent) and ok
	if not level.items.is_empty():
		ok = spawn_items(level, parent) and ok
	if level.has_exit():
		ok = spawn_exit(level, parent) and ok
	return ok

# ============================================================
# floor
# ============================================================

## 地板：JSON {X,Y,W,H,seed?} -> 瓦片矩形
static func spawn_floor(level: LevelData, parent: Node) -> bool:
	var floor_node := FLOOR_SCENE.instantiate() as Floor
	floor_node.auto_generate = false   # 关掉默认矩形，避免先铺一遍再覆盖
	if level.floor_seed != -1:
		floor_node.seed_value = level.floor_seed  # 固定种子，关卡可复现
	parent.add_child(floor_node)
	floor_node.generate_area(level.floor_rect)
	return true

# ============================================================
# exit
# ============================================================

## 出口：JSON {X,Y,facing,next_scene?,tooltip_offset?} -> 坐标 + 朝向 + 可选属性
static func spawn_exit(level: LevelData, parent: Node) -> bool:
	var exit_node := EXIT_SCENE.instantiate() as Exit
	parent.add_child(exit_node)

	var coord := Vector2i(
		int(level.exit.get("X", 0)),
		int(level.exit.get("Y", 0))
	)
	exit_node.position = level.coord_to_world_center(coord)
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

	return true

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

## 外墙：节点数组 -> TileMapLayer 铺设（含自动连接段）
static func spawn_external_walls(level: LevelData, parent: Node) -> bool:
	if level.external_walls.is_empty():
		return true

	var tile_map := EXTERNAL_WALL_SCENE.instantiate() as TileMapLayer
	parent.add_child(tile_map)
	tile_map.clear()  # 场景默认带瓦片，生成前先清空

	# 1. 推导所有节点的 dirs（显式或自动）
	var nodes_with_dirs: Array = _resolve_all_wall_dirs(level.external_walls)

	# 2. 在每对连接的节点之间生成直墙连接段
	var all_nodes: Array = _build_connecting_segments(nodes_with_dirs)

	# 3. 统一铺设（原始节点 + 自动生成的连接段）
	for node in all_nodes:
		var coord := Vector2i(int(node.get("X", 0)), int(node.get("Y", 0)))
		var dirs: Dictionary = node.get("dirs", {})
		_paint_wall_node(tile_map, coord, dirs)
	return true

## 推导所有节点的 dirs：
##   - dirs 中写了的方向，用写的值
##   - dirs 中没写的方向（包括完全不写 dirs 的情况），自动根据相邻节点推导
## 最终每个节点都有完整的 N/S/W/E 四个方向。
static func _resolve_all_wall_dirs(nodes: Array) -> Array:
	var result := []
	for node in nodes:
		var resolved: Dictionary = node.duplicate(true)
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
					all.append({"X": current.x, "Y": current.y, "dirs": segment_dirs})
				current += direction
	return all

## 在指定方向上找最近的节点（同一行/列，距离 <= WALL_CONNECT_MAX_DISTANCE）
static func _find_nearest_in_direction(nodes: Array, from_coord: Vector2i, direction: Vector2i) -> Dictionary:
	var best := {}
	var best_dist := WALL_CONNECT_MAX_DISTANCE + 1
	for node in nodes:
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
static func _paint_wall_node(tile_map: TileMapLayer, node_coord: Vector2i, dirs: Dictionary) -> void:
	var n: bool = dirs.get("N", false)
	var s: bool = dirs.get("S", false)
	var w: bool = dirs.get("W", false)
	var e: bool = dirs.get("E", false)

	# 四个角的素材坐标（Godot atlas_coords: x=列, y=行）
	# _pick_corner(vertical, horizontal, 都不连, 只垂直连, 只水平连, 都连=内角)
	var tl := _pick_corner(n, w, Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(4, 1))
	var _tr := _pick_corner(n, e, Vector2i(2, 0), Vector2i(2, 1), Vector2i(1, 0), Vector2i(3, 1))
	var bl := _pick_corner(s, w, Vector2i(0, 2), Vector2i(0, 1), Vector2i(1, 2), Vector2i(4, 0))
	var br := _pick_corner(s, e, Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 2), Vector2i(3, 0))

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

## 已知类名（大写优先匹配，小写也能匹配到对应大写类名）
const KNOWN_CLASSES := ["ButtonController", "FakableWall", "FakableButton"]

## 实例化所有 items
static func spawn_items(level: LevelData, parent: Node) -> bool:
	for item in level.items:
		if typeof(item) == TYPE_DICTIONARY:
			_spawn_single_item(item, level, parent)
	return true

## 根据 Class 字段分发到具体的实例化函数
static func _spawn_single_item(item: Dictionary, level: LevelData, parent: Node) -> void:
	var item_class := _resolve_class_name(item)
	match item_class:
		"ButtonController":
			_spawn_button_controller(item, level, parent)
		"FakableWall":
			_spawn_fakable_wall(item, level, parent)
		"FakableButton":
			_spawn_fakable_button(item, level, parent)
		_:
			push_warning("LevelInstantiator: 未知的 Class '%s'，跳过" % item_class)

## 解析 Class 字段：大写优先，无大写再看小写（都匹配到已知类名）
static func _resolve_class_name(item: Dictionary) -> String:
	var raw := str(item.get("Class", item.get("class", "")))
	if raw.is_empty():
		return ""
	for name in KNOWN_CLASSES:
		if raw.to_lower() == name.to_lower():
			return name
	return raw

## 解析 item 的格子坐标（X/Y 大写，整数）
static func _item_grid_coord(item: Dictionary) -> Vector2i:
	return Vector2i(int(item.get("X", 0)), int(item.get("Y", 0)))

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

## 朝向 -> anchor 映射（伸缩朝向，非按钮 on/off 朝向）
static func _facing_to_anchor(facing: String) -> Vector2:
	match facing:
		"N", "n": return Vector2(0.5, 0)
		"S", "s": return Vector2(0.5, 1)
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
	btn.global_position = level.coord_to_world_center(_item_grid_coord(btn_data))

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
	parent.add_child(wall)
	wall.global_position = level.coord_to_world_center(_item_grid_coord(wall_data))

	# 朝向 -> anchor（支持 "facing" 和 "朝向" 两种键名）
	var facing := str(wall_data.get("facing", wall_data.get("朝向", "")))
	if not facing.is_empty() and wall.has_method("set"):
		wall.anchor = _facing_to_anchor(facing)

	# fake / fakable
	_apply_fake(wall, wall_data)
	return wall

## ButtonController 实例化：空 Node2D + 挂脚本，然后实例化 buttons 和 walls 挂载其下
static func _spawn_button_controller(item: Dictionary, level: LevelData, parent: Node) -> void:
	var bc := Node2D.new()
	var script := load(BUTTON_CONTROLLER_SCRIPT) as Script
	bc.set_script(script)
	parent.add_child(bc)
	var bc_pos := level.coord_to_world_center(_item_grid_coord(item))
	bc.position = bc_pos

	var buttons: Array[Node2D] = []
	var walls: Array[Node2D] = []

	# 实例化 buttons（挂载到 ButtonController 下，global_position 自动转相对坐标）
	for btn_data in item.get("buttons", []):
		if typeof(btn_data) == TYPE_DICTIONARY:
			var btn := _instantiate_button(btn_data, level, bc)
			buttons.append(btn)

	# 实例化 walls（挂载到 ButtonController 下，global_position 自动转相对坐标）
	for wall_data in item.get("walls", []):
		if typeof(wall_data) == TYPE_DICTIONARY:
			var wall := _instantiate_wall(wall_data, level, bc)
			walls.append(wall)

	bc.buttons = buttons
	bc.walls = walls

	# size_on / size_off（支持 [x,y] 数组和 {"x":..,"y":..} 对象）
	if item.has("size_on"):
		bc.size_on = _parse_vector2(item["size_on"], bc.size_on)
	if item.has("size_off"):
		bc.size_off = _parse_vector2(item["size_off"], bc.size_off)

## 单独的 FakableWall
static func _spawn_fakable_wall(item: Dictionary, level: LevelData, parent: Node) -> void:
	_instantiate_wall(item, level, parent)

## 单独的 FakableButton
static func _spawn_fakable_button(item: Dictionary, level: LevelData, parent: Node) -> void:
	_instantiate_button(item, level, parent)
