class_name InteractComponent
extends Area2D

# ========== 节点 ==========
@onready var tooltip: RichTextLabel = $tooltip

# ========== 配置 ==========
## 交互按键映射名
@export var input_action: StringName = "interact"
## 最大交互次数: -1表示无限。
@export var max_interact_times: int = -1

@export_group("提示配置")
## 提示内容
@export var tooltip_content: String = "按%s交互" % InputManager.get_key_name("interact"):
	set(value):
		tooltip_content = value
		if tooltip:
			tooltip.text = value
## 提示偏移
@export var tooltip_offset: Vector2 = Vector2(0, -32)

@export_group("范围检测")
## 是否同时检测 Area2D 类型的对象: 若为true，检测Body2D对象的同时，还检测Area2D对象
@export var detect_area: bool = false
## 检测对象所属组名
@export var detect_group: StringName = "interactable"

# ========== 状态 ==========
var object_in_range: bool = false
var interact_times: int = 0
var _externally_enabled: bool = true  ## 外界通过 set_interactable() 控制


# ========== 信号 ==========
signal interacted               ## 成功交互: 可用connect挂载交互后执行的函数
signal interact_rejected(reason: String)  ## 交互被拒绝（带原因）
signal object_entered           ## 对象进入交互范围
signal object_exited            ## 对象离开交互范围


func _ready() -> void:
	if tooltip:
		tooltip.text = tooltip_content
		tooltip.visible = false
		tooltip.global_position = _calculate_tooltip_position()
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if detect_area:
		area_entered.connect(_on_area_entered)
		area_exited.connect(_on_area_exited)


func _process(_delta: float) -> void:
	if not tooltip:
		return
	tooltip.visible = object_in_range and can_interact()
	tooltip.global_position = _calculate_tooltip_position()
	
	if Input.is_action_just_pressed(input_action):
		try_interact()


# ========== 公共方法 ==========

## 尝试交互（内部调用或外部手动触发）
func try_interact() -> void:
	if not can_interact():
		var reason = _get_reject_reason()
		interact_rejected.emit(reason)
		if reason == "已达交互上限":
			tooltip.text = reason
		return
	
	if interact_times < 2**31-1:
		interact_times += 1
	interacted.emit()

## 检查当前是否可以交互:
## 内部条件（范围、次数） + 外部条件（宿主控制）
func can_interact() -> bool:
	if not object_in_range:
		return false
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

# ========== 私有方法 ==========

func _calculate_tooltip_position() -> Vector2:
	# 默认公式，子类或宿主可通过覆盖/脚本调整
	var parent = get_parent()
	if is_instance_of(parent, Node2D):
		return parent.global_position - tooltip.size/2*tooltip.scale + tooltip_offset
	else:
		return self.global_position - tooltip.size/2*tooltip.scale + tooltip_offset


func _get_reject_reason() -> String:
	if not object_in_range:
		return "不在范围内"
	if max_interact_times >= 0 and interact_times >= max_interact_times:
		return "已达交互上限"
	if not _externally_enabled:
		return "当前不可用"
	return "未知原因"


# ========== 范围检测 ==========

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(detect_group):
		object_in_range = true
		object_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(detect_group):
		object_in_range = false
		object_exited.emit()

func _on_area_entered(area: Node2D) -> void:
	if area.is_in_group(detect_group):
		object_in_range = true
		object_entered.emit()

func _on_area_exited(area: Node2D) -> void:
	if area.is_in_group(detect_group):
		object_in_range = false
		object_exited.emit()
