extends Node2D

@export var clues: Array[Clue] = []
@onready var player: Player = %player


func _ready() -> void: 
	var json: Dictionary = FilesManager.json_read(FilesManager.Path.CLUES)
	if json == {}:
		var sm = FilesManager.new()
		for i in len(sm.FormerlyPath.CLUES):
			json = FilesManager.abs_json_read(sm.FormerlyPath.CLUES[i])	# 旧存档继承
			if json != {}:
				print("从%s继承新存档" % sm.FormerlyPath.CLUES[i])
				break
	print("从存档中整理出的线索如下: \n%s" % JSON.stringify(json, "\t"))
	for clue in clues:
		if not clue:
			print("clues 数组配置有误，存在空clue")
			continue
		elif str(clue.id) in json:
			if json[str(clue.id)] == true:
				clue.set_fake(false)
		else:
			print("Clue的ID为%s 可能是配置有误 或 单纯存档无对应的记录" % clue.id)
			json[str(clue.id)] = false
	FilesManager.json_write(FilesManager.Path.CLUES, json)
	pass


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass


func _tip1(body: Node2D) -> void:
	if body is Player:
		pass


func _shut_up(body: Node2D) -> void:
	if body is Player:
		pass
