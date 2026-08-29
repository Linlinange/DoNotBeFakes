class_name Player
extends CharacterBody2D

const _OFF = Vector2(0, -32)
const _W = 10.0
const _H = 12.0
const _FILL = Color("ffdd1170")
const _LINE = Color("ffdd11b3")
const _LW = 1

@onready var eyes: AnimatedSprite2D = $sprite/eyes
@onready var face: AnimatedSprite2D = $sprite/face
@onready var view_area: Area2D = $sprite/eyes/view_area
@onready var v_contorler: Node = $ScreenTouchContorl

@export var speed: float = 180.0
@export var eyes_open: bool = true
@export var eyes_activity: bool = true
## 能否控制: 为false时，既无法进行移动，也无法进行交互; 赋值为false时具有副作用，会强制同步移动与交互的状态
@export var control: bool = true:
	set(value):
		control = value
		if value == false:
			movable = false
			interactable = false
		queue_redraw()
## 能否移动: 为false时，无法进行移动，移动设备也不会显示移动摇杆
@export var movable: bool = true:
	set(value):
		movable = value
		if value == true:
			control = true
## 能否交互: 为false时，无法进行交互，移动设备也不会显示交互按钮
@export var interactable: bool = true:
	set(value):
		interactable = value
		if value == true:
			control = true
@export var view_radius: float = 128.0
@export var view_angle: float = 45.0

var facing: String = "down"

# === 暴露给外界的信号 ===
signal view_body_entered(body: Node2D)
signal view_body_exited(body: Node2D)
signal view_area_entered(area: Area2D)
signal view_area_exited(area: Area2D)


func _ready() -> void:
	# 移动端时，显示触屏控件
	if OS.has_feature("mobile"):
		v_contorler.visible = true
	else:
		v_contorler.visible = false
	
	if not eyes_activity:
		eyes.set_process(false)
	view_area.radius = view_radius
	view_area.angle_deg = view_angle
	# 将子节点 Area2D 的信号冒泡到父节点
	view_area.body_entered.connect(_on_view_body_entered)
	view_area.body_exited.connect(_on_view_body_exited)
	view_area.area_entered.connect(_on_view_area_entered)
	view_area.area_exited.connect(_on_view_area_exited)
	
	_update_eyes()


func _physics_process(_delta: float) -> void:
	var direction := _get_input()
	if movable:
		
		# 更新朝向并移动
		if direction.length() > 0.1:
			facing = _get_facing(direction)
		velocity = direction * speed
		move_and_slide()
		
	_update_animation(direction)	# 更新动画


func _process(_delta: float) -> void:
	if movable:
		v_contorler.v_joystick.visible = true
	else:
		v_contorler.v_joystick.visible = false
	
	if interactable:
		v_contorler.v_interact.visible = true
	else:
		v_contorler.v_interact.visible = false
	
	var m_left = Input.is_action_just_pressed("switch")
	if eyes_activity and m_left:
		match eyes_open:
			true:
				eyes.play("close")
				view_area.tween_property("angle_deg", -1, 0.0, 1.0/6.0)
			false:
				eyes.play("open")
		await eyes.animation_finished
		eyes_open = !eyes_open
		_update_eyes()


func _draw():
	if movable:
		# 目标在当前节点本地坐标系中的位置
		
		var tip   = _OFF + Vector2(0, _H * 0.6)
		var left  = _OFF + Vector2(-_W, -_H * 0.4)
		var right = _OFF + Vector2( _W, -_H * 0.4)
		
		var poly = PackedVector2Array([left, right, tip])
		draw_colored_polygon(poly, _FILL)
		
		var stroke := PackedVector2Array([left, right, tip, left])
		draw_polyline(stroke, _LINE, _LW, true)


# ========== 公共方法 ==========

func get_view_overlapping_bodies() -> Array[Node2D]:
	return view_area.get_overlapping_bodies()

func get_view_overlapping_areas() -> Array[Area2D]:
	return view_area.get_overlapping_areas()

func is_body_in_view(body: Node2D) -> bool:
	return view_area.overlaps_body(body)

func is_area_in_view(area: Area2D) -> bool:
	return view_area.overlaps_area(area)

func set_view_enabled(enabled: bool) -> void:
	view_area.monitoring = enabled
	view_area.monitorable = enabled


# ========== 私有方法 ==========

func _on_view_body_entered(body: Node2D) -> void:
	view_body_entered.emit(body)

func _on_view_body_exited(body: Node2D) -> void:
	view_body_exited.emit(body)

func _on_view_area_entered(area: Area2D) -> void:
	view_area_entered.emit(area)

func _on_view_area_exited(area: Area2D) -> void:
	view_area_exited.emit(area)

# 输入
func _get_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

# 8向计算
func _get_facing(dir: Vector2) -> String:
	var angle := dir.angle()
	var octant := int(round(angle / (PI / 4)))
	if octant < 0:
		octant += 8
	
	var directions := [
		"right", "down_right", "down", "down_left",
		"left", "up_left", "up", "up_right"
	]
	return directions[octant]

# 动画更新
@warning_ignore("unused_parameter")
func _update_animation(direction: Vector2) -> void:
	pass

func _update_eyes() -> void:
	if eyes_open:
		eyes.play("opened")
		view_area.visible = true
		view_area.tween_property("angle_deg", -1, view_angle, 1.0/6.0)
		view_area.collision_layer |= 0b11 # 二进制运算：将一二位置一
		view_area.collision_mask |= 0b11
	else:
		eyes.play("closed")
		view_area.visible = false
		view_area.collision_layer &= ~0b11 # 二进制运算：将一二位置零
		view_area.collision_mask &= ~0b11


## 追踪触屏的手指
var _touch_id: int = -1
func _unhandled_input(event: InputEvent) -> void:
	var follow: Variant
	# 触屏点击/释放
	if event is InputEventScreenTouch:
		if _touch_id == -1 and event.pressed:
			_touch_id = event.index
			follow = get_viewport().get_canvas_transform().affine_inverse() * event.position
			eyes.follow = follow
			view_area.follow = follow
			# print(follow)
		elif _touch_id != -1 and not event.pressed:
			_touch_id = -1

	# 触屏拖动
	if event is InputEventScreenDrag:
		if _touch_id == event.index:
			follow = get_viewport().get_canvas_transform().affine_inverse() * event.position
			eyes.follow = follow
			view_area.follow = follow
			# print(follow)
