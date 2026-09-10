extends Camera2D

@onready var level_loader: Node2D = $".."
@onready var player: Node2D = null


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if not level_loader:
		return

	if not "player" in level_loader.refs:
		return
	
	player = level_loader.refs["player"]
	if not player or not player is Player:
		return
	
	self.global_position = player.global_position
