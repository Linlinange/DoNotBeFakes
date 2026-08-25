extends Area2D

@export var prompt_text: String = "按 %s 交互" % get_key_name("interact")
## 文字偏移
@export var label_offset: Vector2 = Vector2(0, 0)
@onready var label: Label = $UI/Label

@export var next_scene: PackedScene = null
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	label.text = prompt_text
	label.visible = false
	label.position = self.global_position*2 - Vector2(112,80) + label_offset
	return

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if player_in_range  and Input.is_action_just_pressed("interact"):
		if next_scene:
			if TransitionManager:
				TransitionManager.change_scene(next_scene)
			else:
				get_tree().change_scene_to_packed(next_scene)
		else:
			prompt_text = "当前为最后一关"
			label.text = prompt_text
		audio.pitch_scale = randf_range(1.5, 1.8)
		audio.play()
	return

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		label.visible = true
	return

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		label.visible = false
	return
			
# 返回 action 绑定的第一个键盘按键的显示名称
func get_key_name(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			# Godot 4 返回如 "W", "Space", "Shift"
			return ev.as_text()
		if ev is InputEventMouseButton:
			return "鼠标按键 %d" % ev.button_index
	return "?"
