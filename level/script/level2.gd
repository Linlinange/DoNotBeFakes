extends Node2D

@onready var level_loader: Node2D = $".."
@onready var clue: Node2D = null


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	clue = level_loader.refs["clue"]
	if is_instance_valid(clue) and clue is Clue:
		if clue.get_interact_times()>0 and not EventSystem.get_flag("noticed"):
			EventSystem.set_flag("noticed")
			EventSystem.run(level_loader.level.events[1], level_loader)
			await EventSystem.run(level_loader.level.events[2], level_loader)
			# EventSystem.ended
			clue.fakable = false
			clue.set_fake(true)
