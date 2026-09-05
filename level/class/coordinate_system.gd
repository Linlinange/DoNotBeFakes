class_name CoordinateSystem
## 坐标系系统（静态工具类）
##
## 约定：
##   - 二维游戏 Y 正方向向下（Godot 屏幕坐标）。
##   - 关卡数据一律用【格子坐标】Vector2i（整数），渲染时才转像素。
##   - 每格 = 每瓦片 = cell_size 像素（单元坐标宽度兼瓦片宽度）。
##   - 换算 / 朝向公式只写在这里，别处不允许出现 `* 32` 这类魔法数字。

## 默认格子像素尺寸，可被 LevelData 里每个关卡的 cell_size 覆盖。
const DEFAULT_CELL_SIZE := Vector2(32, 32)

# 方向（Y 向下：N=上，S=下，W=左，E=右）
const DIR_N := Vector2i(0, -1)
const DIR_S := Vector2i(0, 1)
const DIR_W := Vector2i(-1, 0)
const DIR_E := Vector2i(1, 0)

## 朝向字符串 -> 方向向量（N/S/W/E，未知值按 E 处理并警告）
static func facing_to_dir(facing: String) -> Vector2i:
	match facing:
		"N": return DIR_N
		"S": return DIR_S
		"W": return DIR_W
		"E": return DIR_E
		_:
			push_warning("CoordinateSystem: 未知朝向 '%s'，按 E 处理" % facing)
			return DIR_E

## 朝向字符串 -> 旋转角（度）。Godot 顺时针为正，故 N=-90（逆时针朝上）。
static func facing_to_rotation(facing: String) -> float:
	match facing:
		"N": return -90.0
		"S": return 90.0
		"W": return 180.0
		"E": return 0.0
		_:
			push_warning("CoordinateSystem: 未知朝向 '%s'，按 E 处理" % facing)
			return 0.0

## 两个外墙节点是否"相邻且同行或同列"（外墙连通判定用）
static func is_adjacent_in_line(a: Vector2i, b: Vector2i) -> bool:
	var d := (b - a).abs()
	return d == Vector2i(1, 0) or d == Vector2i(0, 1)

## 格子坐标 -> 世界像素坐标（格子左上角）
static func coord_to_world(coord: Vector2i, cell_size: Vector2 = DEFAULT_CELL_SIZE) -> Vector2:
	return Vector2(coord) * cell_size

## 世界像素坐标 -> 格子坐标（向下取整）
static func world_to_coord(world: Vector2, cell_size: Vector2 = DEFAULT_CELL_SIZE) -> Vector2i:
	return Vector2i((world / cell_size).floor())

## 格子中心像素坐标（放精灵、做检测用）
static func coord_to_world_center(coord: Vector2i, cell_size: Vector2 = DEFAULT_CELL_SIZE) -> Vector2:
	return coord_to_world(coord, cell_size) + cell_size * 0.5

## 坐标 key："x,y" <-> Vector2i
static func to_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

static func from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		push_warning("CoordinateSystem: 非法坐标 key %s" % key)
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
