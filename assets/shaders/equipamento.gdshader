shader_type canvas_item;
// TROCA DE PALETA do rig "cavaleiro" da Koliani (pedido do Paulo, 3 set
// 2026: "substituir a arma do modelo actual pelo asset da arma equipada,
// e a armadura ... alterar a cor do modelo quando equiparmos outra").
//
// A lamina e as placas de armadura estao PINTADAS dentro de cada frame do
// rig, em sitios diferentes por frame -- por isso nao da para pousar um
// sprite por cima (dava duas espadas). O que da, e da bem, e' reconhecer
// os pixeis pela COR: o rig usa duas rampas de cinzento separadas.
//
//   RAMPA_ARMA      -- o fio da lamina e o rasto do golpe (e os olhos)
//   RAMPA_ARMADURA  -- as placas do peito, ombros e saia
//
// Cada pixel que caia numa rampa e' reescrito na cor do item equipado,
// guardando a posicao dele na rampa (o sombreado sobrevive). Tudo o resto
// -- pele, cabelo, manto, botas -- fica intacto.
//
// Verificado com `tools/verificar_paleta_rig.py`, que remarca as duas
// rampas por cima das tiras e deixa ver o que apanha.

uniform vec4 cor_arma : source_color = vec4(0.62, 0.62, 0.68, 1.0);
uniform vec4 cor_armadura : source_color = vec4(0.78, 0.73, 0.64, 1.0);
/// 0 = nao mexer na rampa (sem item equipado), 1 = trocar por completo.
uniform float peso_arma : hint_range(0.0, 1.0) = 0.0;
uniform float peso_armadura : hint_range(0.0, 1.0) = 0.0;
// --- rampas do rig, do escuro para o claro ---------------------------------
const int N_ARMA = 5;
const vec3 RAMPA_ARMA[5] = {
	vec3(0.373, 0.361, 0.412),  // #5f5c69
	vec3(0.400, 0.388, 0.443),  // #666371
	vec3(0.424, 0.412, 0.471),  // #6c6978
	vec3(0.431, 0.420, 0.478),  // #6e6b7a
	vec3(0.776, 0.725, 0.824)   // #c6b9d2
};
const float POS_ARMA[5] = { 0.0, 0.22, 0.40, 0.46, 1.0 };

const int N_ARMADURA = 4;
const vec3 RAMPA_ARMADURA[4] = {
	vec3(0.169, 0.161, 0.192),  // #2b2931
	vec3(0.239, 0.231, 0.267),  // #3d3b44
	vec3(0.286, 0.278, 0.318),  // #494751
	vec3(0.329, 0.322, 0.369)   // #54525e
};
const float POS_ARMADURA[4] = { 0.0, 0.36, 0.62, 1.0 };

// as cores das duas rampas mais proximas distam 0.043 por canal: 3/255 de
// folga chega e nao apanha a rampa vizinha.
const float FOLGA = 0.012;

/// Recria uma rampa de pixel-art a partir de UMA cor: a ponta escura e' a
/// cor abafada, a clara e' a cor lavada a branco.
vec3 rampa_de(vec3 cor, float t) {
	vec3 escuro = cor * 0.42;
	vec3 claro = mix(cor, vec3(1.0), 0.42);
	return mix(escuro, claro, t);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.01) {
		COLOR = c;
	} else {
		vec3 col = c.rgb;
		if (peso_arma > 0.001) {
			for (int i = 0; i < N_ARMA; i++) {
				if (all(lessThan(abs(c.rgb - RAMPA_ARMA[i]), vec3(FOLGA)))) {
					col = mix(col, rampa_de(cor_arma.rgb, POS_ARMA[i]), peso_arma);
					break;
				}
			}
		}
		if (peso_armadura > 0.001) {
			for (int i = 0; i < N_ARMADURA; i++) {
				if (all(lessThan(abs(c.rgb - RAMPA_ARMADURA[i]), vec3(FOLGA)))) {
					col = mix(col, rampa_de(cor_armadura.rgb, POS_ARMADURA[i]), peso_armadura);
					break;
				}
			}
		}
		COLOR = vec4(col, c.a) * COLOR;  // COLOR ja' traz o modulate do no'
	}
}
