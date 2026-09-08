extends Node
## ============================================================
## EventSystem —— 简单数据驱动剧情事件系统（Godot 4.x）
##
## 用法：
##   1. 项目设置 → 自动加载（Autoload）注册本脚本，名字叫 EventSystem
##   2. 关卡脚本里：await EventSystem.run(script, self)
##   3. 关卡提供 actors 映射：var actors = {"player": %player, "dolos": %Dolos_Black}
##
## 设计思路：
##   - 事件 = 数据（Array[Dictionary]），每步一个字典，不写死在代码逻辑里
##   - 执行器 = run()，用指令指针 IP 顺序执行，await 对话/等待
##   - 分支 = branch（条件跳转）+ label（标记）+ jump（跳转）+ choice（玩家选择）
##   - 状态 = flags（布尔标记）/ variables（变量），跨关卡共享
## ============================================================

## ---------- 全局剧情状态（跨关卡共享） ----------
var flags := {}          # 布尔标记：set_flag("level2_reacted")
var variables := {}      # 数值/字符串变量：set_var("interacts", 3)

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
	var labels: Dictionary = _collect_labels(script)
	var ip := 0
	var guard := 0
	while ip < script.size():
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
						step.get("target", Vector2.ZERO),
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
			"end":
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
	if name_ == "" or ctx == null:
		return null
	var mapping: Variant = ctx.get("actors")
	if mapping is Dictionary and mapping.has(name_):
		return mapping[name_]
	var n: Node = ctx.get_node_or_null("%" + name_)
	if n:
		return n
	return ctx.get_node_or_null(name_)
