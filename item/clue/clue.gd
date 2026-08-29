class_name Clue
extends FakableObject


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chat: ChatBubble = $chat_bubble
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var interact_comp: InteractComponent = $InteractComponent


## 线索显示的内容
@export_multiline var content: String = "线索……"
## 线索显示的时长
@export var duration: float = 5.0
## 线索唯一标识
@export var id: int = -1

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
@export var tooltip_offset: Vector2 = Vector2(0, -32):
	set(value):
		tooltip_offset = value
		if interact_comp:
			interact_comp.tooltip_offset = value


func _ready() -> void:
	super._ready()
	_play_idle()
	interact_comp.interacted.connect(interact)
	interact_comp.max_interact_times = self.max_interact_times
	interact_comp.tooltip_content = self.tooltip_content
	interact_comp.tooltip_offset = self.tooltip_offset

# ========== 公共方法 ==========

## 交互: 展示线索内容，并写入存档
func interact() -> void:
	if fake:
		return
	
	if is_functional():
		chat.say(content, duration)
		if id!=-1:
			var json: Dictionary = SavesManager.json_read(SavesManager.Path.CLUES)
			json[str(id)] = true
			SavesManager.json_write(SavesManager.Path.CLUES, json)
	audio.pitch_scale = randf_range(0.4, 0.7)
	audio.play()
	return

## 获取交互次数
func get_interact_times() -> int:
	if interact_comp:
		return interact_comp.get_interact_times()
	else:
		return -1

# ========== 私有方法 ==========

## 播放对应状态的循环待机动画
func _play_idle() -> void:
	return

# 更新虚假值带来的影响
func _on_fake_updated() -> void:
	if fake:
		chat.hide_immediate()
