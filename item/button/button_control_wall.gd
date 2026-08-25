extends Node2D

@export_group("文字")
## 按钮上会显示的文字内容
@export var prompt_text: String = "按F交互"
## 文字偏移
@export var labels_offset: Vector2 = Vector2(0, 0)

## 用于显示文字的节点
@export var labels: Array[Label] = []

@export_group("按钮")
## 用于控制的按钮节点
@export var buttons: Array[Node2D] = []

@export_group("墙")
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
			
	if len(labels) <= 0:
		print("没有label")
	for i in len(labels):
		if not labels[i]:
			print("第%d个label 不存在" % i)
		elif i >= len(buttons):
			print("索引%d大于buttons长度(%d)" % [i, len(buttons)])
		elif not buttons[i]:
			print("第%d个button 不存在" % i)
		else:
			#print("label 存在")
			labels[i].text = prompt_text
			labels[i].visible = false
			labels[i].position = buttons[i].global_position*2 - Vector2(64, 48) + labels_offset
			#print(labels[i].position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	
	# ========== 查询按钮状态，控制其他物体 ==========
	for i in len(buttons):
		if labels[i]:
			if player_in_range and buttons[i].visible == true:
				labels[i].visible = true
			else:
				labels[i].visible = false
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
		for i in len(labels):
			if labels[i]:
				labels[i].visible = true

func _on_button_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		for i in len(labels):
			if labels[i]:
				labels[i].visible = false
			
