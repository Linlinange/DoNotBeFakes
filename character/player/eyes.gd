extends AnimatedSprite2D
## 眼睛能偏离中心的最大距离（像素）
@export var max_radius: float = 5.0
## 平滑系数: 越大跟得越紧；填 0 或不填则瞬间到位
@export var smooth_speed: float = 12.0
## 眼睛向心率: 值越大，越靠近中心。
@export var centripetal: float = 64.0
## 眼睛看向的地方: 若为二维向量，则看向其表示的坐标; 若为节点，则看向节点; 若为null(空)，则看向鼠标
@export var follow: Variant = null

## 记录编辑器里摆好的初始位置，作为"眼眶中心"
var base_position: Vector2

func _ready() -> void:
	base_position = position

func _process(delta: float) -> void:
	
	# 把全局坐标转成父节点（face）的局部坐标
	var local: Vector2
	if follow is Vector2:
		local = get_parent().to_local(follow)
	elif follow is Node2D:
		local = get_parent().to_local(follow.global_position)
	else:
		local = get_parent().to_local(get_global_mouse_position())
	
	# 从 base_position 指向鼠标，限制长度不超过 max_radius
	var off_set = ((local - base_position)/centripetal).limit_length(max_radius)
	var target = base_position + off_set
	
	# 平滑 or 硬切
	if smooth_speed > 0:
		position = position.lerp(target, smooth_speed * delta)
	else:
		position = target
