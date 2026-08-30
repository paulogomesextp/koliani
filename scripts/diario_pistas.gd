class_name DiarioPistas
extends RefCounted
## Pistas sobre a mãe, por id. Dados puros (sem nós, sem autoloads) para o
## ecrã de diário (`scenes/ui/Diario.tscn`) e para os testes headless.
##
## Cada entrada guarda **chaves de tradução** (não o texto): o `Textos`
## resolve-as no idioma atual. Ver `assets/i18n/*.json` (`world.*`,
## `clue.<id>.title`, `clue.<id>.body`).
##
## Os ids são os mesmos que as `Porta`/`Coletavel` passam a
## `EstadoJogo.registar_pista(...)`.

const PISTAS := {
	"floresta_sinal_da_porta": {
		"mundo": "world.forest",
		"titulo": "clue.floresta_sinal_da_porta.title",
		"texto": "clue.floresta_sinal_da_porta.body",
	},
	"floresta_carta_rasgada": {
		"mundo": "world.forest",
		"titulo": "clue.floresta_carta_rasgada.title",
		"texto": "clue.floresta_carta_rasgada.body",
	},
	"pantano_bilhete_na_agua": {
		"mundo": "world.forest",
		"titulo": "clue.pantano_bilhete_na_agua.title",
		"texto": "clue.pantano_bilhete_na_agua.body",
	},
	"ninho_teia_com_cabelo": {
		"mundo": "world.forest",
		"titulo": "clue.ninho_teia_com_cabelo.title",
		"texto": "clue.ninho_teia_com_cabelo.body",
	},
	"arvore_lagrima_no_tronco": {
		"mundo": "world.forest",
		"titulo": "clue.arvore_lagrima_no_tronco.title",
		"texto": "clue.arvore_lagrima_no_tronco.body",
	},
	"coracao_batida_no_chao": {
		"mundo": "world.forest",
		"titulo": "clue.coracao_batida_no_chao.title",
		"texto": "clue.coracao_batida_no_chao.body",
	},
	"prisao_carta_na_cela": {
		"mundo": "world.prison",
		"titulo": "clue.prisao_carta_na_cela.title",
		"texto": "clue.prisao_carta_na_cela.body",
	},
	"prisao_grito_nas_correntes": {
		"mundo": "world.prison",
		"titulo": "clue.prisao_grito_nas_correntes.title",
		"texto": "clue.prisao_grito_nas_correntes.body",
	},
	"torres_lanterna_de_zeriko": {
		"mundo": "world.towers",
		"titulo": "clue.torres_lanterna_de_zeriko.title",
		"texto": "clue.torres_lanterna_de_zeriko.body",
	},
	"torres_sussurro_da_mae": {
		"mundo": "world.towers",
		"titulo": "clue.torres_sussurro_da_mae.title",
		"texto": "clue.torres_sussurro_da_mae.body",
	},
	"castelo_aurora_livre": {
		"mundo": "world.castle",
		"titulo": "clue.castelo_aurora_livre.title",
		"texto": "clue.castelo_aurora_livre.body",
	},
}


## Lista de entradas (chaves de tradução) para os ids dados, pela ordem em
## que foram encontrados. Ids sem pista escrita: `titulo` = o próprio id,
## `texto` = "" (o diário mostra o aviso "por escrever").
static func entradas(ids: Array) -> Array:
	var lista: Array = []
	for id: String in ids:
		var p: Dictionary = PISTAS.get(id, {})
		lista.append({
			"id": id,
			"mundo": p.get("mundo", "world.unknown"),
			"titulo": p.get("titulo", id),
			"texto": p.get("texto", ""),
		})
	return lista


## Quantas pistas existem no total no jogo (para "3 / 8").
static func total_no_jogo() -> int:
	return PISTAS.size()
