extends Node
extends Node
## ============================================================
## EventSystem —— 简单数据驱动剧情事件系统（Godot 4.x）
## 精简版 + 剧本体检：
##   - 开演前自动检查一遍剧本（validate），把填错的参数一次性列到输出面板
##   - 检查发现问题只提示、不拦截：有问题的步骤自动跳过，游戏照常运行、不会崩
##
## 用法：
##   1. 项目设置 → 自动加载（Autoload）注册本脚本，名字叫 EventSystem
##   2. 关卡脚本里：await EventSystem.run(script, self)
##   3. 关卡提供 actors 映射：var actors = {"player": %player, "dolos": %Dolos_Black}
##   3. 关卡提供 actors 映射：var actors = {"player": %player, "dolos": %Dolos_Black}
##
## 设计思路：
##   - 事件 = 数据（Array[Dictionary]），每步一个字典，不写死在代码逻辑里
##   - 执行器 = run()，用指令指针 IP 顺序执行，await 对话/等待
##   - 分支 = branch（条件跳转）+ label（标记）+ jump（跳转）+ choice（玩家选择）
##   - 状态 = flags（布尔标记）/ variables（变量），跨关卡共享
## ============================================================

signal ended			## 事件以end结束时会发出的信号

## ---------- 支持的步骤类型（供剧本体检使用） ----------
const _STEP_TYPES := [
	"say", "speak", "shut_up", "move_to", "wait", "set",
	"set_flag", "set_var", "call", "call_actor",
	"label", "jump", "branch", "choice", "comment", "end", 
]

## ---------- 全局剧情状态（跨关卡共享） ----------
var flags := {}          ## 布尔标记：set_flag("level2_reacted")
var variables := {}      ## 数值/字符串变量：set_var("interacts", 3)

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func get_flag(key: String, default: bool = false) -> bool:
	return flags.get(key, default)

func set_var(key: String, value: Variant) -> void:
	variables[key] = value

func get_var(key: String, default: Variant = null) -> Variant:
	return variables.get(key, default)

func reset() -> void:
	flags.clear()
	variables.clear()


## ---------- 事件执行 ----------
## script: Array[Dictionary]，每个元素是一个步骤（见下）
## script: Array[Dictionary]，每个元素是一个步骤（见下）
## ctx:    执行上下文，通常是关卡根节点（提供 actors 映射 / 可调方法）
##
## 步骤类型：
##   say/speak/shut_up/move_to : 演员演出（say 会等待，speak 不等待）
##   wait                      : 等待 duration 秒
##   set                       : 设置某节点属性，如 player.movable
##   set_flag / set_var        : 写剧情状态
##   call / call_actor         : 调用关卡方法 / 演员方法
##   label / jump / branch     : 分支三件套
##   choice                    : 玩家选择分支（可选扩展）
##   end                       : 结束事件
func run(script: Array, ctx: Node = null) -> void:
	if not is_instance_valid(ctx):
		return
	
	_report_problems(validate(script, ctx))  # 剧本体检：填错的参数一次性列到输出面板
	var labels: Dictionary = _collect_labels(script)
	var ip := 0
	var guard := 0
	while ip < script.size():
		if not is_instance_valid(ctx):
			return
		guard += 1
		if guard > 10000:
			push_warning("EventSystem: 执行次数过多，疑似死循环，已中止")
			return
		var step: Dictionary = script[ip]
		match step.get("type", ""):
			"say":
				var n := _actor(step.get("actor", ""), ctx)
				if n and n.has_method("say"):
					await n.say(step.get("text", ""), step.get("duration", 3.0))
			"speak":
				var n := _actor(step.get("actor", ""), ctx)
				if n and n.has_method("speak"):
					n.speak(step.get("text", ""), step.get("duration", 5.0))
			"shut_up":
				var n := _actor(step.get("actor", ""), ctx)
				if n and n.has_method("shut_up"):
					n.shut_up()
			"move_to":
				var n := _actor(step.get("actor", ""), ctx)
				if n and n.has_method("move_to"):
					n.move_to(
						_to_vector2(step.get("target", Vector2.ZERO)),
						step.get("duration", 1.0),
						step.get("trans", Tween.TRANS_LINEAR))
			"wait":
				await get_tree().create_timer(step.get("duration", 1.0)).timeout
			"set":
				var n := _actor(step.get("target", ""), ctx)
				var prop: String = step.get("property", "")
				if n and prop != "":
					n.set(prop, step.get("value"))
			"set_flag":
				set_flag(step.get("key", ""), step.get("value", true))
			"set_var":
				set_var(step.get("key", ""), step.get("value"))
			"call":
				if ctx and ctx.has_method(step.get("method", "")):
					await ctx.callv(step.get("method", ""), step.get("args", []))
			"call_actor":
				var n := _actor(step.get("actor", ""), ctx)
				if n and n.has_method(step.get("method", "")):
					n.callv(step.get("method", ""), step.get("args", []))
			"label":
				pass  # 无操作，只是标记
			"jump":
				ip = _goto(labels, step.get("target", ""), ip)
				continue
			"branch":
				var hit: bool = _eval_condition(step.get("condition", {}), ctx)
				var tgt: String = step.get("target", "") if hit else step.get("else_target", "")
				if tgt != "":
					ip = _goto(labels, tgt, ip)
					continue
			"choice":
				await _do_choice(step, ctx)
				var tgt: String = variables.get("_choice_target", "")
				variables.erase("_choice_target")
				if tgt != "":
					ip = _goto(labels, tgt, ip)
					continue
			"comment", "print":  # 注释
				print(step.get("content", "无内容"))
			"end":
				ended.emit()
				return
		ip += 1


## ---------- 条件求值 ----------
## 支持的 op：
##   flag                : 检查标记，如 {op:"flag", key:"level2_reacted"}
##   var                 : 比较变量，如 {op:"var", key:"interacts", cmp:">=", value:1}
##   call                : 调用关卡方法返回 bool，如 {op:"call", method:"_is_pc"}
##   not / and / or      : 组合条件
func _eval_condition(cond: Variant, ctx: Node) -> bool:
	if cond == null:
		return true
	if cond is bool:
		return cond
	if cond is Dictionary:
		match cond.get("op", "flag"):
			"flag":
				var expected: bool = cond.get("value", true)
				return get_flag(cond.get("key", ""), false) == expected
			"var":
				var lhs: Variant = get_var(cond.get("key", ""))
				if lhs == null:
					return false  # 变量未设置 → 条件不成立
				return _compare(lhs, cond.get("value"), cond.get("cmp", "=="))
			"call":
				if ctx and ctx.has_method(cond.get("method", "")):
					return bool(ctx.callv(cond.get("method", ""), cond.get("args", [])))
				return false
			"not":
				return not _eval_condition(cond.get("cond", {}), ctx)
			"and":
				for c in cond.get("conds", []):
					if not _eval_condition(c, ctx):
						return false
				return true
			"or":
				for c in cond.get("conds", []):
					if _eval_condition(c, ctx):
						return true
				return false
	return false


func _compare(a: Variant, b: Variant, cmp: String) -> bool:
	match cmp:
		"==": return a == b
		"!=": return a != b
		">":  return a > b
		"<":  return a < b
		">=": return a >= b
		"<=": return a <= b
	push_warning("EventSystem: 未知比较符 '%s'" % cmp)
	return false


## ---------- 分支选择（可选扩展） ----------
## 关卡可以自定义选择 UI：实现 async func prompt_choice(prompt, options) -> int
## 或者连接本单例的 choice_requested 信号，把结果写回 variables["_choice_index"]
signal choice_requested(prompt: String, options: Array)

func _do_choice(step: Dictionary, ctx: Node) -> void:
	var prompt: String = step.get("prompt", "")
	var options: Array = step.get("options", [])
	var idx := 0
	if ctx and ctx.has_method("prompt_choice"):
		idx = await ctx.prompt_choice(prompt, options)
	elif choice_requested.get_connections().size() > 0:
		variables["_choice_index"] = -1
		choice_requested.emit(prompt, options)
		while variables.get("_choice_index", -1) == -1:
			await get_tree().process_frame
		idx = variables.get("_choice_index", 0)
		variables.erase("_choice_index")
	else:
		push_warning("EventSystem: 未提供 choice UI，默认选择第 0 项")
	var targets: Array = step.get("targets", [])
	if idx >= 0 and idx < targets.size():
		variables["_choice_target"] = targets[idx]


## ---------- 剧本体检（调试利器） ----------
## run() 会先自动执行一遍；也可以手动调用：EventSystem.validate(script, self)
## 返回问题列表（空数组 = 没发现问题）
## 发现的问题只提示、不拦截：有问题的步骤运行时自动跳过，游戏不崩溃
func validate(script: Array, ctx: Node = null) -> Array:
	var problems: Array = []
	var labels := {}
	for i in script.size():
		var step: Dictionary = script[i]
		var s_type: String = step.get("type", "")
		if s_type == "":
			problems.append("[第%d步] 缺少 type 字段" % (i + 1))
			continue
		if s_type not in _STEP_TYPES:
			problems.append("[第%d步] 未知 type：'%s'（可用：%s）" % [i + 1, s_type, "、".join(_STEP_TYPES)])
			continue
		if s_type == "label":
			var label_name: String = step.get("name", "")
			if label_name == "":
				problems.append("[第%d步] label 缺少 name" % (i + 1))
			elif labels.has(label_name):
				problems.append("[第%d步] label '%s' 重复定义" % [i + 1, label_name])
			else:
				labels[label_name] = i
		if ctx != null:
			# 只有这些字段是"节点引用"，才查演员；branch/jump 的 target 是 label，不查
			var node_keys: Array = []
			if s_type in ["say", "speak", "shut_up", "move_to", "call_actor"]:
				node_keys.append("actor")
			if s_type == "set":
				node_keys.append("target")
			for akey in node_keys:
				var aname: String = step.get(akey, "")
				if aname != "" and _actor(aname, ctx) == null:
					problems.append("[第%d步] 找不到演员/节点 '%s'（检查 actors 映射）" % [i + 1, aname])
		match s_type:
			"say", "speak", "shut_up", "move_to":
				if step.get("actor", "") == "":
					problems.append("[第%d步] %s 缺少 actor" % [i + 1, s_type])
				elif ctx != null:
					var an0 := _actor(step.get("actor", ""), ctx)
					if an0 != null and not an0.has_method(s_type):
						problems.append("[第%d步] 演员 '%s' 没有 %s() 方法" % [i + 1, step.get("actor", ""), s_type])
			"set":
				var n := _actor(step.get("target", ""), ctx)
				var prop: String = step.get("property", "")
				if prop == "":
					problems.append("[第%d步] set 缺少 property" % (i + 1))
				elif n != null and not (prop in n):
					problems.append("[第%d步] set 的属性 '%s' 在节点上不存在" % [i + 1, prop])
			"call":
				var m: String = step.get("method", "")
				if m == "":
					problems.append("[第%d步] call 缺少 method" % (i + 1))
				elif ctx == null:
					problems.append("[第%d步] call 需要传入关卡 ctx 才能执行" % (i + 1))
				elif not ctx.has_method(m):
					problems.append("[第%d步] call 的方法 '%s' 在关卡里不存在" % [i + 1, m])
			"call_actor":
				var an2 := _actor(step.get("actor", ""), ctx)
				var m2: String = step.get("method", "")
				if m2 == "":
					problems.append("[第%d步] call_actor 缺少 method" % (i + 1))
				elif an2 != null and not an2.has_method(m2):
					problems.append("[第%d步] call_actor 的方法 '%s' 不存在" % [i + 1, m2])
			"branch":
				_validate_condition(step.get("condition", {}), ctx, i, problems)
				if step.get("target", "") == "" and step.get("else_target", "") == "":
					problems.append("[第%d步] branch 没有 target 也没有 else_target" % (i + 1))
			"choice":
				var opts: Array = step.get("options", [])
				var tgts: Array = step.get("targets", [])
				if opts.is_empty():
					problems.append("[第%d步] choice 没有 options" % (i + 1))
				if tgts.size() != opts.size():
					problems.append("[第%d步] choice 的 targets 数量(%d) 和 options 数量(%d) 不一致" % [i + 1, tgts.size(), opts.size()])
	for i in script.size():
		var step: Dictionary = script[i]
		var t: String = step.get("type", "")
		if t in ["jump", "branch"]:
			for tk in ["target", "else_target"]:
				var tgt: String = step.get(tk, "")
				if tgt != "" and not labels.has(tgt):
					problems.append("[第%d步] %s 指向不存在的 label：'%s'" % [i + 1, tk, tgt])
	return problems


func _validate_condition(cond: Variant, ctx: Node, step_idx: int, problems: Array) -> void:
	if cond == null or cond is bool:
		return
	if cond is Array:
		for c in cond:
			_validate_condition(c, ctx, step_idx, problems)
		return
	if cond is Dictionary:
		var op: String = cond.get("op", "flag")
		if op not in ["flag", "var", "call", "not", "and", "or"]:
			problems.append("[第%d步] 未知条件 op：'%s'（可用：flag / var / call / not / and / or）" % [step_idx + 1, op])
			return
		match op:
			"flag":
				if cond.get("key", "") == "":
					problems.append("[第%d步] flag 条件缺少 key" % (step_idx + 1))
			"var":
				if cond.get("key", "") == "":
					problems.append("[第%d步] var 条件缺少 key" % (step_idx + 1))
				if cond.get("cmp", "==") not in ["==", "!=", ">", "<", ">=", "<="]:
					problems.append("[第%d步] var 条件未知比较符 '%s'" % [step_idx + 1, cond.get("cmp", "==")])
			"call":
				var m: String = cond.get("method", "")
				if m == "":
					problems.append("[第%d步] 条件 call 缺少 method" % (step_idx + 1))
				elif ctx == null:
					problems.append("[第%d步] 条件 call 需要传入关卡 ctx 才能执行" % (step_idx + 1))
				elif not ctx.has_method(m):
					problems.append("[第%d步] 条件 call 的方法 '%s' 在关卡里不存在" % [step_idx + 1, m])
			"not":
				_validate_condition(cond.get("cond", {}), ctx, step_idx, problems)
			"and", "or":
				var cs: Array = cond.get("conds", [])
				if cs.is_empty():
					problems.append("[第%d步] %s 条件没有 conds" % [step_idx + 1, op])
				for c in cs:
					_validate_condition(c, ctx, step_idx, problems)


func _report_problems(problems: Array) -> void:
	if problems.is_empty():
		return
	push_warning("EventSystem: 剧本体检发现 %d 个问题：" % problems.size())
	for p in problems:
		push_warning("  - " + str(p))


## ---------- 内部工具 ----------
func _collect_labels(script: Array) -> Dictionary:
	var labels := {}
	for i in script.size():
		var step: Dictionary = script[i]
		if step.get("type", "") == "label":
			labels[step.get("name", "")] = i
	return labels

func _goto(labels: Dictionary, target: String, ip: int) -> int:
	if labels.has(target):
		return labels[target]
	push_warning("EventSystem: 找不到标签 '%s'" % target)
	return ip + 1

## 演员解析：先查 ctx.actors 映射 → 再试 %唯一名 → 再试普通路径
func _actor(name_: String, ctx: Node) -> Node:
	if not is_instance_valid(ctx):
		return null
	if name_ == "" or ctx == null:
		return null
	var mapping: Variant = ctx.get("actors")
	if mapping is Dictionary and mapping.has(name_):
		return mapping[name_]
	var n: Node = ctx.get_node_or_null("%" + name_)
	if mapping is Dictionary and mapping.has(name_):
		return mapping[name_]
	var n: Node = ctx.get_node_or_null("%" + name_)
	if n:
		return n
	return ctx.get_node_or_null(name_)

## 坐标归一化：把外部数据里的坐标写法统一成 Vector2
## 支持：Vector2 / [x, y] / {"x":.., "y":..}
func _to_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(value[0], value[1])
	if value is Dictionary:
		return Vector2(value.get("x", 0.0), value.get("y", 0.0))
	return Vector2.ZERO
