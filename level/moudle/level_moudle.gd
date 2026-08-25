extends Node2D

@onready var player: CharacterBody2D = %player
@onready var green_item: Node2D = $green_item
@onready var player_saw_button: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.view_body_entered.connect(_on_player_saw_body)
	player.view_body_exited.connect(_on_player_oos_body)
	player.view_area_entered.connect(_on_player_saw_area)
	player.view_area_exited.connect(_on_player_oos_area)
	for button in green_item.buttons: 
		button.visible = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_saw_area(area: Area2D):
	if area.is_in_group("button"):
		area.visible = true

func _on_player_saw_body(body: Node2D):
	if body.is_in_group("wall"):
		if body.is_in_group("red"):
			body.fake = false
		if body.is_in_group("orange"):
			body.fake = true

func _on_player_oos_area(area: Area2D):
	if area.is_in_group("button"):
		area.visible = false

func _on_player_oos_body(body: Node2D):
	if body.is_in_group("wall"):
		if body.is_in_group("red"):
			body.fake = true
		if body.is_in_group("orange"):
			body.fake = false
		
