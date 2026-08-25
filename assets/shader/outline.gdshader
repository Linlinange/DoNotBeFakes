shader_type canvas_item;

uniform float outline_thickness : hint_range(0.0, 5.0) = 1.0;
uniform vec4 color_a : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 1.0, 0.2, 1.0);
uniform float cycle_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_thickness;
	
	// 当前像素是否在白色遮罩内
	bool is_inside = tex_color.a > 0.01;
	
	// 采样四周，判断当前像素是否邻接白色遮罩
	float a_right = texture(TEXTURE, UV + vec2(ps.x, 0.0)).a;
	float a_left  = texture(TEXTURE, UV - vec2(ps.x, 0.0)).a;
	float a_up    = texture(TEXTURE, UV + vec2(0.0, ps.y)).a;
	float a_down  = texture(TEXTURE, UV - vec2(0.0, ps.y)).a;
	bool has_neighbor = a_right > 0.01 || a_left > 0.01 || a_up > 0.01 || a_down > 0.01;
	
	// 循环渐变颜色
	float t = sin(TIME * cycle_speed) * 0.5 + 0.5;
	vec4 final_color = mix(color_a, color_b, t);
	
	// 绘制逻辑
	if (is_inside) {
		// 遮罩内部：透明（挖空，显示下层）
		COLOR = vec4(0.0);
	} else if (has_neighbor) {
		// 遮罩外侧且邻接遮罩：描边（往外扩）
		COLOR = final_color;
	} else {
		// 远离遮罩的区域：透明
		COLOR = vec4(0.0);
	}
}