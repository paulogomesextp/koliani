class_name DiarioPistas
extends RefCounted
## Textos das pistas sobre a mãe, por id. Dados puros (sem nós) para o
## ecrã de diário (`scenes/ui/Diario.tscn`) e para os testes headless.
##
## Os ids são os mesmos que as `Porta`/`Coletavel` passam a
## `EstadoJogo.registar_pista(...)`. Quando o agente "gaming" desenha um
## mundo novo, acrescenta aqui as pistas desse mundo.

const PISTAS := {
	"floresta_sinal_da_porta": {
		"mundo": "Floresta Putrefata",
		"titulo": "O cheiro na porta",
		"texto": "A porta ainda cheira ao enxofre dele. Ela passou por aqui -- e não sozinha.",
	},
	"floresta_carta_rasgada": {
		"mundo": "Floresta Putrefata",
		"titulo": "Meia carta",
		"texto": "Metade de uma carta da mãe, rasgada a meio: \"...não me procures, Kol. O que ele quer não sou eu...\"",
	},
	"prisao_carta_na_cela": {
		"mundo": "Prisão dos Condenados",
		"titulo": "A cela vazia",
		"texto": "Numa cela ao fundo, o nome dela riscado na pedra e uma data -- de há três dias. Zeriko não a deixou aqui muito tempo.",
	},
	"prisao_grito_nas_correntes": {
		"mundo": "Prisão dos Condenados",
		"titulo": "Correntes que ainda oscilam",
		"texto": "As correntes de uma cela alta ainda balançam. Quem passou por aqui, passou agora mesmo -- e à força.",
	},
}


## Constrói a lista de entradas legíveis para os ids dados (pela ordem em
## que foram encontrados). Ids sem texto ainda aparecem, com um aviso.
static func entradas(ids: Array) -> Array:
	var lista: Array = []
	for id: String in ids:
		var p: Dictionary = PISTAS.get(id, {})
		lista.append({
			"id": id,
			"mundo": p.get("mundo", "?"),
			"titulo": p.get("titulo", id),
			"texto": p.get("texto", "(pista por escrever)"),
		})
	return lista


## Quantas pistas existem no total no jogo (para "3 / 8").
static func total_no_jogo() -> int:
	return PISTAS.size()
