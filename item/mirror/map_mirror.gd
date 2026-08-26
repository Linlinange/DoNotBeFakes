class_name MapMirror
extends Area2D

enum State { INACTIVED, ACTIVED }
enum Axis { X, Y }

signal state_changed(new_state: State)
signal activated
@warning_ignore("unused_signal") signal deactivated


@onready var control_target: Node2D = self
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effect_area: Area2D = $EffectArea
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var interact_comp: InteractComponent = $InteractComponent

## 镜子当前的状态
@export var current_state: State = State.INACTIVED
## >=0 则 N 秒后自动关闭，-1表示无限
@export var effect_duration: float = -1.0
## 映射的轴: 轴为X时，映射后y坐标关于镜子的X轴翻转；轴为Y时，映射后坐标关于x坐标关于镜子Y轴翻转
@export var axis: Axis = Axis.X
## 可映射的节点
@export var nodes_tomap: Array[Node2D] = []
## 控制映射的玩家节点：为true时控制映射节点而不控制本体，否则控制本体而不控制节点
@export var control_mapped: bool = false

## 最大交互次数，-1 表示无限
@export var max_interact_times: int = -1:
	set(value):
		max_interact_times = value
		if interact_comp:
			interact_comp.max_interact_times = value
## 提示内容
@export var tooltip_content: String = "按F切换控制对象":
	set(value):
		tooltip_content = value
		if interact_comp:
			interact_comp.tooltip_content = value
## 提示偏移
@export var tooltip_offset: Vector2 = Vector2(0, -32):
	set(value):
		tooltip_offset = value
		if interact_comp:
			interact_comp.tooltip_offset = value


var nodes_mapped: Array[Node2D] = []	## 已被映射的节点
var is_transitioning: bool = false		## 是否正在切换状态: 为true时, 拒绝交互

var _timer: Timer


func _ready():
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_deactivate)
	add_child(_timer)
	_update_visual()

	interact_comp.interacted.connect(interact)
	interact_comp.max_interact_times = self.max_interact_times
	interact_comp.tooltip_content = self.tooltip_content
	interact_comp.tooltip_offset = self.tooltip_offset
	
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


# ========== 公共接口 ==========

## 对节点进行特殊处理:
## ex_children为true时, 将会递归处理此节点及其所有子节点
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

## 检查镜子是否激活
func is_actived() -> bool:
	return current_state == State.ACTIVED

## 获取状态
func get_state() -> State:
	return current_state

## 获取状态名
func get_state_name() -> String:
	if current_state == State.ACTIVED:
		return "ACTIVED"
	else:
		return "INACTIVED"

## 交互: 切换镜子状态并切换控制对象
func interact():
	if is_transitioning:
		return
	
	audio.pitch_scale = randf_range(2.1, 2.4)
	audio.play()
	is_transitioning = true
	interact_comp.set_interactable(false)

	match current_state:
		State.INACTIVED:
			sprite.play("active")
			await sprite.animation_finished
			_activate()
		State.ACTIVED:
			sprite.play("inactive")
			await sprite.animation_finished
			_deactivate()
	
	is_transitioning = false
	interact_comp.set_interactable(true)

## 获取交互次数
func get_interact_times() -> int:
	if interact_comp:
		return interact_comp.get_interact_times()
	else:
		return -1

# ========== 私有方法 ==========

func _activate():
	current_state = State.ACTIVED
	activated.emit()
	state_changed.emit(current_state)
	
	if effect_duration >= 0:
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
