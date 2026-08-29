## 输入管理器 
class_name InputManager

## 返回 action 绑定的第一个键盘按键的显示名称
static func get_key_name(action: String) -> String:
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
