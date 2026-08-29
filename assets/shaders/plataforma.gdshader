shader_type canvas_item;
// Plataforma "chunky" tipo Dead Cells, procedural (sem textura). Desenha
// pedra com estratos + juntas de tijolo, aresta de topo iluminada (musgo)
// e sombra em baixo. O `tamanho` (px do rect) e passado pelo plataforma.gd
// para as juntas terem sempre a mesma escala.

uniform vec2 tamanho = vec2(200.0, 40.0);
uniform vec4 cor_base : source_color = vec4(0.15, 0.21, 0.11, 1.0);
uniform vec4 cor_topo : source_color = vec4(0.42, 0.62, 0.28, 1.0);
uniform vec4 cor_fundo : source_color = vec4(0.03, 0.045, 0.02, 1.0);
uniform float brilho_topo : hint_range(0.0, 1.0) = 0.9;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.31, 289.17))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * tamanho;
	vec3 col = cor_base.rgb;

	// ruido de pedra
	float n = hash(floor(p / 6.0));
	col *= 0.88 + 0.16 * n;

	// juntas de tijolo (colunas deslocadas por linha) + linhas horizontais
	float linha = floor(p.y / 24.0);
	float jx = fract((p.x + linha * 13.0) / 36.0);
	float junta = smoothstep(0.0, 0.05, jx) * smoothstep(0.0, 0.05, 1.0 - jx);
	col *= mix(0.76, 1.0, junta);
	col *= mix(0.82, 1.0, smoothstep(0.0, 0.08, fract(p.y / 24.0)));
	// variacao de cor por tijolo
	col *= 0.92 + 0.14 * hash(vec2(floor((p.x + linha * 18.0) / 36.0), linha));

	// aresta de topo iluminada (musgo/relva) + tufos irregulares
	float topo = 1.0 - smoothstep(0.0, 6.0, p.y);
	col = mix(col, cor_topo.rgb, topo * brilho_topo * 0.85);
	float tuf = step(0.68, hash(vec2(floor(p.x / 10.0), 7.0)));
	col = mix(col, cor_topo.rgb * 1.1, tuf * (1.0 - smoothstep(0.0, 12.0, p.y)) * 0.65);

	// sombra em baixo
	col = mix(col, cor_fundo.rgb, smoothstep(0.45, 1.0, UV.y) * 0.65);

	COLOR = vec4(col, 1.0);
}
