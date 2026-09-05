class_name MapMirror
extends Area2D

enum State { INACTIVED, ACTIVED }
enum Axis { X, Y }

signal activated
signal deactivated

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effect_area: Area2D = $EffectArea
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var interact_comp: InteractComponent = $InteractComponent

## 镜子当前的状态
@export var current_state: State = State.INACTIVED
## 映射的轴: 轴为X时，映射后坐标关于镜子的水平轴翻转；轴为Y时，映射后坐标关于镜子垂直轴翻转
@export var axis: Axis = Axis.X
## 可映射的节点
@export var nodes_tomap: Array[Node2D] = []

## 最大交互次数，-1 表示无限
@export var max_interact_times: int = -1:
	set(value):
		max_interact_times = value
		if interact_comp:
			interact_comp.max_interact_times = value
## 提示内容
@export var tooltip_content: String = "按%s切换控制对象" % InputManager.get_key_name("interact"):
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


var nodes_mapped: Dictionary[Node2D, Node2D] = {}	## 已映射的节点: 键为原始节点，值为映射节点
var is_transitioning: bool = false		## 是否正在切换状态: 为true时, 拒绝交互
var last_positions: Dictionary = {}  # Node -> Vector2


# ========== 继承方法 ==========

func _ready():
	_update_visual()
	interact_comp.interacted.connect(interact)
	interact_comp.max_interact_times = self.max_interact_times
	interact_comp.tooltip_content = self.tooltip_content
	interact_comp.tooltip_offset = self.tooltip_offset
	
	# 排除特殊元素，并创建映射节点
	for tomap in nodes_tomap:
		if tomap == null:
			push_warning("不允许映射空元素，已跳过:%s" % tomap)
			continue
		if tomap is MapMirror:
			push_warning("不允许映射映射镜，已跳过:%s" % tomap)
			continue
		if tomap in nodes_mapped:
			push_warning("不允许重复映射，已跳过:%s" % tomap)
			continue
		
		# 节点复制
		var mapped: Node
		if tomap is FakableObject:
			mapped = SceneManager.copy(tomap)
		elif tomap is ButtonController:
			mapped = SceneManager.copy(tomap)
		else:
			mapped = tomap.duplicate()

		# 复制失败过滤
		if mapped == null:
			push_warning("无法重复节点，已跳过:%s" % mapped)
			continue
		
		# 通用节点设置
		nodes_mapped[tomap] = mapped
		get_tree().current_scene.add_child.call_deferred(mapped)
		mapped.global_position = tomap.global_position
		if axis == Axis.Y:
			mapped.global_position.x = 2*self.global_position.x - tomap.global_position.x
		else:
			mapped.global_position.y = 2*self.global_position.y - tomap.global_position.y
		
		# 特殊节点设置
		if tomap is Player:
			mapped.movable = false
			make_reflection(mapped, axis, 0.5)
		elif tomap is FakableObject:
			mapped.set_fake(!mapped.fake)
		else:
			make_reflection(mapped, axis, 0.5)


@warning_ignore("unused_parameter")
func _process(delta: float):
	for tomap in nodes_mapped.keys():
		var mapped = nodes_mapped[tomap]
		var t_moved = last_positions.has(tomap) and tomap.global_position != last_positions[tomap]
		var m_moved = last_positions.has(mapped) and mapped.global_position != last_positions[mapped]

		var source  = tomap if (t_moved or not m_moved) else mapped	## 源对象
		var target  = mapped if (t_moved or not m_moved) else tomap	## 映射目标(映射后的对象)

		# 映射坐标关于镜子对称轴翻转
		target.global_position = source.global_position
		if axis == Axis.Y:
			target.global_position.x = 2 * self.global_position.x - source.global_position.x
		else:
			target.global_position.y = 2 * self.global_position.y - source.global_position.y

		last_positions[tomap]   = tomap.global_position
		last_positions[mapped]  = mapped.global_position

		if tomap is Player:
			if tomap.movable == mapped.movable and tomap.movable == false:
				tooltip_content = "假副本只能通过\n所属映射镜切换对象"
				interact_comp.set_interactable(false)
			else:
				tooltip_content = "按%s切换控制对象" % InputManager.get_key_name("interact")
				interact_comp.set_interactable(true)


# ========== 公共方法 ==========

## 对节点进行特殊处理:
## ex_children为true时, 将会递归处理此节点及其所有子节点
@warning_ignore("shadowed_variable")
func make_reflection(node: Node, axis: int, alpha: float = 0.5, ex_children: bool = false, tint: Color = Color.WHITE) -> void:
	# 移除多余的摄影机
	var camera = node.get_node_or_null("Camera2D")
	if camera:
		node.remove_child(camera)
		camera.queue_free()
	
	# 深复制资源
	if node is Sprite2D and node.texture:
		node.texture = node.texture.duplicate()
	
	# 反转碰撞
	# print(node)
	if node is CollisionObject2D:
		node.collision_layer ^= 0b11
		node.collision_mask ^= 0b11
	
	# 半透明
	if node is CanvasItem:
		var c = tint
		c.a = alpha
		node.modulate = c
	
	# 翻转
	if node is Sprite2D or node is AnimatedSprite2D:
		if axis == Axis.Y:
			node.scale.x *= -1
		else:
			node.scale.y *= -1
	
	# 递归
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

	# 映射节点控制
	for tomap in nodes_mapped.keys():
		var mapped = nodes_mapped[tomap]
		if tomap is Player:
			if tomap.movable == mapped.movable:
				continue
			
			if is_actived():
				mapped.movable = true
				tomap.movable = false
				var camera: Camera2D = tomap.get_node_or_null("Camera2D")
				if camera:
					tomap.remove_child(camera)
					mapped.add_child(camera)
			else:
				tomap.movable = true
				mapped.movable = false
				var camera: Camera2D = mapped.get_node_or_null("Camera2D")
				if camera:
					mapped.remove_child(camera)
					tomap.add_child(camera)
	
	is_transitioning = false
	interact_comp.set_interactable(true)

## 获取交互次数
func get_interact_times() -> int:
	if interact_comp:
		return interact_comp.get_interact_times()
	else:
		return -1


# ========== 私有方法 ==========

## 激活
func _activate():
	current_state = State.ACTIVED
	activated.emit()
	_update_visual()

## 关闭
func _deactivate():
	current_state = State.INACTIVED
	deactivated.emit()
	_update_visual()

## 更新状态
func _update_visual():
	match current_state:
		State.INACTIVED:
			sprite.play("inactived")
		State.ACTIVED:
			sprite.play("actived")
