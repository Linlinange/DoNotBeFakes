extends Node2D

@onready var player: CharacterBody2D = %player
@onready var dolos: CharacterBody2D = %Dolos_Black
@onready var a1: Area2D = $area_open_door
@onready var a2: Area2D = $area_exit

func _ready() -> void:
	a1.body_entered.connect(_open_door_tips)
	a2.body_entered.connect(_next_level_tips)
	await dolos.say("你好\nAletheia White", 3.0)
	await dolos.say("我是Dolos Black\n叫我Black就行", 5.0)
	await dolos.say("我将引导你\n完成接下来的关卡", 5.0)
	player.control = true
	dolos.speak("使用WASD或↑↓←→\n进行移动吧", 5.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _open_door_tips(body: Node2D) -> void:
	if body.is_in_group("player"):
		dolos.speak("你需要靠近按钮\n并按下交互键才能打开门", 12.0)

func _next_level_tips(body: Node2D) -> void:
	if body.is_in_group("player"):
		dolos.speak("继续前进，走至出口\n并按下交互键前往下一关", 12.0)
