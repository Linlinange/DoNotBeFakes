extends Node2D

@onready var level_loader: Node2D = $".."
@onready var camera: Camera2D = $"../Camera2D"
@onready var label: Label = $"../item_layer/Label"
@onready var a1: Area2D = $area1
@onready var a2: Area2D = $area2
@onready var a3: Area2D = $area3
@onready var player: Node2D = null

func _ready() -> void:
	if not level_loader:
		return
	
	a1.body_entered.connect(_tip1)
	a1.body_exited.connect(_shut_up)
	a2.body_entered.connect(_enter_a2)
	a2.body_exited.connect(_exit_a2)
	a3.body_entered.connect(_enter_a3)
	a3.body_exited.connect(_exit_a3)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if not level_loader:
		return

	if not "player" in level_loader.refs:
		return
	
	player = level_loader.refs["player"]
	if not player or not player is Player:
		return
	
	label.global_position = (player.global_position - Vector2(64, 36))*2
	pass

func _tip1(body: Node2D) -> void:
	if body is Player:
		if not "dolos" in level_loader.actors:
			return
		
		if len(level_loader.level.events)>1:
			EventSystem.run(level_loader.level.events[1], level_loader)
			if level_loader.actors["dolos"] is NPC:
				level_loader.actors["dolos"].speak("使用%s\n睁开或闭上双眼" % InputManager.get_key_name("switch"), 5.0)

func _shut_up(body: Node2D) -> void:
	if body is Player:
		if not "dolos" in level_loader.actors:
			return
		
		if len(level_loader.level.events)>2:
			EventSystem.run(level_loader.level.events[2], level_loader)

func _enter_a2(body: Node2D) -> void:
	if body is Player:
		camera.global_position = Vector2(256, 496)
	
		if not "wall" in level_loader.refs:
			return
		
		var wall = level_loader.refs["wall"]
		if not wall or not wall is FakableObject:
			return
		
		wall.set_fake(true)

func _exit_a2(body: Node2D) -> void:
	if body is Player:
		camera.global_position = Vector2(256, 176)
	
		if not "wall" in level_loader.refs:
			return
		
		var wall = level_loader.refs["wall"]
		if not wall or not wall is FakableObject:
			return
		
		wall.set_fake(false)

func _enter_a3(body: Node2D) -> void:
	if body is Player:
		label.visible = true

func _exit_a3(body: Node2D) -> void:
	if body is Player:
		label.visible = false
