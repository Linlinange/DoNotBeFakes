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
var cell_size := Vector2i(32, 32)  # 必要：每格像素宽高（瓦片统一 32px）
var floor_rect := Rect2i()         # 可选：X,Y,W,H（瓦片）
var floor_seed := -1               # 可选：-1 随机，其他值固定（对应 floor 的 seed）
var external_walls: Array = []     # 可选：[{X,Y,dirs:{N,S,W,E}}]
var exit := {}                     # 可选：{X, Y, facing, next_scene?}

# ---------- 便捷判断 ----------
func has_floor() -> bool:
	return floor_rect.size.x > 0 and floor_rect.size.y > 0

func has_exit() -> bool:
	return not exit.is_empty()

## 坐标是否在地板区域内（无地板则为 false）
func is_inside_floor(coord: Vector2i) -> bool:
	return has_floor() and floor_rect.has_point(coord)

# ---------- 坐标便捷方法（转发给 CoordinateSystem，公式只此一份） ----------
func coord_to_world(coord: Vector2i) -> Vector2:
	return CoordinateSystem.coord_to_world(coord, Vector2(cell_size))

## 格子中心像素坐标（放实体 / 出口用）
func coord_to_world_center(coord: Vector2i) -> Vector2:
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
		d["map"]["floor"] = floor_dict
	if not external_walls.is_empty():
		d["map"]["external_wall"] = external_walls.duplicate(true)
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

	# external_wall（可选，无则不实例化）
	var walls: Variant = map_data.get("external_wall", [])
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
		level.exit["X"] = int(level.exit.get("X", 0))  # JSON 数字是 float，规范化回 int
		level.exit["Y"] = int(level.exit.get("Y", 0))

	return level
