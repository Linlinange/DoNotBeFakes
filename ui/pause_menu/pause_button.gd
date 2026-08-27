extends Button

func _ready():
	pass

func _on_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx_rpitch("ui_button", 0.0, 0.7, 0.9)
	
	# 暂停游戏
	TransitionManager.pause_game()
