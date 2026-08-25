extends Button

func _ready():
	pass


func _on_pressed() -> void:
	# 等待并重载当前场景
	TransitionManager.reload_current_scene()
