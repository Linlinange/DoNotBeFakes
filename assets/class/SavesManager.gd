class_name SavesManager
extends RefCounted


## 路径
const Path: Dictionary = {
	"USERDATA": "userdata",
	"CLUES": "userdata/clues.json"
}

## 旧版本路径: 需要通过 new()实例化SavesManager 来访问
var FormerlyPath: Dictionary = {
	"CLUES": [ProjectSettings.globalize_path("user://").get_base_dir().get_base_dir()+"/Godot/app_userdata/2026-0XGJ/DoNotBeFakes/clues.json"]
}


## 从 绝对路径 读取 JSON。返回字典。文件不存在或解析失败返回空字典。此方法仅用于兼容旧版本存档继承。
static func abs_json_read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SavesManager 读取失败 [%s]: %d" % [path, FileAccess.get_open_error()])
		return {}
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SavesManager JSON 解析失败 [%s]: %s (line %d)" % [path, json.get_error_message(), json.get_error_line()])
		return {}
	
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SavesManager 根节点不是字典 [%s]" % path)
		return {}
	
	return json.data

## 从 user:// 下的相对路径读取 JSON，返回字典。文件不存在或解析失败返回空字典。
static func json_read(path: String) -> Dictionary:
	var full_path := "user://%s" % path
	
	if not FileAccess.file_exists(full_path):
		return {}
	
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		push_error("SavesManager 读取失败 [%s]: %d" % [full_path, FileAccess.get_open_error()])
		return {}
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SavesManager JSON 解析失败 [%s]: %s (line %d)" % [full_path, json.get_error_message(), json.get_error_line()])
		return {}
	
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SavesManager 根节点不是字典 [%s]" % full_path)
		return {}
	
	return json.data

## 将字典写入 user:// 下的相对路径。自动创建父目录。
static func json_write(path: String, data: Dictionary) -> bool:
	var full_path := "user://%s" % path
	
	# 自动创建父目录
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive(full_path.get_base_dir())
	
	var file := FileAccess.open(full_path, FileAccess.WRITE)
	if not file:
		push_error("SavesManager 写入失败 [%s]: %d" % [full_path, FileAccess.get_open_error()])
		return false
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true
