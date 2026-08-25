shader_type canvas_item;

uniform vec3 color_base : source_color = vec3(1.0);
uniform vec4 color_a : source_color = vec4(0.597, 0.597, 0.597, 1.0);  	// 默认原始色
uniform vec4 color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);			// 渐变目标色
uniform float cycle_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float t = sin(TIME * cycle_speed) * 0.5 + 0.5;
	vec4 tint = mix(color_a, color_b, t);
	
	// 只替换基色，保留原 alpha
	if (tex.rgb == color_base) {
		COLOR = vec4(tint.rgb, tex.a);
	} else {
		COLOR = tex;
	}
}