shader_type canvas_item;
// Passa as camadas de um `fundo_pack` (packs CC0, cada um com a sua paleta)
// pelo tom da região: tira-lhes saturação e SÓ DEPOIS as pinta com a cor do
// bioma. Multiplicar por uma tinta (o `modulate`) escurece mas não desatura,
// e sem isto o Cold Corridors fica azul-néon e o Mountain Dusk fica com
// falésias vermelhas -- nenhum dos dois casa com o luar/magenta do `key_art`.
//
// A `tinta` vem de `atmosfera.gd::_gradacao` (tinta da região já diluída
// pela profundidade da camada). O `modulate` do Sprite2D fica em branco.

uniform float dessaturar : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tinta : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(l), dessaturar);
	c.rgb *= tinta.rgb;
	COLOR = c;
}
