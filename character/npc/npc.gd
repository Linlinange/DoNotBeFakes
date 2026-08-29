class_name NPC
extends CharacterBody2D

@export var player: CharacterBody2D = null
@export var speed: float = 180.0
@export var eyes_open: bool = true
@export var speaking: bool = false
@onready var eyes: AnimatedSprite2D = $sprite/eyes
@onready var mouth: AnimatedSprite2D = $sprite/mouth
@onready var face: AnimatedSprite2D = $sprite/face
@onready var chat: ChatBubble = $chat_bubble
@onready var timer: Timer = $Timer

signal finished    # 可控终止信号

var facing: String = "down"
var eyes_time: int = randi()%240


func _ready() -> void:
	if "follow" in eyes:
		eyes.follow = self.player
	
	_update_eyes()


func _process(_delta: float) -> void:
	var current_frame = Engine.get_process_frames() % 240
	if (current_frame == eyes_time):
		eyes.play("close")
		await eyes.animation_finished
		eyes.play("open")
		await eyes.animation_finished
		_update_eyes()
		eyes_time = randi() % 240
		while(eyes_time<120):
			eyes_time = randi() % 240
	
	# 强制结束倒计时
	if Input.is_action_just_pressed("interact"):
		timer.stop()
		shut_up()
		finished.emit()  # 发射信号
	return


# ========== 公共方法 ==========
## 说一两句话
func say(content:String, speak_time:float = 5.0) -> void:
	# 重置计时器并开始倒计时
	timer.stop()
	timer.wait_time = speak_time
	timer.start()
	
	# 说话直到倒计时结束
	content += "\n[font_size=20](使用%s跳过)[/font_size]" % chat.get_key_name("interact")
	chat.say(content, speak_time)
	mouth.play("speak")
	await SignalManager.new().any([timer.timeout, finished])
	mouth.play("idle")

## 说非常重要的话
func speak(content:String, speak_time:float = 5.0) -> void:
	# 重置计时器并开始倒计时
	timer.stop()
	timer.wait_time = speak_time
	timer.start()
	
	# 说话直到倒计时结束
	chat.show_text(content)
	mouth.play("speak")
	await timer.timeout
	mouth.play("idle")

## 闭嘴，并让气泡强制消失
func shut_up() -> void:
	timer.stop()
	mouth.play("idle")
	chat.hide_bubble()

## 以一定的轨迹和过渡方式移动到指定位置
func move_to(
	pos:Vector2, 
	move_time:float = 1.0, 
	trans_type:Tween.TransitionType = Tween.TRANS_LINEAR, 
	ease_type:Tween.EaseType = Tween.EASE_OUT
	) -> void:
	create_tween() \
		.set_trans(trans_type) \
		.set_ease(ease_type) \
		.tween_property(self, "position", pos, move_time)

# ========== 私有方法 ==========
## 输入
func _get_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

## 8向计算
func _get_facing(dir: Vector2) -> String:
	var angle := dir.angle()
	var octant := int(round(angle / (PI / 4)))
	if octant < 0:
		octant += 8
	
	var directions := [
		"right", "down_right", "down", "down_left",
		"left", "up_left", "up", "up_right"
	]
	return directions[octant]

## 更新移动动画
@warning_ignore("unused_parameter")
func _update_animation(direction: Vector2) -> void:
	pass

## 更新眼睛动画
func _update_eyes() -> void:
	if eyes_open:
		eyes.play("opened")
	else:
		eyes.play("closed")
