extends Control

@onready var my_button = $Button

func _ready():
	my_button.pressed.connect(_on_my_button_pressed)

func _on_my_button_pressed():
	print("按钮被点击了！")
