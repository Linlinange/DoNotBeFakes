shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.02, 0.03, 0.08, 1.0);	// 背景底色
uniform vec4 star_color_1 : source_color = vec4(0.9, 0.95, 1.0, 1.0);	// 主星色（亮白，占比最多）
uniform vec4 star_color_2 : source_color = vec4(0.35, 0.9, 0.7, 1.0);	// 青绿色星
uniform vec4 star_color_3 : source_color = vec4(0.8, 0.5, 0.9, 1.0);	// 粉紫色点缀星
uniform float star_density = 1.0;		// 星星密度
uniform float twinkle_speed = 1.0;		// 闪烁速度
uniform float min_star_size : hint_range(0.01, 0.2) = 0.2;		// 星星最小尺寸
uniform float max_star_size : hint_range(0.08, 0.7) = 0.5;		// 星星最大尺寸
uniform float ray_strength : hint_range(0.0, 1.2) = 0.7;		// 星光强度（0=纯圆点）
uniform vec4 nebula_color : source_color = vec4(0.4, 0.3, 0.6, 1.0);	// 星云光晕颜色
uniform float nebula_strength : hint_range(0.0, 0.4) = 0.12;			// 星云亮度（0=无星云）
uniform float nebula_speed = 0.3;										// 星云缓慢流动速度

// 基础随机函数
float rand(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// 平滑值噪声（生成柔和星云用）
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f); // 平滑插值曲线
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    vec3 color = base_color.rgb;

    // ========== 底层：淡淡流动星云 ==========
    vec2 nebula_uv = UV * 3.5; // 数值越小星云斑块越大
    // 双层噪声错位流动，模拟星云层次感
    float layer1 = noise(nebula_uv + vec2(TIME * nebula_speed * 0.08, 0.0));
    float layer2 = noise(nebula_uv * 1.8 - vec2(0.0, TIME * nebula_speed * 0.05));
    float nebula = layer1 * 0.65 + layer2 * 0.35;
    // 压暗暗部，只保留亮部光晕
    nebula = smoothstep(0.35, 0.95, nebula) * nebula_strength;
    color += nebula_color.rgb * nebula;

    // ========== 上层：星空 ==========
    vec2 uv = UV * 200.0 * star_density;
    vec2 id = floor(uv);
    vec2 f = fract(uv);

    float n = rand(id);

    if (n > 0.98) {
        float size = mix(min_star_size, max_star_size, rand(id + 1.0));

        // ===== 交错闪烁：每颗星星独立频率+独立相位 =====
        float speed_random = rand(id + 3.0) * 0.6 + 0.7; // 随机0.7~1.3倍速
        float phase_random = n * 15.0; // 完全随机初始相位
        float twinkle = sin(TIME * twinkle_speed * speed_random + phase_random) * 0.5 + 0.5;

        // 星星形状：亮核心 + 十字星芒
        vec2 center = f - 0.5;
        float dx = abs(center.x);
        float dy = abs(center.y);
        float dist = length(center);

        float core = smoothstep(size * 0.5, 0.0, dist);
        float ray_h = smoothstep(size, 0.0, dx) * smoothstep(size * 0.12, 0.0, dy);
        float ray_v = smoothstep(size, 0.0, dy) * smoothstep(size * 0.12, 0.0, dx);
        float rays = (ray_h + ray_v) * ray_strength;

        float star = core + rays;

        // 随机分配星光颜色
        float color_rand = rand(id + 2.0);
        vec3 star_col;
        if (color_rand < 0.6) {
            star_col = star_color_1.rgb;
        } else if (color_rand < 0.88) {
            star_col = star_color_2.rgb;
        } else {
            star_col = star_color_3.rgb;
        }

        color += star_col * star * twinkle;
    }

    COLOR = vec4(color, 1.0);
}