class_name Exit
extends Area2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var interact_comp: InteractComponent = $InteractComponent

## 交互后切换到的下一个场景
@export var next_scene: PackedScene = null

## 最大交互次数，-1 表示无限
@export var max_interact_times: int = -1:
	set(value):
		max_interact_times = value
		if interact_comp:
			interact_comp.max_interact_times = value
## 提示内容
@export var tooltip_content: String = "按%s进入一关" % InputManager.get_key_name("interact"):
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


func _ready() -> void:
	_play_idle()
	interact_comp.interacted.connect(interact)
	interact_comp.max_interact_times = self.max_interact_times
	interact_comp.tooltip_content = self.tooltip_content
	interact_comp.tooltip_offset = self.tooltip_offset
	interact_comp.reset_rotation(false)
	return


# ========== 公共方法 ==========

## 交互: 切换场景
func interact() -> void:
	audio.pitch_scale = randf_range(1.5, 1.8)
	audio.play()

	if next_scene:
		if TransitionManager:
			TransitionManager.change_scene(next_scene)
		else:
			get_tree().change_scene_to_packed(next_scene)
	else:
		tooltip_content = "当前为最后一关"


# ========== 私有方法 ==========

## 播放对应状态的循环待机动画
func _play_idle() -> void:
	return
