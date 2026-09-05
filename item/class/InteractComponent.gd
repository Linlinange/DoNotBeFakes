class_name InteractComponent
extends Area2D


## 交互角色
enum Role {
	INTERACTOR,		## 只能主动交互
	INTERACTEE,		## 只能被交互
	BOTH			## 两者皆可
}

@onready var tooltip: RichTextLabel = $tooltip
@onready var _original_rotation: float = tooltip.rotation	## 记录初始旋转角

## 最大交互次数: -1表示无限。
@export var max_interact_times: int = -1
## 交互角色
@export var role: Role = Role.INTERACTEE
## 提示内容
@export var tooltip_content: String = "按%s交互" % InputManager.get_key_name("interact"):
	set(value):
		tooltip_content = value
		if tooltip:
			tooltip.text = value
## 提示偏移
@export var tooltip_offset: Vector2 = Vector2(0, -32)
## 提示时检测的对象所属组名
@export var detect_group: StringName = "interactable"

# ========== 状态 ==========
var comps_in_range: Array[InteractComponent] = []	## 在范围内的组件
var current_target: InteractComponent = null		## 被交互目标
var objects_in_range: Array[CollisionObject2D] = []	## 处于范围内的需要提示的对象
var interact_times: int = 0					## 交互次数
var _externally_enabled: bool = true  		## 能否交互: false时，无法交互，也无法被交互。可通过 set_interactable() 控制


# ========== 信号 ==========
signal interacted			## 成功交互或被交互: 可用connect挂载交互后执行的函数
signal interact_rejected(reason: String)	## 无法交互或被拒绝交互（带原因）


# ========== 继承方法 ==========

func _ready() -> void:
	if tooltip:
		tooltip.text = tooltip_content
		tooltip.visible = false
		tooltip.global_position = _calculate_tooltip_position()
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _process(_delta: float) -> void:
	if not tooltip:
		return
	tooltip.visible = not objects_in_range.is_empty() and can_interact() and role!=Role.INTERACTOR
	tooltip.global_position = _calculate_tooltip_position()


# ========== 公共方法 ==========

## 尝试交互:
	## INTERACTOR 获取被交互目标，并令其interact()
	## 优先以current_target为被交互目标，为空则遍历并获取优先的
	## 成功或失败都发出信号
func try_interact() -> bool:
	# 检查自身是否允许主动交互
	if role == Role.INTERACTEE:
		interact_rejected.emit("当前角色无法主动交互")
		return false
	
	# 检查自身交互条件
	if not can_interact():
		interact_rejected.emit(_get_reject_reason())
		return false
	
	# 确定目标
	var target: InteractComponent = null
	if current_target != null and is_instance_valid(current_target) \
			and current_target in comps_in_range and current_target._can_be_interacted():
		target = current_target
	else:
		var valid_targets := _get_valid_targets()
		if valid_targets.size() > 0:
			target = valid_targets[0]
	if target == null:
		interact_rejected.emit("范围内无有效交互目标")
		return false
	
	# 尝试让目标响应交互
	var success = target.reply_interact()
	if success:
		interact_times += 1
		interacted.emit()
		return true
	return false


## 回复交互:
	## INTERACTEE 检查交互条件并交互
	## 成功或失败都发出信号
	## 成功时返回true，否则返回false
func reply_interact() -> bool:
	# 检查自身是否允许被交互
	if role == Role.INTERACTOR:
		interact_rejected.emit("当前角色无法被交互")
		return false
	
	# 检查交互条件
	if not can_interact():
		interact_rejected.emit(_get_reject_reason())
		return false
	
	interact_times += 1
	interacted.emit()
	return true


## 切换下一个被交互目标: 
## 仅存在多个符合条件的目标时有效，当前为空则获取第一个
func next_target() -> void:
	var valid_targets := _get_valid_targets()
	if valid_targets.size() == 0:
		current_target = null
		return
	
	if current_target == null or not is_instance_valid(current_target) \
			or not current_target in valid_targets:
		current_target = valid_targets[0]
	else:
		var idx := valid_targets.find(current_target)
		idx = (idx + 1) % valid_targets.size()
		current_target = valid_targets[idx]


## 切换上一个被交互目标: 
## 仅存在多个符合条件的目标时有效，当前为空则获取最后一个
func last_target() -> void:
	var valid_targets := _get_valid_targets()
	if valid_targets.size() == 0:
		current_target = null
		return
	
	if current_target == null or not is_instance_valid(current_target) \
			or not current_target in valid_targets:
		current_target = valid_targets[-1]
	else:
		var idx := valid_targets.find(current_target)
		idx = (idx - 1 + valid_targets.size()) % valid_targets.size()
		current_target = valid_targets[idx]


## 检查当前是否可以被交互:
	## 内部条件（次数） + 外部条件（宿主控制）
func can_interact() -> bool:
	if max_interact_times >= 0 and interact_times >= max_interact_times:
		return false
	if not _externally_enabled:
		return false
	return true

## 启用/禁用交互:
	## 用于虚态屏蔽、过渡保护、剧情锁定等
func set_interactable(enabled: bool) -> void:
	_externally_enabled = enabled

## 查询交互次数
func get_interact_times() -> int:
	return interact_times

## 重置交互次数
func reset_interact_times() -> void:
	interact_times = 0

## 设置提示内容
func set_tooltip_content(content: String) -> void:
	tooltip_content = content
	if tooltip:
		tooltip.text = content


## 恢复初始旋转: 
## inherit 为true时, 忽略父节点。
## 该方法常用于不希望提示文字跟随父节点的情况，调用此方法之后通常会配合设置tooltip_offset(提示偏移)以达到预期位置。
func reset_rotation(inherit: bool) -> bool:
	tooltip.rotation = self._original_rotation
	if not inherit:
		var parent = self.get_parent()
		if is_instance_of(parent, Node2D):
			tooltip.rotation -= parent.rotation
			return true
	else:
		return true
	return false

# ========== 私有方法 ==========

func _calculate_tooltip_position() -> Vector2:
	# 默认公式，子类或宿主可通过覆盖/脚本调整
	var parent = get_parent()
	if is_instance_of(parent, Node2D):
		return parent.global_position - tooltip.size/2*tooltip.scale + tooltip_offset
	else:
		return self.global_position - tooltip.size/2*tooltip.scale + tooltip_offset

## 获取拒绝原因
func _get_reject_reason() -> String:
	if max_interact_times >= 0 and interact_times >= max_interact_times:
		return "已达交互上限"
	if not _externally_enabled:
		return "当前不可用"
	return "未知原因"

## 获取可作为被交互目标的有效组件列表（按距离升序）
func _get_valid_targets() -> Array[InteractComponent]:
	var result: Array[InteractComponent] = []
	for comp in comps_in_range:
		if not is_instance_valid(comp):
			continue
		if comp._can_be_interacted():
			result.append(comp)
	
	result.sort_custom(func(a: InteractComponent, b: InteractComponent) -> bool:
		var dist_a := self.global_position.distance_squared_to(a.global_position)
		var dist_b := self.global_position.distance_squared_to(b.global_position)
		return dist_a < dist_b
	)
	return result

## 检查该组件当前是否可以作为被交互目标
func _can_be_interacted() -> bool:
	if role == Role.INTERACTOR:
		return false
	return can_interact()


# ---------- 范围检测 ----------

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(detect_group):
		objects_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(detect_group):
		objects_in_range.remove_at(objects_in_range.find(body))

func _on_area_entered(area: Node2D) -> void:
	if area.is_in_group(detect_group):
		objects_in_range.append(area)
	if area is InteractComponent:
		var comp := area as InteractComponent
		if not comp in comps_in_range:
			comps_in_range.append(comp)
		# 若当前目标已不在范围内或已失效，清空
		if current_target != null and (not is_instance_valid(current_target) or not current_target in comps_in_range):
			current_target = null

func _on_area_exited(area: Node2D) -> void:
	if area.is_in_group(detect_group):
		objects_in_range.remove_at(objects_in_range.find(area))
	if area is InteractComponent:
		var comp := area as InteractComponent
		comps_in_range.erase(comp)
		if current_target == comp:
			current_target = null
