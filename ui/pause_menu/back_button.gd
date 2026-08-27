extends Button

@export var scene: PackedScene = null

func _on_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_rpitch("ui_button", 0.0, 0.7, 0.9)
	
	# 返回主菜单
	if TransitionManager:
		if scene:
			TransitionManager.change_scene(scene)
