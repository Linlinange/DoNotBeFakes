class_name Clue
extends FakableObject

## 线索显示的内容
@export_multiline var content: String = "线索……"
## 线索显示的时长
@export var duration: float = 5.0
## 线索唯一标识
@export var id: int = -1
## 被靠近时会显示的提示
@export var tooltip_content: String = "按F交互"
## 提示的坐标偏移
@export var tooltip_offset: Vector2 = Vector2(0, 0)


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chat: ChatBubble = $chat_bubble
@onready var tooltip: Label = $CanvasLayer/tooltip
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var player_in_range: bool = false
@onready var interact_times: int = 0


func _ready() -> void:
	super._ready()
	tooltip.text = tooltip_content
	tooltip.visible = false
	tooltip.position = self.global_position*2 + Vector2(-64, 32) + tooltip_offset
	_play_idle()
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	self.area_entered.connect(_on_area_entered)
	self.area_exited.connect(_on_area_exited)


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if player_in_range and is_functional():
		tooltip.visible = true
		if Input.is_action_just_pressed("interact"):
			interact()
	else:
		tooltip.visible = false

# ========== 公共接口 ==========
## 交互
func interact() -> void:
	if is_functional():
		chat.say(content, duration)
		if interact_times < 2**31-1:
			interact_times += 1
		if id!=-1:
			var json: Dictionary = SavesManager.json_read(SavesManager.Path.CLUES)
			json[str(id)] = true
			SavesManager.json_write(SavesManager.Path.CLUES, json)
	audio.pitch_scale = randf_range(0.4, 0.7)
	audio.play()
	return

func get_interact_times() -> int:
	return interact_times

# ========== 私有方法 ==========
## 播放对应状态的循环待机动画
func _play_idle() -> void:
	return

# 更新虚假值带来的影响
func _on_fake_updated() -> void:
	if fake:
		chat.hide_immediate()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_area_entered(area: Node2D) -> void:
	if area.is_in_group("player"):
		player_in_range = true

func _on_area_exited(area: Node2D) -> void:
	if area.is_in_group("player"):
		player_in_range = false
