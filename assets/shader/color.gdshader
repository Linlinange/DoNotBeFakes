shader_type canvas_item;

uniform vec3 color_base : source_color = vec3(1.0);
uniform vec4 color_a : source_color = vec4(0.597, 0.597, 0.597, 1.0);  	// 默认原始色
uniform vec4 color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);			// 渐变目标色
uniform float cycle_speed : hint_range(0.0, 5.0) = 2.0;

varying vec4 modulate_color;

void vertex() {
	// vertex 阶段的 COLOR = 顶点色 × modulate × self_modulate
	// 对 Sprite2D 来说顶点色通常是白色，所以这里拿到的大约就是 modulate
	modulate_color = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float t = sin(TIME * cycle_speed) * 0.5 + 0.5;
	vec4 tint = mix(color_a, color_b, t);
	
	// 替换基色后，再乘回 modulate，保留原 alpha 与 modulate alpha 的交互
	if (tex.rgb == color_base) {
		COLOR = vec4(tint.rgb, tex.a) * modulate_color;
	} else {
		COLOR = tex * modulate_color;
	}
}