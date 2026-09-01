class_name FakableButton
extends FakableObject

enum State { OFF, ON }

signal state_changed(new_state: State)
signal turned_on
signal turned_off


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var interact_comp: InteractComponent = $InteractComponent


## 按钮当前的状态
@export var current_state: State = State.OFF

## 最大交互次数，-1 表示无限
@export var max_interact_times: int = -1:
	set(value):
		max_interact_times = value
		if interact_comp:
			interact_comp.max_interact_times = value
## 提示内容
@export var tooltip_content: String = "按%s交互" % InputManager.get_key_name("interact"):
	set(value):
		tooltip_content = value
		if interact_comp:
			interact_comp.tooltip_content = value
## 提示偏移
@export var tooltip_offset: Vector2 = Vector2(0, -16):
	set(value):
		tooltip_offset = value
		if interact_comp:
			interact_comp.tooltip_offset = value

var is_transitioning: bool = false   ## 是否正在切换状态: 为true时, 拒绝交互

# ========== 继承方法 ==========

func _ready() -> void:
	super._ready()
	_play_idle()
	interact_comp.interacted.connect(interact)
	interact_comp.max_interact_times = self.max_interact_times
	interact_comp.tooltip_content = self.tooltip_content
	interact_comp.tooltip_offset = self.tooltip_offset

func _on_fake_updated() -> void:
	if fake:
		interact_comp.set_interactable(false)
	else:
		interact_comp.set_interactable(true)

# ========== 公共方法 ==========

## 检查按钮是否开启
func is_on() -> bool:
	return current_state == State.ON

## 获取状态
func get_state() -> State:
	return current_state

## 获取状态名
func get_state_name() -> String:
	if current_state == State.ON:
		return "ON"
	else:
		return "OFF"

## 交互: 切换按钮状态
func interact() -> void:
	if is_transitioning:
		return
	if fake:
		return
	#print("切换")
	
	audio.pitch_scale = randf_range(0.8, 1.2)
	audio.play()
	is_transitioning = true
	interact_comp.set_interactable(false)
	
	match current_state:
		State.OFF:
			sprite.play("turn_on")
			await sprite.animation_finished
			current_state = State.ON
			turned_on.emit()
		State.ON:
			sprite.play("turn_off")
			await sprite.animation_finished
			current_state = State.OFF
			turned_off.emit()
	
	state_changed.emit(current_state)
	is_transitioning = false
	interact_comp.set_interactable(true)
	_play_idle()

## 获取交互次数
func get_interact_times() -> int:
	if interact_comp:
		return interact_comp.get_interact_times()
	else:
		return -1


# ========== 私有方法 ==========

## 播放对应状态的循环待机动画
func _play_idle() -> void:
	match current_state:
		State.OFF:
			sprite.play("idle_off")
		State.ON:
			sprite.play("idle_on")