# test/instantiate_test.gd —— 挂到一个空场景（Node2D）的根节点，F5 运行
extends Node2D

@export var LEVEL_PATH = "res://level/data/loader_test.json"

@onready var level_info: RichTextLabel = $menu_bar/RichTextLabel

func _ready() -> void:
	var level: LevelData = LevelIO.load_level(LEVEL_PATH) 	# 解析
	if level == null:
		return
	LevelInstantiator.build_level(level, self)       		# 实例化
	level_info.text = level.name + "[font_size=24]\n" + level.description + "[/font_size]"
	level_info.reset_size()
	print(level_info.global_position)
