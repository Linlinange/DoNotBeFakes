extends Area2D

enum State { INACTIVED, ACTIVED }
enum Axis { X, Y }

const _OFF = Vector2(0, -32)
const _W = 10.0
const _H = 12.0
const _FILL = Color("fff170ff")
const _LINE = Color("ad7013ff")
const _LW = 1

## 镜子当前的状态
@export var current_state: State = State.INACTIVED
## true=交互一定次数后永久保持，无法切换
@export var disposable: bool = false
## >0 则 N 秒后自动关闭，0=无限
@export var effect_duration: float = 0.0 
## 映射的轴: 轴为X时，映射后y坐标关于镜子的X轴翻转；轴为Y时，映射后坐标关于x坐标关于镜子Y轴翻转
@export var axis: Axis = Axis.X
## 可映射的节点
@export var nodes_tomap: Array[Node2D] = []
## 控制映射的玩家节点：为true时控制映射节点而不控制本体，否则控制本体而不控制节点
@export var control_mapped: bool = false
## 被靠近时会显示的提示
@export var tooltip_content: String = "按F交互"
## 提示的坐标偏移
@export var tooltip_offset: Vector2 = Vector2(0, 0)

@onready var control_target: Node2D = self
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effect_area: Area2D = $EffectArea
@onready var tooltip: Label = $CanvasLayer/tooltip
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var player_in_range: bool = false

var nodes_mapped: Array[Node2D] = []

var is_transitioning: bool = false   # 正在播放切换动画，拒绝交互 

var _timer: Timer
var _interact_times: int = 0 # 交互次数 

signal state_changed(new_state: State)
signal activated
@warning_ignore("unused_signal")
signal deactivated


func _ready():
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_deactivate)
	tooltip.text = tooltip_content
	tooltip.visible = false
	tooltip.position = self.global_position*2 + Vector2(-64, 32) + tooltip_offset
	add_child(_timer)
	_update_visual()
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	
	# 创建映射节点
	for node in nodes_tomap:
		var mapped = node.duplicate()
		nodes_mapped.append(mapped)
		get_tree().current_scene.add_child.call_deferred(mapped)
		make_reflection(mapped, axis, 0.5)
		mapped.global_position = node.global_position
		if axis == Axis.Y:
			mapped.global_position.x = 2*self.global_position.x - node.global_position.x
		else:
			mapped.global_position.y = 2*self.global_position.y - node.global_position.y
		if node.is_in_group("player"):
			control_target = node
		

@warning_ignore("unused_parameter")
func _process(delta: float):
	if control_target:
		queue_redraw()
	if player_in_range:
		tooltip.visible = true
		if Input.is_action_just_pressed("interact"):
			interact()
	else:
		tooltip.visible = false
	
	for i in len(nodes_mapped):
		var node = nodes_tomap[i]
		var mapped = nodes_mapped[i]
		if node.is_in_group("player") and control_mapped:
			node.global_position = mapped.global_position
			if axis == Axis.Y:
				node.global_position.x = 2*self.global_position.x - mapped.global_position.x
			else:
				node.global_position.y = 2*self.global_position.y - mapped.global_position.y
		else:
			mapped.global_position = node.global_position
			if axis == Axis.Y:
				mapped.global_position.x = 2*self.global_position.x - node.global_position.x
			else:
				mapped.global_position.y = 2*self.global_position.y - node.global_position.y
			

func _draw():
	if not control_target:
		return
	
	# 目标在当前节点本地坐标系中的位置
	var base = to_local(control_target.global_position)
	
	var tip   = base + _OFF + Vector2(0, _H * 0.6)
	var left  = base + _OFF + Vector2(-_W, -_H * 0.4)
	var right = base + _OFF + Vector2( _W, -_H * 0.4)
	
	var poly = PackedVector2Array([left, right, tip])
	draw_colored_polygon(poly, _FILL)
	
	var stroke := PackedVector2Array([left, right, tip, left])
	draw_polyline(stroke, _LINE, _LW, true)


func interact():
	"""外界调用：切换镜子状态"""
	if is_transitioning:
		return
	if disposable and _interact_times >= 1:
		return
	else:
		_interact_times += 1
	
	match current_state:
		State.INACTIVED:
			sprite.play("active")
			await sprite.animation_finished
			_activate()
		State.ACTIVED:
			sprite.play("inactive")
			await sprite.animation_finished
			_deactivate()
	audio.pitch_scale = randf_range(2.1, 2.4)
	audio.play()


func _activate():
	current_state = State.ACTIVED
	activated.emit()
	state_changed.emit(current_state)
	
	if effect_duration > 0:
		_timer.start(effect_duration)
	
	# 映射节点控制
	control_mapped = true
	for i in len(nodes_mapped):
		var node = nodes_tomap[i]
		var mapped = nodes_mapped[i]
		if node is Player:
			node.control = false
			mapped.control = true
			control_target = mapped
			var camera = node.get_node_or_null("Camera2D")
			if camera:
				camera.reparent(mapped)
		#mapped.queue_free()
	#nodes_mapped.clear()

	_update_visual()


func _deactivate():
	current_state = State.INACTIVED
	state_changed.emit(current_state)
	
	# 映射节点控制
	control_mapped = false
	for i in len(nodes_mapped):
		var node = nodes_tomap[i]
		var mapped = nodes_mapped[i]
		if node is Player:
			node.control = true
			mapped.control = false
			control_target = node
			var camera = mapped.get_node_or_null("Camera2D")
			if camera:
				camera.reparent(node)
		#mapped.queue_free()
	#nodes_mapped.clear()
	
	_timer.stop()
	_update_visual()


func _update_visual():
	match current_state:
		State.INACTIVED:
			sprite.play("inactived")
		State.ACTIVED:
			sprite.play("actived")

# ========== 公共接口 ==========

## 递归处理一个节点及其所有子节点
@warning_ignore("shadowed_variable")
func make_reflection(node: Node, axis: int, alpha: float = 0.5, ex_children: bool = false, tint: Color = Color.WHITE) -> void:
	## 1. 关碰撞
	#print(node)
	if node is Player:
		node.set_physics_process(false)
	#node.set_process_input(false)
	#node.set_process_unhandled_input(false)
	#node.set_process_shortcut_input(false)
	#node.set_process_unhandled_key_input(false)
	if node is CollisionObject2D:
		node.collision_layer = 0b10
		node.collision_mask = 0b10
	if node is Area2D:
		node.monitoring = false
		node.monitorable = false
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", true)
	
	## 2. 半透明
	if node is CanvasItem:
		var c = tint
		c.a = alpha
		node.modulate = c
	
	## 3. 翻转
	if node is Sprite2D or node is AnimatedSprite2D:
		if axis == Axis.Y:
			node.scale.x *= -1
		else:
			node.scale.y *= -1
	
	## 递归
	if not ex_children:
		return
	for child in node.get_children():
		make_reflection(child, axis, alpha)

func is_actived() -> bool:
	"""检查镜子是否激活"""
	return current_state == State.ACTIVED

func get_state() -> State:
	"""获取状态"""
	return current_state

func get_state_name() -> String:
	"""获取状态名"""
	if current_state == State.ACTIVED:
		return "ACTIVED"
	else:
		return "INACTIVED"


# ========== 交互检测 ==========

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
