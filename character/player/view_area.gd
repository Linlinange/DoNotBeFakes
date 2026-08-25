extends Area2D

# ========== 扇形几何 ==========
## 母线长 / 半径（像素）
@export var radius: float = 64.0
## 扇形张角（度），1 ~ 360
@export var angle_deg: float = 90.0
## 弧边分段数，越多越圆滑（建议 16~64）
@export var segments: int = 32

# ========== 外观 ==========
@export var fill_color: Color = Color(0.2, 0.7, 1.0, 0.25)
@export var stroke_color: Color = Color(0.2, 0.7, 1.0, 0.7)
@export var stroke_width: float = 1.0

# ========== 跟随目标 ==========
## 自动找 eyes；如果节点结构不同，在 Inspector 里改这个路径
@export var eyes_path: NodePath = ".."

@onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D

var eyes: Node2D

# 缓存，用来检测参数是否被修改
var _last_radius: float
var _last_angle: float
var _last_segments: int

# 当前正在运行的 Tweens（按属性名存储，同名属性会打断旧动画）
var _active_tweens: Dictionary = {}


func _ready() -> void:
	if not eyes_path.is_empty():
		eyes = get_node_or_null(eyes_path)
	
	# 初始化
	_update_polygon()


func _process(_delta: float) -> void:
	# 1. 位置 & 旋转同步
	if eyes:
		global_position = eyes.global_position
		look_at(get_global_mouse_position())
	
	# 2. 参数变化时重建碰撞和图形
	if radius != _last_radius or angle_deg != _last_angle or segments != _last_segments:
		_update_polygon()
	
	# 3. 标记重绘（_draw 只在需要时执行，不耗性能）
	queue_redraw()


# ========== 属性过渡动画 ==========
## 将指定数值属性从当前值（或指定起始值）平滑过渡到目标值
## 
## 用法示例：
##   tween_property("radius", 64.0, 128.0, 0.5)           # 半径 0.5秒扩大到128
##   tween_property("angle_deg", 90.0, 180.0, 0.3)        # 张角 0.3秒展开到180度
##   tween_property("radius", 32.0, 96.0, 1.0, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
##
## @param property   要动画的属性名（"radius" / "angle_deg" / "segments"）
## @param from       起始值（若为 -1 则使用当前值）
## @param to         目标值
## @param duration   动画时长（秒）
## @param trans      过渡类型（默认线性）
## @param ease_type  缓动类型（默认 InOut）
## @param on_finish  动画结束时的可选回调（Callable）
func tween_property(
	property: String,
	from: float,
	to: float,
	duration: float,
	trans: int = Tween.TRANS_LINEAR,
	ease_type: int = Tween.EASE_IN_OUT,
	on_finish: Callable = Callable()
) -> Tween:
	# 如果该属性已有动画在跑，先杀掉
	if _active_tweens.has(property) and _active_tweens[property] != null:
		_active_tweens[property].kill()
	
	var tween := create_tween()
	tween.set_trans(trans)
	tween.set_ease(ease_type)
	
	# 确定起始值
	var start_val: float = from if from >= 0 else get(property)
	
	# 立即设置起始值（避免从错误值开始）
	set(property, start_val)
	_update_polygon()
	
	tween.tween_property(self, property, to, duration)
	
	# 动画结束清理 + 可选回调
	tween.finished.connect(func():
		_active_tweens.erase(property)
		if on_finish.is_valid():
			on_finish.call()
	, CONNECT_ONE_SHOT)
	
	_active_tweens[property] = tween
	return tween

## 快捷方法：同时动画化多个属性
## 示例：tween_multiple([["radius", 64, 128, 0.5], ["angle_deg", 90, 45, 0.3]])
func tween_multiple(tweens_data: Array) -> void:
	for data in tweens_data:
		# 数据格式: [property, from, to, duration, trans, ease, callback]
		# 后三项可选
		var p: String = data[0]
		var f: float   = data[1]
		var t: float   = data[2]
		var d: float   = data[3]
		var _tr: int    = data[4] if data.size() > 4 else Tween.TRANS_LINEAR
		var e: int     = data[5] if data.size() > 5 else Tween.EASE_IN_OUT
		var cb: Callable = data[6] if data.size() > 6 else Callable()
		tween_property(p, f, t, d, _tr, e, cb)

## 停止指定属性的动画（立即停止，保留当前值）
func stop_tween(property: String) -> void:
	if _active_tweens.has(property) and _active_tweens[property] != null:
		_active_tweens[property].kill()
		_active_tweens.erase(property)

## 停止所有属性动画
func stop_all_tweens() -> void:
	for tween in _active_tweens.values():
		if tween != null:
			tween.kill()
	_active_tweens.clear()


# ========== 构建扇形顶点 ==========
func _build_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)  # 圆心
	
	var half_rad := deg_to_rad(angle_deg) / 2.0
	var step := deg_to_rad(angle_deg) / maxi(segments, 3)
	
	for i in range(segments + 1):
		var theta := -half_rad + step * i
		pts.append(Vector2(cos(theta) * radius, sin(theta) * radius))
	
	return pts


func _update_polygon() -> void:
	_last_radius = radius
	_last_angle = angle_deg
	_last_segments = segments
	
	if collision_poly:
		collision_poly.polygon = _build_points()


# ========== 渲染 ==========
func _draw() -> void:
	var pts := _build_points()
	
	# 填充扇形
	if fill_color.a > 0:
		draw_colored_polygon(pts, fill_color)
	
	# 描边（圆心→弧→圆心）
	if stroke_width > 0 and stroke_color.a > 0:
		var outline := PackedVector2Array(pts)
		outline.append(Vector2.ZERO)
		draw_polyline(outline, stroke_color, stroke_width, true)
