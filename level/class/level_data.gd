class_name LevelData
extends RefCounted
## 关卡数据：只保存数据 + JSON 互转，不掺游戏逻辑。
##
## 对应关卡文件 JSON 结构（Y 向下）：
##   format_version: int | [min,max] | {min,max}
##   meta.id         必要，唯一标识
##   meta.name       缺省用 id
##   meta.description 可选
##   map.cell_size   必要（每格像素宽高，兼瓦片尺寸）
##   map.floor       可选（X,Y,W,H 瓦片矩形 + seed）→ 有才实例化地板
##   map.external_wall 可选（外墙节点数组）
##   map.exit        可选（X,Y,facing,next_scene）→ 有才实例化出口
##   characters      可选（角色数组，与 map、items 同级）
##     - type: 必选，角色类型 Player / Dolos_Black
##     - X,Y: 必选，格子坐标（整数）
##     - facing: 可选，朝向 N/S/W/E，默认 E
##     - movable: 可选（仅Player），是否可移动，默认 true
##     - interactable: 可选（仅Player），是否可交互，默认 true
##     - view_angle: 可选（仅Player），视野角度（度），默认 45
##
## 注意：JSON 数字解析后一律是 float（Godot JSON.parse_string 行为），
## from_dict 里所有读数字的地方都要 int() 显式转回整数，to_dict 才写回干净整数。

## 当前代码支持的格式版本
const FORMAT_VERSION := 1

## 格式版本声明：int / [min,max] / {min,max}
var format_version = FORMAT_VERSION

# ---------- meta ----------
var id := ""          # 必要
var name := ""        # 缺省用 id
var description := "" # 可选

# ---------- map ----------
var cell_size := Vector2i(32, 32)	# 必要：每格像素宽高（瓦片统一 32px）
var floor_rect := Rect2i()			# 可选：X,Y,W,H（瓦片）
var floor_seed := -1				# 可选：-1 随机，其他值固定（对应 floor 的 seed）
var floor_preset_tiles: Array = []	# 可选：预制瓦片 [{X,Y,tile:[x,y],facing?}]（先铺、generate 不覆盖）
var floor_name := ""				# 可选：引用键名（会写进 build_level_with_refs 的 refs）
var external_walls: Array = []		# 可选：[{X,Y,dirs:{N,S,W,E}}]
var exit := {}						# 可选：{X, Y, facing, next_scene?}
var items: Array = []				# 可选：物体数组(ButtonController / FakableWall / FakableButton ...)
var characters: Array = []			# 可选：角色数组(Player / DolosBlack ...)
var events: Array = []				# 可选：事件数组，一个数组表示一个事件

# ---------- 便捷判断 ----------
func has_floor() -> bool:
	return floor_rect.size.x > 0 and floor_rect.size.y > 0

func has_exit() -> bool:
	return not exit.is_empty()

## 坐标是否在地板区域内（无地板则为 false）
func is_inside_floor(coord: Vector2i) -> bool:
	return has_floor() and floor_rect.has_point(coord)

# ---------- 坐标便捷方法（转发给 CoordinateSystem，公式只此一份） ----------
## 格子坐标 -> 世界像素坐标（格子左上角）。coord 允许浮点（如 1.5 格）。
func coord_to_world(coord: Vector2) -> Vector2:
	return CoordinateSystem.coord_to_world(coord, Vector2(cell_size))

## 格子中心像素坐标（放实体 / 出口用）。coord 允许浮点。
func coord_to_world_center(coord: Vector2) -> Vector2:
	return CoordinateSystem.coord_to_world_center(coord, Vector2(cell_size))

func world_to_coord(world: Vector2) -> Vector2i:
	return CoordinateSystem.world_to_coord(world, Vector2(cell_size))

# ---------- 序列化 ----------
func to_dict() -> Dictionary:
	var d := {
		"format_version": format_version,
		"meta": {
			"id": id,
			"name": name,
			"description": description,
		},
		"map": {
			"cell_size": {"width": cell_size.x, "height": cell_size.y},
		},
	}
	if has_floor():
		var floor_dict := {
			"X": floor_rect.position.x,
			"Y": floor_rect.position.y,
			"W": floor_rect.size.x,
			"H": floor_rect.size.y,
		}
		if floor_seed != -1:
			floor_dict["seed"] = floor_seed
		if not floor_preset_tiles.is_empty():
			floor_dict["preset_tile"] = floor_preset_tiles.duplicate(true)  # 单数优先
		if not floor_name.is_empty():
			floor_dict["name"] = floor_name
		d["map"]["floor"] = floor_dict
	if not external_walls.is_empty():
		d["map"]["external_wall"] = external_walls.duplicate(true)
	if not items.is_empty():
		d["item"] = items.duplicate(true)  # 单数优先
	if not characters.is_empty():
		d["character"] = characters.duplicate(true)  # 单数优先
	if not events.is_empty():
		d["event"] = events.duplicate(true)  # 单数优先
	if has_exit():
		d["map"]["exit"] = exit.duplicate(true)
	return d

static func from_dict(d: Dictionary) -> LevelData:
	var level := LevelData.new()
	var fv: Variant = d.get("format_version", FORMAT_VERSION)
	if typeof(fv) == TYPE_FLOAT:
		fv = int(fv)  # JSON 数字是 float，版本号按整数语义规范化
	level.format_version = fv

	# meta
	var meta: Dictionary = d.get("meta", {})
	level.id = str(meta.get("id", ""))
	level.name = str(meta.get("name", ""))
	if level.name.is_empty():
		level.name = level.id
	level.description = str(meta.get("description", ""))

	# map
	var map_data: Dictionary = d.get("map", {})
	var cs: Dictionary = map_data.get("cell_size", {})
	level.cell_size = Vector2i(
		int(cs.get("width", level.cell_size.x)),
		int(cs.get("height", level.cell_size.y))
	)

	# floor（可选，无则不实例化）
	var floor_data: Dictionary = map_data.get("floor", {})
	if not floor_data.is_empty():
		level.floor_rect = Rect2i(
			int(floor_data.get("X", 0)),
			int(floor_data.get("Y", 0)),
			int(floor_data.get("W", 0)),
			int(floor_data.get("H", 0))
		)
		level.floor_seed = int(floor_data.get("seed", -1))
		level.floor_name = str(floor_data.get("name", ""))  # 可选引用键名
		# 预制瓦片（可选）：[{X, Y, tile:[x,y], facing?}]
		# X/Y 是瓦片格子坐标必须整数；tile 是 Atlas 坐标 [x,y] 必须整数
		var presets: Variant = floor_data.get("preset_tile", floor_data.get("preset_tiles", []))  # 单数优先，复数兼容
		if typeof(presets) == TYPE_ARRAY:
			level.floor_preset_tiles = presets.duplicate(true)
			for preset in level.floor_preset_tiles:
				if typeof(preset) != TYPE_DICTIONARY:
					continue
				preset["X"] = int(preset.get("X", 0))
				preset["Y"] = int(preset.get("Y", 0))
				var tile_data: Variant = preset.get("tile", [0, 0])
				if typeof(tile_data) == TYPE_ARRAY and tile_data.size() >= 2:
					preset["tile"] = [int(tile_data[0]), int(tile_data[1])]

	# external_wall（可选，无则不实例化）
	var walls: Variant = map_data.get("external_wall", map_data.get("external_walls", []))  # 单数优先，复数兼容
	if typeof(walls) == TYPE_ARRAY:
		level.external_walls = walls.duplicate(true)
		for wall in level.external_walls:
			if typeof(wall) == TYPE_DICTIONARY:
				wall["X"] = int(wall.get("X", 0))  # JSON 数字是 float，规范化回 int
				wall["Y"] = int(wall.get("Y", 0))

	# exit（可选，无则不实例化）
	var exit_data: Variant = map_data.get("exit", {})
	if typeof(exit_data) == TYPE_DICTIONARY and not exit_data.is_empty():
		level.exit = exit_data.duplicate(true)
		# X/Y 保留浮点（JSON 数字是 float，世界坐标允许小数，如 1.5 格）

	# items（可选，与 map 同级，无则不实例化）
	var items_data: Variant = d.get("item", d.get("items", []))  # 单数优先，复数兼容
	if typeof(items_data) == TYPE_ARRAY:
		level.items = items_data.duplicate(true)

	# characters（可选，与 map、items 同级，无则不实例化）
	var chars_data: Variant = d.get("character", d.get("characters", []))  # 单数优先，复数兼容
	if typeof(chars_data) == TYPE_ARRAY:
		level.characters = chars_data.duplicate(true)
		# X/Y 保留浮点（与 exit/items 一致，世界坐标允许小数，如 1.5 格）
	
	# events （可选，与 map、items、characters 同级，不实例化，只读）
	var events_data: Variant = d.get("event", d.get("events", []))  # 单数优先，复数兼容
	if typeof(events_data) == TYPE_ARRAY:
		level.events = events_data.duplicate(true)
	
	return level
