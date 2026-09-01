extends Node2D

@onready var player: Player = %player
@onready var dolos: NPC = %Dolos_Black
@onready var a1: Area2D = $area1
@onready var a2: Area2D = $area2
@onready var a3: Area2D = $area3
@onready var wall: StaticBody2D = $fakable_external_wall
@onready var camera: Camera2D = $Camera2D
@onready var label: Label = $item_layer/Label

func _ready() -> void:
	a1.body_entered.connect(_tip1)
	a1.body_exited.connect(_shut_up)
	a2.body_entered.connect(_enter_a2)
	a2.body_exited.connect(_exit_a2)
	a3.body_entered.connect(_enter_a3)
	a3.body_exited.connect(_exit_a3)
	await dolos.say("除了眼见为\"实\"\n还可以自欺欺人", 5.0)
	player.movable= true
	dolos.speak("使用%s\n睁开或闭上双眼" % InputManager.get_key_name("switch"), 5.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	label.global_position = (player.global_position - Vector2(64, 36))*2
	pass

func _tip1(body: Node2D) -> void:
	if body is Player:
		dolos.speak("使用%s\n睁开或闭上双眼" % InputManager.get_key_name("switch"), 5.0)

func _enter_a2(body: Node2D) -> void:
	if body is Player:
		wall.fakable = true
		wall.fake = true
		wall.fakable = false
		camera.global_position = Vector2(0, 320)

func _exit_a2(body: Node2D) -> void:
	if body is Player:
		wall.fakable = true
		wall.fake = false
		wall.fakable = false
		camera.global_position = Vector2(0, 0)

func _enter_a3(body: Node2D) -> void:
	if body is Player:
		label.visible = true

func _exit_a3(body: Node2D) -> void:
	if body is Player:
		label.visible = false

func _shut_up(body: Node2D) -> void:
	if body is Player:
		dolos.shut_up()
