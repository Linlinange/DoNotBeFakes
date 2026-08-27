extends CanvasLayer

@onready var tr_bar: CanvasLayer = $top_right
@onready var center_bar: CanvasLayer = $center
@onready var pause: Button = $top_right/HBoxContainer/pause_button
@onready var contin: Button = $center/CenterContainer/VBoxContainer/continue_button

func _ready() -> void:
	if BgmManager:
		if not BgmManager.is_playing_bgm("res://assets/music/level.mp3"):
			BgmManager.play_bgm("res://assets/music/level.mp3")
	pause.pressed.connect(_on_pause)
	contin.pressed.connect(_on_continue)
	if TransitionManager:
		TransitionManager.add_exemption(tr_bar)
		TransitionManager.add_exemption(center_bar)
	return

func _on_pause() -> void:
	tr_bar.visible =  false
	center_bar.visible =  true
	return

func _on_continue() -> void:
	tr_bar.visible =  true
	center_bar.visible =  false
	return
