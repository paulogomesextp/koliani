shader_type spatial;
// Pantano envenenado: agua escura com veios verde-acido e manchas de corrupcao.
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 cor_fundo : source_color = vec3(0.02, 0.06, 0.04);
uniform vec3 cor_veio : source_color = vec3(0.25, 0.9, 0.35);
uniform vec3 cor_corr : source_color = vec3(0.7, 0.1, 0.5);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 1.2 + wpos.x * 0.8 + wpos.z * 0.5) * 0.04;
}
void fragment() {
	vec2 p = wpos.xz * 0.12;
	float a = texture(ruido, p + vec2(TIME * 0.015, TIME * 0.01)).r;
	float b = texture(ruido, p * 2.3 - vec2(TIME * 0.02, -TIME * 0.012)).r;
	float veio = 1.0 - smoothstep(0.0, 0.018, abs(a - b));
	float mancha = smoothstep(0.68, 0.8, texture(ruido, p * 0.5 + 0.37).r);
	ALBEDO = cor_fundo;
	ROUGHNESS = 0.08;
	METALLIC = 0.2;
	EMISSION = cor_veio * veio * 0.35 + cor_corr * mancha * 0.18 * (0.7 + 0.3 * sin(TIME * 2.0));
}
