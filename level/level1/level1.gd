extends Node2D
## 示例：level1 用事件系统改写

@onready var player: Player = %player
@onready var dolos: NPC = %Dolos_Black
@onready var a1: Area2D = $area_open_door
@onready var a2: Area2D = $area_exit

var actors := {}  # 在 _ready 中填：演员名字 → 节点

## 开场剧情：事件脚本 = 数据
var intro_script := [
	{"type": "say", "actor": "dolos", "text": "你好\nAletheia White", "duration": 3.0},
	{"type": "say", "actor": "dolos", "text": "我是Dolos Black\n叫我Black就行", "duration": 5.0},
	{"type": "say", "actor": "dolos", "text": "我将引导你\n完成接下来的关卡", "duration": 5.0},
	{"type": "set", "target": "player", "property": "movable", "value": true},
	# 分支条件：调用关卡方法判断平台
	{
		"type": "branch", "condition": {"op": "call", "method": "_is_pc"},
		"target": "pc_tip", 
		"else_target": "touch_tip"
	},
	{"type": "label", "name": "pc_tip"},
		{"type": "speak", "actor": "dolos", "text": "使用WASD或↑↓←→\n进行移动吧", "duration": 5.0},
		{"type": "jump", "target": "intro_end"},
	{"type": "label", "name": "touch_tip"},
		{"type": "speak", "actor": "dolos", "text": "使用游戏摇杆\n进行移动吧", "duration": 5.0},
	{"type": "label", "name": "intro_end"},
	{"type": "end"},
]

func _ready() -> void:
	a1.body_entered.connect(_open_door_tips)
	a2.body_entered.connect(_next_level_tips)
	actors = {"player": player, "dolos": dolos}
	await EventSystem.run(intro_script, self)

## 供事件系统条件求值调用（{op:"call", method:"_is_pc"}）
func _is_pc() -> bool:
	return OS.has_feature("pc")

func _open_door_tips(body: Node2D) -> void:
	# flag = "记住发生过的事"的格子；没勾过 → 提示 + 打勾；勾过 → 直接跳过
	if body is Player:
		if not EventSystem.get_flag("door_tipped"):
			EventSystem.set_flag("door_tipped")
			dolos.speak("你需要靠近按钮\n并按下交互键才能打开门", 8.0)
		else:
			dolos.speak("你怎么回来了\n有什么疑问吗", 6.0)


func _next_level_tips(body: Node2D) -> void:
	if body is Player:
		dolos.speak("继续前进，走至出口\n并按下交互键前往下一关", 8.0)
