shader_type spatial;
// Koliani 3D -- material estilizado unico (terreno, rocha, casca, pedra sagrada,
// tecido, pele). Triplanar de ruido -> duas cores + musgo nas faces de cima,
// luz difusa em degraus suaves e rim colorido (contorno de luar).
render_mode specular_disabled;

uniform vec3 cor_a : source_color = vec3(0.2, 0.18, 0.16);
uniform vec3 cor_b : source_color = vec3(0.3, 0.27, 0.22);
uniform vec3 cor_topo : source_color = vec3(0.12, 0.3, 0.14);
uniform float topo_quant = 0.0;
uniform float topo_limiar = 0.55;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform float escala = 0.35;
uniform float contraste = 1.0;
uniform float fendas = 0.0;
uniform vec3 cor_rim : source_color = vec3(0.45, 0.8, 0.7);
uniform float rim = 0.22;
uniform vec3 emissao : source_color = vec3(0.0);
uniform float emissao_veias = 0.0;
uniform float emissao_plana = 0.0;
uniform float pulso = 0.0;
uniform float degraus = 0.65;
uniform float flash = 0.0;
uniform vec3 cor_flash : source_color = vec3(1.0);

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float tri(vec3 p, vec3 n) {
	vec3 b = pow(abs(n), vec3(4.0));
	b /= (b.x + b.y + b.z + 1e-4);
	return texture(ruido, p.zy).r * b.x + texture(ruido, p.xz).r * b.y + texture(ruido, p.xy).r * b.z;
}

void fragment() {
	vec3 p = wpos * escala;
	float n1 = tri(p, wnrm);
	float n2 = tri(p * 3.7 + vec3(0.31, 0.17, 0.53), wnrm);
	float v = clamp((n1 * 0.65 + n2 * 0.35 - 0.5) * contraste + 0.5, 0.0, 1.0);
	vec3 c = mix(cor_a, cor_b, smoothstep(0.3, 0.72, v));
	// fendas escuras (pedra/casca)
	float f = 1.0 - smoothstep(0.0, 0.05, abs(n2 - 0.5));
	c *= 1.0 - f * fendas * 0.55;
	float t = smoothstep(topo_limiar, topo_limiar + 0.18, wnrm.y + (n1 - 0.5) * 0.6) * topo_quant;
	c = mix(c, cor_topo * (0.7 + 0.6 * n2), t);
	c = mix(c, cor_flash, flash);
	ALBEDO = c;
	ROUGHNESS = 0.9;
	float veia = smoothstep(0.615, 0.64, n1) * (1.0 - smoothstep(0.64, 0.675, n1));
	float pul = 1.0 + pulso * sin(TIME * 3.0 + wpos.y * 1.5);
	EMISSION = emissao * (veia * emissao_veias + emissao_plana) * pul;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += cor_rim * fr * rim + cor_flash * flash * 0.6;
}

void light() {
	float d = dot(NORMAL, LIGHT);
	float s = smoothstep(-0.05, 0.25, d);
	float banda = mix(d * 0.5 + 0.5, s, degraus);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * clamp(banda, 0.0, 1.0) / 3.14159;
}
