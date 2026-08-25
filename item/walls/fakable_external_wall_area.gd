extends Area2D

@onready var self_collision: CollisionShape2D = $CollisionShape2D
@onready var parent_collision: CollisionShape2D = $"../CollisionShape2D"


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	self_collision.shape = parent_collision.shape
	self_collision.position = parent_collision.position
