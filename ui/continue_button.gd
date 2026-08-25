extends Button

func _ready():
	pass

func _on_pressed() -> void:
	# 继续游戏
	TransitionManager.resume_game()
