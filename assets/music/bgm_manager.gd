class_name BGMManager
extends AudioStreamPlayer

@export var fade_duration: float = 0.8

var _tween: Tween

## 切换 BGM，同一首歌不重复播放
func play_bgm(path: String, from_start: bool = true) -> void:
	var new_stream = load(path) as AudioStream
	if not new_stream:
		push_warning("BGM 加载失败: %s" % path)
		return
	
	# 同一首歌且正在播，就不从头切了
	if stream == new_stream and playing and not from_start:
		return
	
	# 如果有正在播的，先淡出
	if playing:
		_fade_out_and_switch(new_stream, from_start)
	else:
		_play_new(new_stream, from_start)

## 停止 BGM（带淡出）
func stop_bgm() -> void:
	if not playing:
		return
	_fade_volume(-80, fade_duration, true)

## 返回当前正在播放的 BGM 路径，没播放返回 ""
func get_current_bgm() -> String:
	if stream:
		return stream.resource_path
	return ""

## 检查当前是否正在播放指定路径的 BGM
func is_playing_bgm(path: String) -> bool:
	return playing and stream != null and stream.resource_path == path

## 内部：直接播放新音乐
func _play_new(new_stream: AudioStream, from_start: bool) -> void:
	stream = new_stream
	volume_db = -80  # 从静音开始
	play()
	if not from_start:
		seek(0.0)
	_fade_volume(0, fade_duration)

## 内部：淡出后切换
func _fade_out_and_switch(new_stream: AudioStream, from_start: bool) -> void:
	_fade_volume(-80, fade_duration / 2, true)
	await _tween.finished
	_play_new(new_stream, from_start)

## 内部：音量渐变
func _fade_volume(target_db: float, duration: float, stop_after: bool = false) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "volume_db", target_db, duration)
	
	if stop_after:
		_tween.finished.connect(stop, CONNECT_ONE_SHOT)
