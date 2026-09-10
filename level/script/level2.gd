extends Node2D

@onready var level_loader: Node2D = $".."
@onready var clue: Node2D = null


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if not level_loader:
		return
	
	if not "clue" in level_loader.refs:
		return
	
	clue = level_loader.refs["clue"]
	if not clue or not clue is Clue:
		return
	
	if clue.get_interact_times()>0 and not EventSystem.get_flag("noticed"):
		EventSystem.set_flag("noticed")
		if len(level_loader.level.events)>1:
			EventSystem.run(level_loader.level.events[1], level_loader)
		if len(level_loader.level.events)>2:
			await EventSystem.run(level_loader.level.events[2], level_loader)
			# EventSystem.ended
			clue.fakable = false
			clue.set_fake(true)
