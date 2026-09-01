class_name MirrorStand
extends Area2D

enum State { INACTIVED, ACTIVED }

signal activated
signal deactivated

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effect_area: Area2D = $EffectArea
@onready var player_in_range: bool = false

## 镜子当前的状态
@export var current_state: State = State.INACTIVED
## true=交互一定次数后永久保持，无法切换
@export var disposable: bool = false 

var is_transitioning: bool = false   # 正在播放切换动画，拒绝交互 

var _interact_times: int = 0 # 交互次数 


func _ready():
	_update_visual()

@warning_ignore("unused_parameter")
func _process(delta: float):
	if player_in_range and Input.is_action_just_pressed("interact"):
		interact()


## 交互: 切换镜子状态
func interact():
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

## 激活
func _activate():
	current_state = State.ACTIVED
	activated.emit()
	
	for body in effect_area.get_overlapping_bodies():
		if "fakable" in body:
			body.add_to_group("mirror_controlled")
			body.fakable = true
			body.fake = false
			body.fakable = false
	_update_visual()

## 关闭
func _deactivate():
	current_state = State.INACTIVED
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
	_update_visual()


func _update_visual():
	match current_state:
		State.INACTIVED:
			sprite.play("inactived")
		State.ACTIVED:
			sprite.play("actived")

# ========== 公共方法 ==========

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
