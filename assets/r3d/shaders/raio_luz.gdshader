shader_type spatial;
// Feixe de luar (falso volumetrico): cone aditivo que se esvai nas pontas.
render_mode blend_add, cull_disabled, unshaded, depth_draw_never, shadows_disabled;
uniform vec3 cor : source_color = vec3(0.5, 0.85, 0.7);
uniform float forca = 0.16;
void fragment() {
	float alt = smoothstep(0.0, 0.35, UV.y) * (1.0 - smoothstep(0.55, 1.0, UV.y));
	float fr = pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.5);
	ALBEDO = cor * alt * forca * fr * (0.85 + 0.15 * sin(TIME * 0.7 + UV.x * 18.0));
}
