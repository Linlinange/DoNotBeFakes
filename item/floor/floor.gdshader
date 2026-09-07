shader_type canvas_item;

// ========== 参数调节 ==========
// 单个瓦片的像素尺寸（按你实际瓦片修改，如16/32/64）
uniform float tile_size = 32.0;
// 倒角边框宽度（像素单位）
uniform float bevel_size = 1.0;
// 高光提亮强度 0~1
uniform float highlight_strength = 0.3;
// 阴影压暗强度 0~1
uniform float shadow_strength = 0.4;
// 光源方向：(-1,-1)=左上，(1,-1)=右上，(-1,1)=左下
uniform vec2 light_direction = vec2(-1.0, -1.0);
// 瓦片网格偏移（像素单位），瓦片与世界网格不对齐时调整此值校准边缘
uniform vec2 offset = vec2(0.0, 0.0);
uniform sampler2D detail_tex: filter_nearest;

// ========== 内部变量 ==========
varying vec4 modulate_color;
varying vec2 world_pos;

void vertex() {
	// 局部坐标 → 世界坐标，传递到片段阶段
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;

	// vertex 阶段的 COLOR = 顶点色 × modulate × self_modulate
	// 对 Sprite2D 来说顶点色通常是白色，所以这里拿到的大约就是 modulate
	modulate_color = COLOR;
}

void fragment() {
	// 1. 采样固有色贴图
	vec4 base = texture(TEXTURE, UV);
	vec4 detail_col = texture(detail_tex, UV);
	vec4 left     = texture(detail_tex, UV + vec2(-TEXTURE_PIXEL_SIZE.x, 0.0));
	vec4 right    = texture(detail_tex, UV + vec2( TEXTURE_PIXEL_SIZE.x, 0.0));
	vec4 up       = texture(detail_tex, UV + vec2(0.0, -TEXTURE_PIXEL_SIZE.y));
	vec4 down     = texture(detail_tex, UV + vec2(0.0,  TEXTURE_PIXEL_SIZE.y));
	
	// 2. 计算世界网格内的相对UV（与瓦片自身旋转完全无关）
	// 减去 offset 抵消瓦片网格与世界网格的偏移差，保证边缘对齐
	vec2 tile_uv = fract((world_pos - offset) / tile_size);
	
	// 3. 计算像素到四边的距离
	float left_dist = tile_uv.x;
	float right_dist = 1.0 - tile_uv.x;
	float top_dist = tile_uv.y;
	float bottom_dist = 1.0 - tile_uv.y;
	
	// 倒角宽度转UV单位
	float bevel_uv = bevel_size / tile_size;
	
	// 4. 四边权重（硬边像素风用 step，平滑风换 smoothstep）
	float left_w = 1.0 - step(bevel_uv, left_dist);
	float right_w = 1.0 - step(bevel_uv, right_dist);
	float top_w = 1.0 - step(bevel_uv, top_dist);
	float bottom_w = 1.0 - step(bevel_uv, bottom_dist);
	
	// 5. 根据光源方向分配高光/阴影
	float highlight = 0.0;
	float shadow = 0.0;
	float light_len = length(light_direction);
	
	// 水平方向
	if (light_direction.x < 0.0) {
		highlight += left_w * abs(light_direction.x);
		shadow += right_w * abs(light_direction.x);
	} else {
		highlight += right_w * light_direction.x;
		shadow += left_w * light_direction.x;
	}
	
	// 垂直方向
	if (light_direction.y < 0.0) {
		highlight += top_w * abs(light_direction.y);
		shadow += bottom_w * abs(light_direction.y);
	} else {
		highlight += bottom_w * light_direction.y;
		shadow += top_w * light_direction.y;
	}
	
	// 归一化，避免方向向量长度影响亮度
	highlight /= light_len;
	shadow /= light_len;

	if (detail_col.a == 1.0){
		highlight = 0.0;
		shadow = 0.0;
	}

	// 6. 混合最终颜色
	vec3 final_rgb = base.rgb * (1.0 + highlight * highlight_strength - shadow * shadow_strength);
	COLOR = vec4(final_rgb, base.a) * modulate_color;
}
