extends Button

func _on_pressed() -> void:
	# 开始游戏
	if TransitionManager:
		TransitionManager.change_scene("res://ui/menu/level_menu.tscn")
