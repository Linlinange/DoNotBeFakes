extends Node2D

@export var buttons: Array[Node2D] = []
@onready var player: CharacterBody2D = %player
@onready var player_saw_button: bool = false


func _ready() -> void:
	player.view_body_entered.connect(_on_player_saw_body)
	player.view_body_exited.connect(_on_player_oos_body)
	player.view_area_entered.connect(_on_player_saw_area)
	player.view_area_exited.connect(_on_player_oos_area)
	for i in len(buttons):
		if buttons[i]:
			buttons[i].fake = true
		else:
			print("第%d个button 不存在" % i)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _on_player_saw_area(area: Area2D):
	if area.is_in_group("button"):
		area.fake = false
	else:
		if "fake" in area:
			if area.is_in_group("red"):
				area.fake = false
			elif area.is_in_group("orange"):
				area.fake = true
			else:
				area.fake = false

func _on_player_saw_body(body: Node2D):
	if body.is_in_group("wall"):
		if body.is_in_group("red"):
			body.fake = false
		elif body.is_in_group("orange"):
			body.fake = true
		else:
			body.fake = false
	else:
		if "fake" in body:
			if body.is_in_group("red"):
				body.fake = false
			elif body.is_in_group("orange"):
				body.fake = true
			else:
				body.fake = false

func _on_player_oos_area(area: Area2D):
	if area.is_in_group("button"):
		area.fake = true
	else:
		if "fake" in area:
			if area.is_in_group("red"):
				area.fake = true
			elif area.is_in_group("orange"):
				area.fake = false
			else:
				area.fake = true

func _on_player_oos_body(body: Node2D):
	if body.is_in_group("wall"):
		if body.is_in_group("red"):
			body.fake = true
		if body.is_in_group("orange"):
			body.fake = false
		else:
			body.fake = true
	else:
		if "fake" in body:
			if body.is_in_group("red"):
				body.fake = true
			elif body.is_in_group("orange"):
				body.fake = false
			else:
				body.fake = true
			
		
