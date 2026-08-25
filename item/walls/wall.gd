class_name FakableWall
extends FakableObject

@onready var visuals = $Visuals
@onready var top_l = $Visuals/TL
@onready var top = $Visuals/Top
@onready var top_r = $Visuals/TR
@onready var left = $Visuals/Left
@onready var center = $Visuals/Center
@onready var right = $Visuals/Right
@onready var bottom_l = $Visuals/BL
@onready var bottom = $Visuals/Bottom
@onready var bottom_r = $Visuals/BR
@onready var collision_shape = $CollisionShape2D
@onready var normal_collision_layer = collision_layer

## 尺寸: 墙体的宽度和长度
@export var size: Vector2 = Vector2(48, 48):
	set(v):
		var min_v = Vector2(16, 16)
		var target = v.max(min_v)
		size = target
		
		if not is_node_ready():
			_display_size = target
			return
		
		_start_size_tween(target)


# ========== 动画参数 ==========
@export_group("动画参数")
@export var tween_duration: float = 0.3
@export var tween_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var tween_ease: Tween.EaseType = Tween.EASE_OUT

## 伸缩的锚点: 例如(0, 0) = 左上固定，向右下扩展；
## (0.5, 0.5) = 中心固定，双向对称扩展（默认）；
## (1, 1) = 右下固定，向左上扩展；
@export var anchor: Vector2 = Vector2(0.5, 0.5)

## fake为真时 Atlas 纹理相对于正常纹理的 x 偏移（像素）
@export var fake_offset_x: float = 80.0

# ========== 内部状态 ==========
var _tween: Tween

var _display_size: Vector2 = Vector2(48, 48):
	set(v):
		_display_size = v
		if is_node_ready():
			update_table()

# 缓存：节点名 → 正常状态的 region.x
var _normal_regions: Dictionary = {}

func _ready() -> void:
	if collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	_display_size = size
	update_table()
	
	# 记录每个 Sprite2D 当前 region.x（即正常状态的 x）
	for child in visuals.get_children():
		if child is Sprite2D and child.texture is AtlasTexture:
			_normal_regions[child.name] = child.texture.region
	
	super._ready()


func _start_size_tween(target: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_trans(tween_trans)
	_tween.set_ease(tween_ease)
	
	_tween.tween_property(self, "_display_size:x", target.x, tween_duration)
	_tween.parallel().tween_property(self, "_display_size:y", target.y, tween_duration)


## 更新尺寸
func update_table() -> void:
	if not is_node_ready():
		return
	
	var w = _display_size.x
	var h = _display_size.y
	var cw = top_l.texture.get_width()
	var ch = top_l.texture.get_height()
	var mid_w = w - cw * 2
	var mid_h = h - ch * 2
	
	# --- 四角 ---
	_set_piece(top_l,    Vector2(0,   0),   Vector2( cw/2,  ch/2))
	_set_piece(top_r,    Vector2(1,   0),   Vector2(-cw/2,  ch/2))
	_set_piece(bottom_l, Vector2(0,   1),   Vector2( cw/2, -ch/2))
	_set_piece(bottom_r, Vector2(1,   1),   Vector2(-cw/2, -ch/2))
	
	top_l.scale = Vector2.ONE
	top_r.scale = Vector2.ONE
	bottom_l.scale = Vector2.ONE
	bottom_r.scale = Vector2.ONE
	
	# --- 四边 ---
	_set_piece(top,      Vector2(0.5, 0),   Vector2( 0,   ch/2))
	_set_piece(bottom,   Vector2(0.5, 1),   Vector2( 0,  -ch/2))
	_set_piece(left,     Vector2(0,   0.5), Vector2( cw/2,  0))
	_set_piece(right,    Vector2(1,   0.5), Vector2(-cw/2,  0))
	
	top.scale    = Vector2(mid_w / top.texture.get_width(), 1)
	bottom.scale = Vector2(mid_w / bottom.texture.get_width(), 1)
	left.scale   = Vector2(1, mid_h / left.texture.get_height())
	right.scale  = Vector2(1, mid_h / right.texture.get_height())
	
	# --- 中心 ---
	_set_piece(center,   Vector2(0.5, 0.5), Vector2.ZERO)
	center.scale = Vector2(
		mid_w / center.texture.get_width(),
		mid_h / center.texture.get_height()
	)
	
	# --- 碰撞箱同步 ---
	var shape = collision_shape.shape as RectangleShape2D
	if shape:
		shape.size = _display_size
		# 碰撞箱中心要跟着锚点走
		collision_shape.position = Vector2(
			(0.5 - anchor.x) * w,
			(0.5 - anchor.y) * h
		)

# 通用定位：norm 是 0~1 网格位置，offset 是纹理中心微调
func _set_piece(node: Sprite2D, norm: Vector2, offset: Vector2) -> void:
	node.position = Vector2(
		(norm.x - anchor.x) * _display_size.x + offset.x,
		(norm.y - anchor.y) * _display_size.y + offset.y
	)


# 方法覆写，此方法继承自 FakableObject
func _on_fake_updated() -> void:
	for child in visuals.get_children():
		if not child is Sprite2D:
			continue
		if not child.texture is AtlasTexture:
			continue
		
		# 修改 region，触发重绘
		var atlas: AtlasTexture = child.texture
		var base: Rect2 = _normal_regions.get(child.name, Rect2())
		
		if fake:
			atlas.region = Rect2(
				base.position.x + fake_offset_x,
				base.position.y,
				base.size.x,
				base.size.y
			)
			collision_layer = fake_collision_layer
		else:
			atlas.region = base
			collision_layer = normal_collision_layer
