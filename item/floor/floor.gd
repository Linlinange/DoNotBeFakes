extends TileMapLayer

# ========== 参数 ==========
## 随机种子。-1 表示每次自动生成随机种子，其他值固定生成
@export var seed_value: int = -1

## 瓦片集里的 Source ID（通常第一个 Atlas 是 0）
@export var source_id: int = 0

## 候选瓦片（Atlas 坐标）
@export var tile_options: Array[Vector2i] = [
	Vector2i(0, 4), 
	Vector2i(2, 4), 
	Vector2i(3, 4), 
	Vector2i(0, 5), 
	Vector2i(1, 5), 
	Vector2i(2, 5)
]

## 与 tile_options 一一对应的权重，长度不足时自动补 1.0
@export var tile_weights: Array[float] = [
	15.0, 
	5.0, 
	5.0, 
	1.0, 
	1.0, 
	1.0, 
]

## 填充区域（单元格坐标）
@export var fill_rect: Rect2i = Rect2i(-60, -40, 120, 80)

## 生成前是否清空图层
@export var clear_before_fill: bool = true

## 是否只铺空白格子（不覆盖已有瓦片）
@export var only_fill_empty: bool = false

## 进入游戏时自动生成
@export var auto_generate: bool = true

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	if auto_generate:
		generate()

func generate() -> void:
	if tile_options.is_empty():
		push_warning("候选瓦片 tile_options 为空，无法生成")
		return
	
	# 补齐权重数组
	while tile_weights.size() < tile_options.size():
		tile_weights.append(1.0)
	
	# ========== 种子处理 ==========
	var effective_seed: int
	if seed_value == -1:
		effective_seed = randi()
		#print("[floor] 自动生成随机种子: ", effective_seed)
	else:
		effective_seed = seed_value
		#print("[floor] 使用固定种子: ", effective_seed)
	
	rng.seed = effective_seed
	# =============================
	
	if clear_before_fill:
		clear()
	
	for x in range(fill_rect.position.x, fill_rect.end.x):
		for y in range(fill_rect.position.y, fill_rect.end.y):
			var coord := Vector2i(x, y)
			
			if only_fill_empty and get_cell_source_id(coord) != -1:
				continue
			
			var atlas: Vector2i = _pick_weighted_tile()
			set_cell(coord, source_id, atlas)


func generate_area(rect: Rect2i) -> void:
	if tile_options.is_empty():
		return
	while tile_weights.size() < tile_options.size():
		tile_weights.append(1.0)
	
	# ========== 种子处理（同上）==========
	var effective_seed: int
	if seed_value == -1:
		effective_seed = randi()
	else:
		effective_seed = seed_value
	
	rng.seed = effective_seed
	# =====================================
	
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var coord := Vector2i(x, y)
			if only_fill_empty and get_cell_source_id(coord) != -1:
				continue
			var atlas: Vector2i = _pick_weighted_tile()
			set_cell(coord, source_id, atlas)


# ========== 加权随机选择 ==========
func _pick_weighted_tile() -> Vector2i:
	var total := 0.0
	for w in tile_weights:
		total += w
	
	var rand_val := rng.randf() * total
	var cumulative := 0.0
	
	for i in range(tile_options.size()):
		cumulative += tile_weights[i]
		if rand_val <= cumulative:
			return tile_options[i]
	
	return tile_options[-1]
