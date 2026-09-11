extends Node2D

@onready var level_loader: Node2D = $".."
@onready var camera: Camera2D = $"../Camera2D"
@onready var a1: Area2D = $"../Node2D/area1"
@onready var player: Node2D = null
@onready var wall: FakableWall

func _ready() -> void:
	if not level_loader:
		return
	
	rotate_wall.call_deferred()
	
	a1.body_entered.connect(_enter_a1)
	a1.body_exited.connect(_exit_a1)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if not level_loader:
		return
	
	if "map_mirror" in level_loader.refs:
		var mirror = level_loader.refs["map_mirror"]
		if mirror is MapMirror:
			match mirror.get_state():
				mirror.State.INACTIVED: 
					if not "player" in level_loader.refs:
						return
					player = level_loader.refs["player"]
					if not player or not player is Player:
						return
					camera.follow = player
				mirror.State.ACTIVED:
					for to_map in mirror.nodes_mapped:
						var mapped = mirror.nodes_mapped[to_map]
						if not mapped or not mapped is Player:
							continue
						camera.follow = mapped
						break


func rotate_wall() -> void:
	if not "wall" in level_loader.refs:
		return
	if not level_loader.refs["wall"] is FakableWall:
		return
	
	wall = level_loader.refs["wall"]
	wall.rotate(PI/2)

func _enter_a1(body: Node2D) -> void:
	if body is Player:
		if wall:
			wall.set_fake(true)


func _exit_a1(body: Node2D) -> void:
	if body is Player:
		if wall:
			wall.set_fake(false)
