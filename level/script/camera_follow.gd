extends Camera2D

enum Mode{
	ANY,
	PLAYER
}

@export var mode: Mode = Mode.PLAYER
@onready var level_loader: Node2D = $".."
@onready var follow: Node2D = null


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if mode == Mode.PLAYER:
		if not level_loader:
			return
		if not "player" in level_loader.refs:
			return
		
		follow = level_loader.refs["player"]
		if not follow or not follow is Player:
			return
	
	if follow:
		self.global_position = follow.global_position
