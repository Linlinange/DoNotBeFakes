## 输入管理器 
# class_name InputManager
extends Node2D

func _process(_delta: float) -> void:
	var key_F = Input.is_action_just_pressed("interact")
	if key_F:
		var tree = get_tree().root.get_children()
		for child in tree[len(tree)-1].get_children():
			if child is Player:
				if not child.interactable:
					continue
				if child.interact_comp.comps_in_range.is_empty():
					continue
				if child.interact_comp.try_interact():
					break
			elif child is NPC:
				child.timer.stop()
				child.shut_up()
				child.finished.emit()  # 发射信号

## 返回 action 绑定的第一个键盘按键的显示名称
func get_key_name(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if OS.has_feature("mobile"):
		if action == "interact":
			return "交互键"
		elif action == "switch":
			return "长按屏幕或切换键"
	for ev in events:
		if ev is InputEventKey:
			return ev.as_text().replace(" - Physical", "键")
		if ev is InputEventMouseButton:
			return "鼠标按键%d" % ev.button_index
	return "?"
