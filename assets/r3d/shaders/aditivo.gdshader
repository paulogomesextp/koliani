shader_type spatial;
// VFX: rasto da espada, ondas, marcas de aviso. Cor * alpha do vertice.
render_mode blend_add, cull_disabled, unshaded, depth_draw_never, shadows_disabled;
uniform vec3 cor : source_color = vec3(1.0, 0.2, 0.7);
uniform float forca = 1.0;
uniform int modo = 0; // 0 cor do vertice, 1 faixa (UV.y), 2 circulo de aviso
void fragment() {
	float a = COLOR.a;
	if (modo == 1) {
		a *= 1.0 - abs(UV.y - 0.5) * 2.0;
	} else if (modo == 2) {
		vec2 q = UV - 0.5;
		float r = length(q) * 2.0;
		float anel = smoothstep(0.8, 0.95, r) * (1.0 - smoothstep(0.95, 1.0, r));
		float ang = atan(q.y, q.x);
		float racha = smoothstep(0.92, 1.0, sin(ang * 7.0 + r * 9.0)) * (1.0 - r);
		a *= (anel + racha * 0.8 + (1.0 - step(1.0, r)) * (1.0 - r) * 0.15);
	}
	ALBEDO = cor * COLOR.rgb * a * forca;
}
