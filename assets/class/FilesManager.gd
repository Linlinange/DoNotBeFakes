class_name FilesManager
extends RefCounted


## 路径
const Path: Dictionary = {
	"USERDATA": "userdata",
	"CLUES": "userdata/clues.json",
	"LEVEL": "level"
}

## 旧版本路径: 需要通过 new()实例化 FilesManager 来访问
var FormerlyPath: Dictionary = {
	"CLUES": [ProjectSettings.globalize_path("user://").get_base_dir().get_base_dir()+"/Godot/app_userdata/2026-0XGJ/DoNotBeFakes/clues.json"]
}


## 从 绝对路径 读取 JSON。返回字典。文件不存在或解析失败返回空字典。此方法仅用于兼容旧版本存档继承。
static func abs_json_read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("FilesManager 读取失败 [%s]: %d" % [path, FileAccess.get_open_error()])
		return {}
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FilesManager JSON 解析失败 [%s]: %s (line %d)" % [path, json.get_error_message(), json.get_error_line()])
		return {}
	
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("FilesManager 根节点不是字典 [%s]" % path)
		return {}
	
	return json.data

## 从 user:// 下的相对路径读取 JSON，返回字典。文件不存在或解析失败返回空字典。
static func json_read(path: String) -> Dictionary:
	var full_path := "user://%s" % path
	
	if not FileAccess.file_exists(full_path):
		return {}
	
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		push_error("FilesManager 读取失败 [%s]: %d" % [full_path, FileAccess.get_open_error()])
		return {}
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FilesManager JSON 解析失败 [%s]: %s (line %d)" % [full_path, json.get_error_message(), json.get_error_line()])
		return {}
	
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("FilesManager 根节点不是字典 [%s]" % full_path)
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
		push_error("FilesManager 写入失败 [%s]: %d" % [full_path, FileAccess.get_open_error()])
		return false
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


# ============================================================
# 关卡文件读写（由 LevelIO 合并而来）
# ============================================================
## 关卡默认目录（user:// 下相对路径）与扩展名
const LEVEL_DIR := "level"
const LEVEL_EXT := ".json"

## 保存关卡（LevelData -> JSON 文件）。
## path 留空按 id 生成默认路径（user://level/<id>.json）；传任意可写路径则存到该路径。
## 成功返回 OK。
static func save_level(level: LevelData, path: String = "", warn: bool = true) -> Error:
	if level.id.is_empty():
		if warn:
			push_error("FilesManager: 关卡缺少 id，无法确定保存路径")
		return ERR_INVALID_DATA
	
	var final_path := path if path != "" else level_default_path(level.id)
	
	var err := DirAccess.make_dir_recursive_absolute(final_path.get_base_dir())
	if err != OK and err != ERR_ALREADY_EXISTS:
		if warn:
			push_error("FilesManager: 无法创建目录：%s (err=%d)" % [final_path.get_base_dir(), err])
		return err
	
	var file := FileAccess.open(final_path, FileAccess.WRITE)
	if file == null:
		var fe := FileAccess.get_open_error()
		if warn:
			push_error("FilesManager: 无法写入 %s (err=%d)" % [final_path, fe])
		return fe
	
	file.store_string(JSON.stringify(level.to_dict(), "  "))
	file.close()
	return OK

## 加载关卡（JSON 文件 -> LevelData）。
## path 为任意可读路径（res:// / user:// / 绝对路径）。成功返回 LevelData，失败返回 null（原因在日志）。
static func load_level(path: String, warn: bool = true) -> LevelData:
	if not FileAccess.file_exists(path):
		if warn:
			push_error("FilesManager: 关卡文件不存在：%s" % path)
		return null
	
	# 复用通用 JSON 读取；解析失败 / 根节点非字典时 abs_json_read 已打印日志并返回空字典
	var data := abs_json_read(path)
	if data.is_empty():
		return null
	
	# 版本兼容检查
	var declared: Variant = data.get("format_version", LevelData.FORMAT_VERSION)
	if not _version_ok(declared, LevelData.FORMAT_VERSION):
		if warn:
			push_error("FilesManager: 版本不兼容。文件声明 %s，当前代码支持 %d" % [str(declared), LevelData.FORMAT_VERSION])
		return null
	
	return LevelData.from_dict(data)

## 版本兼容：文件声明的 format_version 是否覆盖 supported。
## 支持三种写法：数字（JSON 解析后是 float，按 int 比较）；[min, max]；{min, max}
static func _version_ok(declared: Variant, supported: int) -> bool:
	if typeof(declared) == TYPE_INT or typeof(declared) == TYPE_FLOAT:
		return int(declared) == supported
	if typeof(declared) == TYPE_ARRAY:
		if declared.size() < 2:
			return false
		return supported >= int(declared[0]) and supported <= int(declared[1])
	if typeof(declared) == TYPE_DICTIONARY:
		var lo: int = int(declared.get("min", supported))
		var hi: int = int(declared.get("max", supported))
		return supported >= lo and supported <= hi
	return false

## 根据 id 生成默认路径（user://level/<id>.json）
static func level_default_path(level_id: String) -> String:
	return "user://%s/%s%s" % [LEVEL_DIR, level_id, LEVEL_EXT]
