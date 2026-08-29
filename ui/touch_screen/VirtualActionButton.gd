extends Button


@export var action_name: StringName = ""
@export var icon_up: Texture2D = null
@export var icon_down: Texture2D = null

func _ready() -> void:
	if icon_up == null:
		icon_up = self.icon
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	toggled.connect(_on_toggled)
	return


func _on_down() -> void:
	Input.action_press(action_name, 0.5)
	return

func _on_up() -> void:
	Input.action_release(action_name)
	return

func _on_toggled(press: bool) -> void:
	if press:
		if icon_down != null:
			self.icon = icon_down
	else:
		if icon_up != null:
			self.icon = icon_up
	Input.action_press(action_name, 0.5)
	return
