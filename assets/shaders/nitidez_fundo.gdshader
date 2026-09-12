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
// halo nas arestas.
//
// Execution 9H.7 -- O `COLOR` de um shader de canvas_item JÁ vem multiplicado
// pelo `modulate` do nó e de todos os pais. Escrever `COLOR = c` com `c` a sair
// só da textura ATIRAVA ESSE MODULATE FORA, e ninguém punha nada no uniforme
// `tinta` que estava aqui para o substituir. Resultado desde a 9H: o fundo da
// Região I era desenhado sem a tinta de mood da 08, sem os −18 % da camada
// mais funda e sem os alfas das camadas (0,82 na 3 e 0,6 na 2, que era o que
// impedia a silhueta das árvores de apagar as arestas) -- e daí vinha metade
// do ar errado. Agora o `modulate` é apanhado no estágio de VÉRTICE (onde o
// `COLOR` é exactamente a cor do vértice, ou seja a cadeia de modulate já
// propagada pelos pais) e reposto no fim. Pelo vértice e não por um `MODULATE`
// no fragmento porque esse built-in não existe em todas as versões -- nesta
// dá "Unknown identifier".

uniform float forca : hint_range(0.0, 1.5) = 0.55;
uniform float raio : hint_range(0.5, 4.0) = 1.15;
// A gradação da camada continua a entrar aqui (ver `fundo_bioma.gdshader`):
// uma peça só pode ter um material, e a tinta tinha de vir junto.
uniform vec4 tinta : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dessaturar : hint_range(0.0, 1.0) = 0.0;

varying vec4 modulacao;

void vertex() {
	modulacao = COLOR;
}

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
	COLOR = c * modulacao;
}
