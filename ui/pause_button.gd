extends Button

func _ready():
	pass

func _on_pressed() -> void:
	# 暂停游戏
	TransitionManager.pause_game()
