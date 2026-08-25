class_name SFX
extends Node

## 播放音效并随机变调
## player: AudioStreamPlayer 或 AudioStreamPlayer2D
## pitch_range: 音调浮动范围，默认 ±10%
static func play_with_pitch(player: Node, pitch_range: float = 0.1) -> void:
	if not player:
		push_warning("SFX.play_with_pitch: player 为空")
		return
	
	var base_pitch := 1.0
	var variation := randf_range(-pitch_range, pitch_range)
	
	# 同时兼容 2D 和普通播放器
	if player is AudioStreamPlayer:
		player.pitch_scale = base_pitch + variation
		player.play()
	elif player is AudioStreamPlayer2D:
		player.pitch_scale = base_pitch + variation
		player.play()
	else:
		push_warning("SFX.play_with_pitch: %s 不是有效的音频播放器" % player.name)

## 如果需要指定具体范围而不是浮动比例
static func play(player: Node, pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	if not player:
		return
	
	var p = randf_range(pitch_min, pitch_max)
	
	if player is AudioStreamPlayer or player is AudioStreamPlayer2D:
		player.pitch_scale = p
		player.play()
