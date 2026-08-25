class_name ChatBubble
extends Node2D

## 相机缩放: 这将影响CanvasLayer的缩放，以及字体的实际大小和实际位置
@export var zoom: Vector2 = Vector2(1, 1)
## 文本内容
@export_multiline var text: String = "请输入文本"
## 文本默认可见性
@export var default_visible: bool = false
## 文本偏移
@export var label_offset: Vector2 = Vector2(0, 0)
## 文字和气泡边框的间距
@export var padding: Vector2 = Vector2(10, 6)
## 气泡整体偏移
@export var bubble_offset: Vector2 = Vector2(0, -32)
## 气泡最小尺寸
@export var min_size: Vector2 = Vector2(32, 32)

@export_group("动画")
@export var auto_hide: bool = true
@export var default_duration: float = 2.0
@export var fade_duration: float = 0.12

@onready var bubble: NinePatchRect = $NinePatchRect
@onready var layer: CanvasLayer = $CanvasLayer
@onready var label: RichTextLabel = $CanvasLayer/RichTextLabel

var _tween: Tween = null


func _ready() -> void:
	set_canvas_layer(zoom)
	set_text_content(text)
	if default_visible:
		_set_alpha(1.0)
		_resize()
	else:
		_set_alpha(0.0)
		visible = false


# ========== 私有方法 ==========
func _resize() -> void:
	label.reset_size()
	var content_size = label.size
	bubble.size.x = content_size.x / zoom.x + padding.x * 2
	bubble.size.y = content_size.y / zoom.y + padding.y * 2
	if bubble.size.x < min_size.x:
		bubble.size.x = min_size.x
	if bubble.size.y < min_size.y:
		bubble.size.y = min_size.y
	position = Vector2(-bubble.size.x / 2, -bubble.size.y) + bubble_offset
	set_text_position(global_position)


func _set_alpha(a: float) -> void:
	modulate.a = a
	label.modulate.a = a


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _fade_in() -> void:
	_kill_tween()
	visible = true
	_set_alpha(0.0)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	_tween.tween_property(label, "modulate:a", 1.0, fade_duration)


func _fade_out() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	_tween.tween_property(label, "modulate:a", 0.0, fade_duration)
	await _tween.finished
	visible = false


# ========== 公共方法 ==========
## 显示一段文字，只持续一段时间
func say(content: String, duration: float = -1.0) -> void:
	set_text_content(content)
	_resize()
	_kill_tween()
	visible = true
	_set_alpha(0.0)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	_tween.tween_property(label, "modulate:a", 1.0, fade_duration)
	if auto_hide:
		var dur := duration if duration >= 0 else default_duration
		_tween.chain().tween_interval(dur)
		_tween.chain().tween_callback(_fade_out)

## 显示一段文字
func show_text(content: String) -> void:
	set_text_content(content)
	_resize()
	_fade_in()

## 隐藏气泡
func hide_bubble() -> void:
	_fade_out()

## 强制隐藏气泡
func hide_immediate() -> void:
	_kill_tween()
	_set_alpha(0.0)
	visible = false

## 设置相机缩放: 这将影响CanvasLayer的缩放，以及字体的实际大小和实际位置
func set_canvas_layer(new_zoom: Vector2) -> void:
	zoom = new_zoom
	layer.scale.x = 1.0 / zoom.x
	layer.scale.y = 1.0 / zoom.y

## 设置文字的位置: 通常不需要调用这个，但是发生意外时可以通过调用此函数调整文字预期的位置
func set_text_position(new_pos: Vector2) -> void:
	label.global_position.x = (new_pos + padding).x / layer.scale.x + label_offset.x
	label.global_position.y = (new_pos + padding).y / layer.scale.y + label_offset.y

## 设置气泡显示的内容
func set_text_content(content: String) -> void:
	text = content
	label.text = text

## 设置文字可见性
func set_text_visible(visibility: bool) -> void:
	label.visible = visibility

## 切换文字可见性
func toggle_text_visible() -> void:
	label.visible = !label.visible

## 返回 action 绑定的第一个键盘按键的显示名称
func get_key_name(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return ev.as_text()
		if ev is InputEventMouseButton:
			return "鼠标按键 %d" % ev.button_index
	return "?"
