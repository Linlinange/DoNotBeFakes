extends Button


func _ready() -> void:
	pass


func _on_pressed() -> void:
	# 返回主菜单
	if TransitionManager:
		TransitionManager.change_scene("res://ui/menu/main_menu.tscn")
