extends Node2D

@onready var player: Player = %player
@onready var dolos: NPC = %Dolos_Black

func _ready() -> void:
	player.control = true
	await dolos.say("你可以控制的物品不止一种", 4.0)
	await dolos.say("尽管不是任意种类都会生效\n但你可以多试试", 6.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _tip1(body: Node2D) -> void:
	if body.is_in_group("player"):
		return

func _shut_up(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
