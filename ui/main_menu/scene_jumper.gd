extends Button

## 按下按钮后会前往的场景
@export var scene: PackedScene = null
## 按钮上会显示的文字
@export var label_text: String = "场景"

@export_group("无场景选项")
## 场景为空时的文本提示
@export var null_tooltip: String = "本场景未开放"
## 场景为空时的文本提示气泡的坐标偏移
@export var chat_offset: Vector2 = Vector2(48.0, -16.0)

@onready var label: RichTextLabel = $RichTextLabel
@onready var chat: Node2D = $chat_bubble


func _ready() -> void:
	chat.bubble_offset = chat_offset
	label.text = label_text
	label.size = self.size
	if not scene:
		tooltip_text = null_tooltip
		label.text = "[color=red]"+label.text+"[/color]"
	return


func _on_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_rpitch("ui_button", 0.0, 0.7, 0.9)
	if not scene:
		chat.say("[font_size=48]"+null_tooltip+"[/font_size]", 2.0)
		return
	elif TransitionManager:
		TransitionManager.change_scene(scene)
		return
	else:
		return
