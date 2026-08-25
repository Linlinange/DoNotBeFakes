class_name FakableBomb
extends FakableObject

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var player_in_range: bool = false

## 激活时长: 激活时，达到一定值后爆炸; 未激活时，会逐渐衰减
@onready var active_time: float = 0.0

## 是否处于爆炸
@onready var exploding: bool = false

## 爆炸后等待多久重开（秒）
@export var restart_delay: float = 1.0

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	super._ready()

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if player_in_range and is_functional():
		active_time += delta
	else:
		if active_time > 0.0:
			active_time -= delta
		else:
			active_time = 0.0
	
	if not exploding and active_time >= 0.2:
		exploding = true
		fakable = false
		sprite.play("explode")
	
		audio.pitch_scale = randf_range(0.8, 1.4)
		audio.play()
	
		# 等待并重载当前场景
		await get_tree().create_timer(restart_delay).timeout
		TransitionManager.reload_current_scene()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
