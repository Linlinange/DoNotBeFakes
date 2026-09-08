# test/instantiate_test.gd —— 挂到一个空场景（Node2D）的根节点，F5 运行
extends Node2D

@export var LEVEL_PATH: String = "res://level/data/loader_test.json"
@export var Level_id: int = -1

@onready var level_info: RichTextLabel = $menu_bar/RichTextLabel

var actors := {}  # 在 _ready 中填：演员名字 → 节点
var level: LevelData

func _ready() -> void:
	# 读取json关卡数据
	if Level_id == -1:
		level = FilesManager.load_level(LEVEL_PATH)
	else:
		level = FilesManager.load_level("user://%s/level%s.json" % [FilesManager.LEVEL_DIR, Level_id], false)
		if level == null:
			level = FilesManager.load_level("res://%s/data/level%s.json" % [FilesManager.LEVEL_DIR, Level_id])
	
	if level == null:
		return
	
	# 实例化	
	var refs = LevelInstantiator.build_level_with_refs(level, self)
	level_info.text = level.name + "[font_size=24]\n%s[/font_size]" % level.description
	level_info.reset_size()

	for char_ in level.characters:
		if not "name" in char_:
			continue
		var name_ = char_["name"]
		var node = refs[name_]
		if node is NPC:
			for node_j in refs["characters"]:
				if node_j is Player:
					node.set_follow(node_j)
					break
	
	# 事件
	EventSystem.reset()
	await EventSystem.run(level.events[0], self)
	
