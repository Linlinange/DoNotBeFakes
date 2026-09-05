## 场景管理器 
class_name SceneManager

## 浅复制场景节点: 
	## 复制通过场景实例化。
	## 原始根节点只有部分属性会被复制。
	## 材质、纹理不会被复制。
static func copy(node: Node) -> Node:
	var packed_scene: PackedScene = load(node.scene_file_path)
	var new: Node
	if packed_scene:
		new = packed_scene.instantiate()
	else:
		push_warning("节点场景不存在")
	
	if not new:
		push_warning("不允许复制不存在场景的节点")
	
	if new is Node2D:
		new.transform = node.transform

	if new is FakableObject:
		new.fake = node.fake
		new.fakable = node.fakable
		new.visual_mode = node.visual_mode
		new.fake_alpha = node.fake_alpha
		new.fake_collision_layer = node.fake_collision_layer
		if new is FakableWall:
			new.size = node.size
			new.tween_duration = node.tween_duration
			new.tween_trans = node.tween_trans
			new.anchor = node.anchor
			new.fake_offset_x = node.fake_offset_x
			new._normal_regions = node._normal_regions
		elif new is FakableButton:
			new.current_state = node.current_state
			new.max_interact_times = node.max_interact_times
			new.tooltip_content = node.tooltip_content
			new.tooltip_offset = node.tooltip_offset
	elif new is ButtonController:
		for button in node.buttons:
			if button:
				new.buttons.append(copy(button))
			else:
				new.buttons.append(button)
		for wall in node.walls:
			if wall:
				new.walls.append(copy(wall))
			else:
				new.walls.append(wall)
		new.size_on = node.size_on
		new.size_off = node.size_off

	return new
