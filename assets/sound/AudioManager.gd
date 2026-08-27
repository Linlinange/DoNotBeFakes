# class_name AudioManager
extends Node2D

var cache: Dictionary[String, AudioStream] = {
	"item_button"	= preload("res://assets/sound/item_button.ogg"),
	"ui_button"		= preload("res://assets/sound/ui_button.ogg"),
}

var _pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	if TransitionManager:
		TransitionManager.add_exemption(self)

## 播放音效: 
func play_sfx(stream: String, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	# 找一个空闲的复用，没有就新建
	var player: AudioStreamPlayer = null
	for p in _pool:
		if not p.is_playing():
			player = p
			break
	
	if player == null:
		player = AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	
	if not cache.has(stream):
		push_error("音效未缓存: " + stream)
		return
	
	player.stream = cache[stream]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	return player

## 以随机音高范围播放音效: 
func play_sfx_rpitch(stream: String, volume_db: float = 0.0, pitch_min: float = 0.9, pitch_max: float = 1.1) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = null
	for p in _pool:
		if not p.is_playing():
			player = p
			break
	
	if player == null:
		player = AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	
	if not cache.has(stream):
		push_error("音效未缓存: " + stream)
		return
	
	player.stream = cache[stream]
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()
	return player

## 播放2d音效: 
func play_sfx_2d(stream: String, pos: Vector2, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.global_position = pos
	get_tree().root.add_child(player)  # 挂到根节点，切换场景不影响

	if not cache.has(stream):
		push_error("音效未缓存: " + stream)
		return

	player.stream = cache[stream]
	player.volume_db = volume_db
	player.play()
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	return player
