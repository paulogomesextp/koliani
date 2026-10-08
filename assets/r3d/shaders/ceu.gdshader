shader_type sky;
// Ceu noturno da Floresta Corrompida: gradiente, lua grande, aureola, estrelas.
uniform vec3 cor_zenite : source_color = vec3(0.02, 0.03, 0.06);
uniform vec3 cor_horizonte : source_color = vec3(0.12, 0.08, 0.16);
uniform vec3 cor_brilho : source_color = vec3(0.35, 0.12, 0.32);
uniform vec3 dir_lua = vec3(0.3, 0.45, -0.85);
uniform vec3 cor_lua : source_color = vec3(0.85, 0.95, 0.9);
uniform float tam_lua = 0.035;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, -1.0, 1.0);
	vec3 c = mix(cor_horizonte, cor_zenite, smoothstep(0.0, 0.55, h));
	c += cor_brilho * pow(1.0 - abs(h), 6.0) * 0.6;
	vec3 l = normalize(dir_lua);
	float ang = acos(clamp(dot(d, l), -1.0, 1.0));
	c += cor_lua * smoothstep(tam_lua, tam_lua * 0.85, ang);
	c += cor_lua * 0.25 * exp(-ang * 9.0);
	c += cor_brilho * 0.15 * exp(-ang * 2.5);
	vec2 q = d.xz / (d.y + 1.2) * 520.0;
	vec2 g = floor(q);
	float s = step(0.993, h21(g)) * smoothstep(0.32, 0.0, length(fract(q) - 0.5)) * smoothstep(0.05, 0.4, h);
	c += vec3(s) * 0.8;
	if (h < 0.0) c = mix(cor_horizonte * 0.6, vec3(0.01, 0.015, 0.02), smoothstep(0.0, -0.3, h));
	COLOR = c;
}
