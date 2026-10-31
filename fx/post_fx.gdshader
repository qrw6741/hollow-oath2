shader_type canvas_item;
// Screen-space finishing pass: soft bloom on bright pixels, split-tone colour grade, slight edge
// chromatic fringe and fine film grain. Reads the already-drawn world (below the HUD).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float bloom : hint_range(0.0, 1.0) = 0.34;
uniform float grade : hint_range(0.0, 1.0) = 0.7;
uniform float grain : hint_range(0.0, 0.2) = 0.035;
uniform float fringe : hint_range(0.0, 4.0) = 1.2;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 bright(vec2 uv) {
	vec3 c = texture(screen_tex, uv).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return c * smoothstep(0.62, 1.0, l);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 d = uv - vec2(0.5);
	float edge = dot(d, d);
	vec2 off = d * edge * fringe * px * 6.0;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;
	// bloom: two rings of taps, scaled with the screen so it looks alike at every size
	float s = max(1.0, 1.0 / (px.y * 270.0)) * 1.6;
	vec3 b = vec3(0.0);
	for (int i = 0; i < 4; i++) {   // 4 + 4 taps (was 8 + 8): same look, half the texture reads
		float a = float(i) * 1.5707963 + 0.7853982;
		vec2 o = vec2(cos(a), sin(a));
		b += bright(uv + o * px * s * 2.5);
		b += bright(uv + o * px * s * 5.5) * 0.7;
	}
	b /= 6.8;
	col += b * bloom * vec3(1.0, 0.88, 0.7);
	// split-tone grade: cool violet shadows, warm highlights, a touch more contrast
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 shadow = vec3(0.9, 0.92, 1.12);
	vec3 high = vec3(1.08, 1.02, 0.9);
	vec3 toned = col * mix(shadow, high, smoothstep(0.1, 0.7, l));
	toned = mix(vec3(l), toned, 1.1);
	toned = (toned - 0.5) * 1.07 + 0.5;
	col = mix(col, toned, grade);
	// grain
	float n = hash(floor(FRAGCOORD.xy) + floor(TIME * 24.0) * 7.13) - 0.5;
	col += n * grain * (1.1 - l);
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
