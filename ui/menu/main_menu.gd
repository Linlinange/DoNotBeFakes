extends Control


func _ready() -> void:
	if not BgmManager.is_playing_bgm("res://assets/music/main.mp3"):
		BgmManager.play_bgm("res://assets/music/main.mp3")
