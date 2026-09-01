extends Node2D

@onready var player: Player = %player
@onready var dolos: NPC = %Dolos_Black
@onready var a1: Area2D = $area1
@onready var a2: Area2D = $area2
@onready var wall: StaticBody2D = $items_control/fakable_external_wall

func _ready() -> void:
	a1.body_entered.connect(_tip1)
	a1.body_exited.connect(_shut_up)
	a2.body_entered.connect(_enter_a2)
	a2.body_exited.connect(_exit_a2)
	await dolos.say("这里有一面映射镜\n它可以映射一些物体\n作为假副本，比如说你", 6.0)
	await dolos.say("与之交互可以控制\n被映射出的另一个“你”", 5.0)
	player.movable= true
	await dolos.say("真实的你，无法通过实墙\n可以通过虚墙", 5.0)
	await dolos.say("而假副本，可以通过实墙\n无法通过虚墙", 5.0)
	await dolos.say("无论是你还是假副本\n都无法通过外墙", 5.0)


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

func _enter_a2(body: Node2D) -> void:
	if body is Player:
		wall.fakable = true
		wall.fake = true
		wall.fakable = false

func _exit_a2(body: Node2D) -> void:
	if body is Player:
		wall.fakable = true
		wall.fake = false
		wall.fakable = false
