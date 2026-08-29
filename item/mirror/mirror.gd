class_name MirrorStand
extends Area2D

enum State { INACTIVED, ACTIVED }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effect_area: Area2D = $EffectArea
@onready var player_in_range: bool = false

## 镜子当前的状态
@export var current_state: State = State.INACTIVED
## true=交互一定次数后永久保持，无法切换
@export var disposable: bool = false
## >0 则 N 秒后自动关闭，0=无限
@export var effect_duration: float = 0.0    

var is_transitioning: bool = false   # 正在播放切换动画，拒绝交互 

var _timer: Timer
var _interact_times: int = 0 # 交互次数 

signal state_changed(new_state: State)
signal activated
signal deactivated


func _ready():
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_deactivate)
	add_child(_timer)
	_update_visual()
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

@warning_ignore("unused_parameter")
func _process(delta: float):
	if player_in_range and Input.is_action_just_pressed("interact"):
		interact()


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


func _activate():
	current_state = State.ACTIVED
	activated.emit()
	state_changed.emit(current_state)
	
	for body in effect_area.get_overlapping_bodies():
		if "fakable" in body:
			body.add_to_group("mirror_controlled")
			body.fakable = true
			body.fake = false
			body.fakable = false
	
	if effect_duration > 0:
		_timer.start(effect_duration)
	
	_update_visual()


func _deactivate():
	current_state = State.INACTIVED
	state_changed.emit(current_state)
	
	deactivated.emit()
	for body in effect_area.get_overlapping_bodies():
		if "fakable" in body:
			body.add_to_group("mirror_controlled")
			body.fakable = true
			body.fake = true
			body.fakable = false
	
	# 释放控制权，让外界重新接管
	for body in get_tree().get_nodes_in_group("mirror_controlled"):
		if is_instance_valid(body):
			body.remove_from_group("mirror_controlled")
	
	_timer.stop()
	_update_visual()


func _update_visual():
	match current_state:
		State.INACTIVED:
			sprite.play("inactived")
		State.ACTIVED:
			sprite.play("actived")

# ========== 公共接口 ==========

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
