extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

var _exemptions: Array[Node] = []
var _original_modes: Dictionary = {}

var is_transitioning: bool = false
var is_paused: bool = false


func _ready() -> void:
	add_exemption(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect.color = Color.BLACK
	rect.modulate.a = 0.0


## 强制恢复（不播动画，用于切场景前清理状态）
func _force_resume() -> void:
	if not is_paused:
		return
	get_tree().paused = false
	for node in _original_modes:
		if is_instance_valid(node):
			node.process_mode = _original_modes[node]
	_original_modes.clear()
	is_paused = false


func add_exemption(node: Node) -> void:
	if node == null or node in _exemptions:
		return
	_exemptions.append(node)
	if is_paused and not _original_modes.has(node):
		if is_instance_valid(node):
			_original_modes[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_ALWAYS


func toggle_pause() -> void:
	if is_transitioning:
		return
	if is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	if is_paused or is_transitioning:
		return
	
	is_transitioning = true
	await _fade(0.5, 0.15)
	
	_original_modes.clear()
	for node in _exemptions:
		if is_instance_valid(node):
			_original_modes[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().paused = true
	is_paused = true
	is_transitioning = false


func resume_game() -> void:
	if not is_paused or is_transitioning:
		return
	
	is_transitioning = true
	get_tree().paused = false
	
	for node in _original_modes:
		if is_instance_valid(node):
			node.process_mode = _original_modes[node]
	_original_modes.clear()
	
	await _fade(0.0, 0.15)
	is_paused = false
	is_transitioning = false

## 重载当前场景（带过渡）
func reload_current_scene() -> void:
	if is_transitioning:
		return
	
	_force_resume()  # ← 关键：切场景前必须恢复，否则新场景也是暂停的
	is_transitioning = true
	await _fade(1.0, 0.2)
	get_tree().reload_current_scene()
	# reload 后当前节点会被销毁，下面这行其实执行不到
	# 但为了保险，逻辑上仍保留
	await get_tree().process_frame
	await _fade(0.0, 0.2)
	is_transitioning = false

## 切换到其他场景（带过渡）
func change_scene(target: Variant) -> void:
	if is_transitioning:
		return
	
	_force_resume()
	is_transitioning = true
	
	# 淡出
	await _fade(1.0, 0.2)
	
	# 根据类型切换场景
	if target is String:
		get_tree().change_scene_to_file(target)
	elif target is PackedScene:
		get_tree().change_scene_to_packed(target)
	else:
		push_error("change_scene 只接受 String 路径或 PackedScene 资源，收到: %s" % typeof(target))
		is_transitioning = false
		return
	
	# 等待新场景加载完成
	await get_tree().process_frame
	
	# 淡入
	await _fade(0.0, 0.2)
	is_transitioning = false


func _fade(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", target_alpha, duration)
	await tween.finished
