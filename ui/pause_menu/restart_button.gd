extends Button


func _on_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_rpitch("ui_button", 0.0, 0.7, 0.9)
	
	# 等待并重载当前场景
	TransitionManager.reload_current_scene()
