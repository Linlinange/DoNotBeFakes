extends Node2D

@onready var player: Player = %player
@onready var dolos: NPC = %Dolos_Black
@onready var clue: Clue = $items_control/clue
@onready var a1: Area2D = $area1
@onready var t: int = 0


func _ready() -> void:
	#print(2**31-1)
	#print(clue.get_interact_times())
	a1.body_entered.connect(_tip1)
	a1.body_exited.connect(_shut_up)
	await dolos.say("太过自信会被虚假欺骗\n眼见才为实", 5.0)
	player.movable = true
	if OS.has_feature("pc"):
		dolos.speak("你的视野会跟随鼠标指针\n借助视野可以化虚为实，试试吧", 15.0)
	else:
		dolos.speak("你的视野会跟随手指按下的位置\n借助视野可以化虚为实，试试吧", 15.0)


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	dolos.chat._resize()
	if t<1 and clue.get_interact_times()>0:
		dolos.move_to(Vector2(-48, 16), 1.4)
		dolos.say("在那边干什么呢？\n往上再走两步就成功了", 8.0)
		t += 1
	elif t==1 and dolos.position == Vector2(-48, 16):
		dolos.move_to(Vector2(48, 16), 1.2)
		t += 1
	elif t==2 and dolos.position == Vector2(48, 16):
		dolos.move_to(Vector2(48, 96), 2.0, Tween.TRANS_CUBIC)
		t += 1
	else:
		if t==3 and dolos.position == Vector2(48, 96):
			t += 1
			clue.set_fake(true)
	pass


func _tip1(body: Node2D) -> void:
	if body is Player:
		if OS.has_feature("pc"):
			dolos.speak("你的视野会跟随鼠标指针\n借助视野可以化虚为实，试试吧", 15.0)
		else:
			dolos.speak("你的视野会跟随手指按下的位置\n借助视野可以化虚为实，试试吧", 15.0)


func _shut_up(body: Node2D) -> void:
	if body is Player:
		dolos.shut_up()
