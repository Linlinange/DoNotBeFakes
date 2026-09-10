extends Node2D

@onready var level_loader: Node2D = $".."
@onready var a1: Area2D = $a1
@onready var a2: Area2D = $a2

func _ready() -> void:
	if not level_loader:
		return
	
	a1.body_entered.connect(_open_door_tips)
	a2.body_entered.connect(_next_level_tips)

func _open_door_tips(body: Node2D) -> void:
	if body is Player:
		if not "dolos" in level_loader.actors:
			return
		
		if level_loader.actors["dolos"] and len(level_loader.level.events)>1:
			EventSystem.run(level_loader.level.events[1], level_loader)


func _next_level_tips(body: Node2D) -> void:
	if body is Player:
		if not "dolos" in level_loader.actors:
			return
		
		if level_loader.actors["dolos"] and len(level_loader.level.events)>2:
			EventSystem.run(level_loader.level.events[2], level_loader)
