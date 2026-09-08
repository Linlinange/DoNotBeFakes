extends Node2D

@onready var level_loader: Node2D = $".."
@onready var a1: Area2D = $area_open_door
@onready var a2: Area2D = $area_exit

func _ready() -> void:
	a1.body_entered.connect(_open_door_tips)
	a2.body_entered.connect(_next_level_tips)

func _open_door_tips(body: Node2D) -> void:
	if body is Player:
		if level_loader.actors["dolos"]:
			EventSystem.run(level_loader.level.events[1], level_loader)


func _next_level_tips(body: Node2D) -> void:
	if body is Player:
		if level_loader.actors["dolos"]:
			EventSystem.run(level_loader.level.events[2], level_loader)
