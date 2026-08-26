extends Node2D


## 用于控制的按钮节点
@export var buttons: Array[Node2D] = []

## 受控制的墙节点
@export var walls: Array[Node2D] = []
## 按钮打开时墙的宽度和长度
@export var size_on: Vector2 = Vector2(32, 32)
## 按钮关闭时墙的宽度和长度
@export var size_off: Vector2 = Vector2(32, 96)

var player_in_range: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in len(buttons):
		if not buttons[i]:
			print("第%d个button 不存在" % i)
		else:
			#print("第%d个button 存在" % i)
			buttons[i].body_entered.connect(_on_button_body_entered)
			buttons[i].body_exited.connect(_on_button_body_exited)
			
	for i in len(walls):
		if not walls[i]:
			print("第%d个wall 不存在" % i)
		#else:
			#print("第%d个wall 存在" % i)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	
	# ========== 查询按钮状态，控制其他物体 ==========
	for i in len(buttons):
		if buttons[i].is_on():           # 调用 button 的公共接口
			for wall in walls:
				if wall:
					wall.size = size_on
		else:
			for wall in walls:
				if wall:
					wall.size = size_off


# 信号回调，即信号触发时执行的函数，body为触发信号的实例
func _on_button_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true

func _on_button_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
			
