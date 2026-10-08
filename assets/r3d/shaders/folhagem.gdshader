shader_type spatial;
// Fetos/erva/folhas: forma desenhada no UV (sem textura), vento no vertice.
render_mode cull_disabled, specular_disabled;
uniform vec3 cor_base : source_color = vec3(0.03, 0.09, 0.05);
uniform vec3 cor_ponta : source_color = vec3(0.16, 0.42, 0.22);
uniform int forma = 0; // 0 feto, 1 erva, 2 folha larga
uniform float vento = 0.12;
uniform vec3 cor_rim : source_color = vec3(0.4, 0.9, 0.6);
varying float alt;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float k = UV.y * UV.y;
	VERTEX.x += sin(TIME * 1.6 + w.x * 0.7 + w.z * 0.4) * vento * k;
	VERTEX.z += cos(TIME * 1.3 + w.z * 0.6) * vento * 0.6 * k;
	alt = UV.y;
}
void fragment() {
	vec2 uv = UV;
	float x = abs(uv.x - 0.5) * 2.0;
	float a = 0.0;
	if (forma == 0) {
		float larg = sin(uv.y * 3.14159) * 0.95;
		float folio = fract(uv.y * 11.0);
		float lim = larg * (0.55 + 0.45 * smoothstep(0.0, 0.5, folio) * (1.0 - smoothstep(0.6, 1.0, folio)));
		a = step(x, lim) * step(0.02, uv.y);
		a = max(a, step(x, 0.05));
	} else if (forma == 1) {
		a = step(x, (1.0 - uv.y) * 0.9);
	} else {
		a = step(x, sin(uv.y * 3.14159) * 0.9 * (1.0 - uv.y * 0.3));
	}
	if (a < 0.5) discard;
	vec3 c = mix(cor_base, cor_ponta, smoothstep(0.0, 1.0, alt));
	ALBEDO = c * (0.85 + 0.3 * x);
	ROUGHNESS = 0.8;
	BACKLIGHT = c * 0.6;
	float fr = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = cor_rim * fr * 0.15 * alt;
}
