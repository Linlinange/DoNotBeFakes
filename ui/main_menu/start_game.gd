extends Button

@export var resource: String = ""

func _on_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_rpitch("ui_button", 0.0, 0.7, 0.9)
	
	# 开始游戏
	if TransitionManager:
		TransitionManager.change_scene(resource)
