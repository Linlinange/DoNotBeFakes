extends Label

# 视图大小
@onready var viewport_size: Vector2 = get_viewport_rect().size


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.position = Vector2(viewport_size.x/2, -viewport_size.y/2) - Vector2(128, 0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# 当前帧率
	var fps = Engine.get_frames_per_second()
	# 物理帧率
	var physics_fps = Engine.physics_ticks_per_second
	# 当前是第几帧（进程帧）
	var frame = Engine.get_process_frames()
	self.text = "帧率: "+str(fps)+" | "
	self.text += str(physics_fps)+"\n"
	self.text += "当前为第%d帧"%frame+"\n"
	pass
