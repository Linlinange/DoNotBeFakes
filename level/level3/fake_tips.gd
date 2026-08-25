extends Label

@onready var player: CharacterBody2D = %player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (player.global_position.x < 0 and player.global_position.y > -96) and (player.global_position.y < 64):
		self.visible = true
		self.position = player.global_position*2 - Vector2(176, 110)
	else:
		self.visible = false
	pass
