class_name TouchPoint
extends Control

@export var fill_color: Color = Color(0.2, 0.7, 1.0, 0.25)
@export var stroke_color: Color = Color(0.2, 0.7, 1.0, 0.7)

func _ready() -> void:
	get_tree().root.add_child.call_deferred(self)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, fill_color, true)
	draw_circle(Vector2.ZERO, 16, stroke_color, false, 1.0, true)
