shader_type spatial;
// Tecido/cabelo: gradiente ao longo do UV.y (raiz -> ponta), dois lados, rim.
render_mode cull_disabled, specular_disabled;
uniform vec3 cor_raiz : source_color = vec3(0.03, 0.02, 0.03);
uniform vec3 cor_ponta : source_color = vec3(0.5, 0.04, 0.06);
uniform float ini = 0.55;
uniform float fim = 1.0;
uniform vec3 cor_rim : source_color = vec3(0.7, 0.3, 0.6);
uniform float rim = 0.35;
uniform float brilho = 0.0;
uniform float riscas = 0.15;
uniform float flash = 0.0;
void fragment() {
	vec3 c = mix(cor_raiz, cor_ponta, smoothstep(ini, fim, UV.y));
	float risca = 1.0 - riscas + riscas * sin(UV.x * 40.0);
	ALBEDO = mix(c * risca, vec3(1.0), flash);
	ROUGHNESS = 0.6;
	float fr = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.5);
	EMISSION = cor_rim * fr * rim + c * brilho + vec3(1.0) * flash * 0.6;
}
void light() {
	float d = abs(dot(NORMAL, LIGHT));
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * mix(0.35, 1.0, smoothstep(0.0, 0.4, d)) / 3.14159;
}
