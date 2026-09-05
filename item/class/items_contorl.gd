extends Node2D

@export var buttons: Array[Node2D] = []


func _ready() -> void:
	for i in len(buttons):
		if buttons[i]:
			buttons[i].fake = true
		else:
			print("第%d个button 不存在" % i)
