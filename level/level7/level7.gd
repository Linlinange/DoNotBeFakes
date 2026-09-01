extends Node2D

@onready var player: Player = %player

func _ready() -> void:
	player.movable= true


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _tip1(body: Node2D) -> void:
	if body is Player:
		return

func _shut_up(body: Node2D) -> void:
	if body is Player:
		return
