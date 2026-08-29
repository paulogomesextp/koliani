shader_type canvas_item;
// Passe de ecra: contraste + saturacao + bloom suave (extrai zonas
// claras, borra, soma). Barato o suficiente para 60fps; poe bloom a 0
// para desligar (ex.: telemoveis fracos).

uniform sampler2D ecra : hint_screen_texture, filter_linear_mipmap;
uniform float contraste : hint_range(0.8, 1.4) = 1.06;
uniform float saturacao : hint_range(0.5, 2.0) = 1.12;
uniform float bloom : hint_range(0.0, 1.5) = 0.35;
uniform float bloom_limiar : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	vec2 px = 1.0 / vec2(textureSize(ecra, 0));
	vec3 c = texture(ecra, SCREEN_UV).rgb;

	vec3 b = vec3(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec3 s = texture(ecra, SCREEN_UV + vec2(float(i), float(j)) * px * 3.0).rgb;
			b += max(s - bloom_limiar, vec3(0.0));
		}
	}
	c += (b / 9.0) * bloom * 3.0;

	c = (c - 0.5) * contraste + 0.5;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturacao);

	COLOR = vec4(clamp(c, vec3(0.0), vec3(1.0)), 1.0);
}
