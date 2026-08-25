class_name FakableObject
extends CollisionObject2D

## 虚态时的视觉表现方式
enum VisualMode {
	TRANSPARENT,  ## 半透明: 修改 modulate.a
	HIDDEN,       ## 完全隐藏: 修改 visible
	CUSTOM        ## 完全自定义: 子类重写 _on_apply_fake / _on_apply_real
}

# ========== 核心属性 ==========

## 虚假值: 为true时，对象失去核心功能
@export var fake: bool = false:
	set(v):
		if (not fakable) and is_node_ready():
			return
		if fake == v:
			return
		fake = v
		if is_node_ready():
			_update_fake()

## 可造假值: 为true时，虚假值可在运行时被动态更改
@export var fakable: bool = false

## 虚态视觉模式: 在编辑器里选，子类也可代码覆盖
@export var visual_mode: VisualMode = VisualMode.TRANSPARENT

## 虚态透明度: 仅 TRANSPARENT 模式有效，0=完全透明
@export_range(0.0, 1.0) var fake_alpha: float = 0.0

## 虚态碰撞层: -1表示"不改变"，保持实态时的碰撞层
@export var fake_collision_layer: int = -1

# ========== 内部状态 ==========

## 缓存实态时的碰撞层
@onready var _normal_collision_layer: int = collision_layer


func _ready() -> void:
	_update_fake()


# ========== 核心方法 ==========

## 更新虚态/实态的视觉与物理表现
# 子类一般不需要重写这个，去重写下面的钩子
func _update_fake() -> void:
	if fake:
		_apply_fake_appearance()
		# -1值时，不切换碰撞层
		if fake_collision_layer != -1:
			collision_layer = fake_collision_layer
	else:
		_apply_real_appearance()
		# 实态时总是恢复为最初缓存的正常层
		collision_layer = _normal_collision_layer
	
	_on_fake_updated()


## 应用虚态视觉表现
func _apply_fake_appearance() -> void:
	# print("_apply_fake_appearance")
	match visual_mode:
		VisualMode.TRANSPARENT:
			if self is CanvasItem:
				self.modulate.a = fake_alpha
		VisualMode.HIDDEN:
			if self is CanvasItem:
				self.visible = false
		VisualMode.CUSTOM:
			_on_apply_fake()


## 应用实态视觉表现
func _apply_real_appearance() -> void:
	# print("_apply_real_appearance")
	match visual_mode:
		VisualMode.TRANSPARENT:
			if self is CanvasItem:
				self.modulate.a = 1.0
		VisualMode.HIDDEN:
			if self is CanvasItem:
				self.visible = true
		VisualMode.CUSTOM:
			_on_apply_real()


# 子类在交互前可以用这个判断，不用自己写 `if not fake`
## 检查当前是否处于可用（实态）状态
func is_functional() -> bool:
	return not fake


# ========== 子类可重写钩子 ==========

# 例如 Wall 的纹理偏移
## CUSTOM 模式下的虚态表现
func _on_apply_fake() -> void:
	pass

# 例如 Wall 恢复原始纹理
## CUSTOM 模式下的实态表现
func _on_apply_real() -> void:
	pass

# 例如 Clue 在这里隐藏对话气泡
## 每次 fake 状态更新后调用
func _on_fake_updated() -> void:
	pass
