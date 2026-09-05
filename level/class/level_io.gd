class_name LevelIO
## 关卡文件读写：LevelData <-> JSON 文件。
## 默认存 user://levels/ 下；调试时可传任意路径。
##
## 注意：JSON 数字解析后一律是 float（Godot JSON.parse_string 行为），
## 所有从 JSON 读出的数字都必须用 int() 显式转回整数，不要直接比较。

const LEVEL_DIR := "user://levels"
const EXT := ".json"

## 保存。path 留空按 id 生成默认路径。成功返回 OK。
static func save_level(level: LevelData, path: String = "") -> Error:
	if level.id.is_empty():
		push_error("LevelIO: 关卡缺少 id，无法确定保存路径")
		return ERR_INVALID_DATA

	var final_path := path if path != "" else default_path(level.id)

	var err := DirAccess.make_dir_recursive_absolute(final_path.get_base_dir())
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("LevelIO: 无法创建目录：%s (err=%d)" % [final_path.get_base_dir(), err])
		return err

	var file := FileAccess.open(final_path, FileAccess.WRITE)
	if file == null:
		var fe := FileAccess.get_open_error()
		push_error("LevelIO: 无法写入 %s (err=%d)" % [final_path, fe])
		return fe

	file.store_string(JSON.stringify(level.to_dict(), "  "))
	file.close()
	return OK

## 加载。成功返回 LevelData，失败返回 null（原因在日志）。
static func load_level(path: String) -> LevelData:
	if not FileAccess.file_exists(path):
		push_error("LevelIO: 文件不存在：%s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var fe := FileAccess.get_open_error()
		push_error("LevelIO: 无法读取 %s (err=%d)" % [path, fe])
		return null

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("LevelIO: JSON 解析失败：%s" % path)
		return null
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("LevelIO: 关卡文件根节点必须是对象：%s" % path)
		return null

	# 版本兼容检查
	var declared: Variant = parsed.get("format_version", LevelData.FORMAT_VERSION)
	if not _version_ok(declared, LevelData.FORMAT_VERSION):
		push_error("LevelIO: 版本不兼容。文件声明 %s，当前代码支持 %d" % [str(declared), LevelData.FORMAT_VERSION])
		return null

	return LevelData.from_dict(parsed)

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

## 根据 id 生成默认路径
static func default_path(level_id: String) -> String:
	return "%s/%s%s" % [LEVEL_DIR, level_id, EXT]
