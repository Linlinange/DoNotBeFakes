extends Control

@onready var timer: Timer = $Timer
@onready var npc: NPC = %Dolos_Black

func _ready():
	if not BgmManager.is_playing_bgm("res://assets/music/main.mp3"):
		BgmManager.play_bgm("res://assets/music/main.mp3")
	timer.timeout.connect(_on_timer_timeout)
	_restart_timer(1.0, 2.0)
	
	# 连接信号
	npc.input_pickable = true
	npc.input_event.connect(_on_input_event)

func _restart_timer(a: float, b: float):
	var time = randf_range(a, b)
	timer.wait_time = time
	#print(time)
	timer.start()

func _on_timer_timeout():
	npc.say(
		weighted_pick({
			"不用管我，忙你的就行": 30.0,
			"要学会控制视野\n在不必要时闭上双眼": 25.0,
			"有些按钮只是被隐藏了\n化虚为实令其显形": 15.0,
			"按钮切换需要花费时间\n在关门前可以快速通过": 25.0,
			"不是所有的墙或门\n都可以由虚转实": 25.0,
			"什么炸弹，明明是地雷\n一碰就炸": 15.0,
			"炸弹为虚时，不会爆炸": 15.0,
			"炸弹碰到瞬间不会立刻爆炸\n若离开则不会爆炸": 15.0,
			"虚态下对应的机关\n不会对你起反应": 25.0,
			"借助映射镜\n能通过正常难以通过的地方": 15.0,
			"不是所有虚的东西都无害\n有些只是藏起来了": 20.0,
			"不是所有事物都可控\n别太依赖由虚转实的能力": 25.0,
			"线索？\n不清楚那是什么": 15.0,
			"化假为实，化真为虚": 30.0,
			"实虽真但可造假\n虚够真亦可成实": 20.0,
			
			"其实我也没懂映射镜的原理\n若是假的，那为何能交互？": 15.0,
			"你放心，你绝对是真的\n不是什么克隆体": 10.0,
			"说实话这些实验……\n我指这些关，已经很熟了": 10.0,
			"你刚才好像犹豫了\n是在怀疑什么吗？": 15.0,
			"[font_size=28]观察你是我的工作……\n我是说，陪你通关是我的工作[/font_size]": 15.0,
			"每次切换，难以分清自己\n现在是原本，还是镜像": 15.0,
			"你放心，我货真价实\n不像[color=#ff4444]那家伙[/color]一样是假的": 15.0,
			"说实话我厌倦了实验\n每次都得重新引导": 10.0,
			"有人认为我的行为不应提倡\n那是他不懂": 15.0,
			"抛去道德伦理问题而言\n克隆其实有不少好处": 5.0,
			
			"游戏玩久了的话\n要记得好好休息": 15.0,
			"有些关卡，好乱，好杂\n到底是谁设计的": 10.0,
			"映射镜教会了我们\n遇事可以尝试转换角度": 15.0,
			"什么？这不是穿模\n这是……“不确定性态”": 10.0,
			"如果卡关了，试试闭上眼睛\n不是游戏的闭眼，是现实的": 5.0,
			"到底是什么奇葩的制作者\n才能开发出抽象的游戏": 5.0,
			"[color=yellow]关注零乘游创社喵~\n关注零乘游创社蟹蟹喵~[/color]": 30.0,
		}), 8.0
	)
	_restart_timer(8.0, 15.0)  # 重新随机间隔

## 根据权重随机选一个字符串
## items: { "字符串": 权重, ... }
func weighted_pick(items: Dictionary) -> String:
	var total: float = 0.0
	for w in items.values():
		total += w

	var roll := randf() * total
	var accum: float = 0.0
	for key in items.keys():
		accum += items[key]
		if roll < accum:
			return key
	return items.keys()[-1]  # 兜底

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_timer_timeout()
