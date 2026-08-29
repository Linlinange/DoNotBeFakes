extends Node2D

@onready var player: Player = %player
@onready var dolos: NPC = %Dolos_Black
@onready var a1: Area2D = $area1

func _ready() -> void:
	a1.body_entered.connect(_tip1)
	a1.body_exited.connect(_shut_up)
	await dolos.say("我有时会有事\n会暂时离开一会", 3.0)
	await dolos.say("你自己可以做到的", 3.0)
	dolos.move_to(Vector2(168, -128), 0.5)
	dolos.chat.bubble_offset += Vector2(-112, 32)
	player.movable= true
	await dolos.say("记得小心，别踩到炸弹\n否则会发生爆炸", 8.0)
	dolos.move_to(Vector2(168, -256), 1.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	dolos.chat._resize()
	pass

func _tip1(body: Node2D) -> void:
	if body.is_in_group("player"):
		return

func _shut_up(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
