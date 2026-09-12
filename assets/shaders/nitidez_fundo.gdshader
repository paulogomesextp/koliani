shader_type canvas_item;
// NITIDEZ DO FUNDO (Execution 9H).
//
// O Game Master disse que "o background está desfocado", e estava: as peças
// do kit da Região I são pinturas pequenas (o panorama tem 952x247, as peças
// de fundo 50-200 px) desenhadas com `TEXTURE_FILTER_LINEAR` a 2x-3x, e com
// a câmara a somar o seu zoom por cima. Ampliação bilinear é, por definição,
// interpolação: quanto mais se amplia, mais macia fica a imagem.
//
// Sharpen a montante (na textura) não resolve -- a ampliação volta a
// suavizar. Este shader trabalha DEPOIS da ampliação, no pixel do ecrã:
// máscara de desfoque (unsharp) de quatro amostras em cruz. O raio é em
// píxeis de ECRÃ, por isso o efeito é o mesmo em qualquer zoom.
//
// `forca` 0 = igual ao que estava. Valores acima de ~0,9 começam a desenhar
// halo nas arestas; o kit usa 0,45-0,75 conforme a ampliação da camada.

uniform float forca : hint_range(0.0, 1.5) = 0.55;
uniform float raio : hint_range(0.5, 4.0) = 1.15;
// A gradação da camada continua a entrar aqui (ver `fundo_bioma.gdshader`):
// uma peça só pode ter um material, e a tinta tinha de vir junto.
uniform vec4 tinta : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dessaturar : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// passo de amostragem = `raio` píxeis do ECRÃ convertidos para UV
	vec2 passo = raio * fwidth(UV);
	vec3 borrao = (
		texture(TEXTURE, UV + vec2(passo.x, 0.0)).rgb +
		texture(TEXTURE, UV - vec2(passo.x, 0.0)).rgb +
		texture(TEXTURE, UV + vec2(0.0, passo.y)).rgb +
		texture(TEXTURE, UV - vec2(0.0, passo.y)).rgb) * 0.25;
	c.rgb = clamp(c.rgb + (c.rgb - borrao) * forca, 0.0, 1.0);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(l), dessaturar);
	c.rgb *= tinta.rgb;
	COLOR = c;
}
