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
	"fornalha_marca_do_ferreiro": {
		"mundo": "world.prison",
		"titulo": "clue.fornalha_marca_do_ferreiro.title",
		"texto": "clue.fornalha_marca_do_ferreiro.body",
	},
	"execucoes_lista_de_nomes": {
		"mundo": "world.prison",
		"titulo": "clue.execucoes_lista_de_nomes.title",
		"texto": "clue.execucoes_lista_de_nomes.body",
	},
	"mortos_irmao_mais_novo": {
		"mundo": "world.prison",
		"titulo": "clue.mortos_irmao_mais_novo.title",
		"texto": "clue.mortos_irmao_mais_novo.body",
	},
	"cela_zero_o_primeiro": {
		"mundo": "world.prison",
		"titulo": "clue.cela_zero_o_primeiro.title",
		"texto": "clue.cela_zero_o_primeiro.body",
	},
	"cela_zero_porta_aberta": {
		"mundo": "world.prison",
		"titulo": "clue.cela_zero_porta_aberta.title",
		"texto": "clue.cela_zero_porta_aberta.body",
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
	"sinos_badalada_familiar": {
		"mundo": "world.towers",
		"titulo": "clue.sinos_badalada_familiar.title",
		"texto": "clue.sinos_badalada_familiar.body",
	},
	"tempestade_cajado_de_osso": {
		"mundo": "world.towers",
		"titulo": "clue.tempestade_cajado_de_osso.title",
		"texto": "clue.tempestade_cajado_de_osso.body",
	},
	"torres_lanterna_de_zeriko": {
		"mundo": "world.towers",
		"titulo": "clue.torres_lanterna_de_zeriko.title",
		"texto": "clue.torres_lanterna_de_zeriko.body",
	},
	"lunar_carta_da_sacerdotisa": {
		"mundo": "world.towers",
		"titulo": "clue.lunar_carta_da_sacerdotisa.title",
		"texto": "clue.lunar_carta_da_sacerdotisa.body",
	},
	"torres_sussurro_da_mae": {
		"mundo": "world.towers",
		"titulo": "clue.torres_sussurro_da_mae.title",
		"texto": "clue.torres_sussurro_da_mae.body",
	},
	"pico_escama_de_vyrak": {
		"mundo": "world.towers",
		"titulo": "clue.pico_escama_de_vyrak.title",
		"texto": "clue.pico_escama_de_vyrak.body",
	},
	"pico_torres_para_tras": {
		"mundo": "world.towers",
		"titulo": "clue.pico_torres_para_tras.title",
		"texto": "clue.pico_torres_para_tras.body",
	},
	"catacumbas_coroa_partida": {
		"mundo": "world.catacombs",
		"titulo": "clue.catacumbas_coroa_partida.title",
		"texto": "clue.catacumbas_coroa_partida.body",
	},
	"ossos_placa_do_colosso": {
		"mundo": "world.catacombs",
		"titulo": "clue.ossos_placa_do_colosso.title",
		"texto": "clue.ossos_placa_do_colosso.body",
	},
	"velas_rosario_da_freira": {
		"mundo": "world.catacombs",
		"titulo": "clue.velas_rosario_da_freira.title",
		"texto": "clue.velas_rosario_da_freira.body",
	},
	"serpente_idolo_partido": {
		"mundo": "world.catacombs",
		"titulo": "clue.serpente_idolo_partido.title",
		"texto": "clue.serpente_idolo_partido.body",
	},
	"abismo_o_que_esta_la_em_baixo": {
		"mundo": "world.catacombs",
		"titulo": "clue.abismo_o_que_esta_la_em_baixo.title",
		"texto": "clue.abismo_o_que_esta_la_em_baixo.body",
	},
	"abismo_saida_para_a_cidade": {
		"mundo": "world.catacombs",
		"titulo": "clue.abismo_saida_para_a_cidade.title",
		"texto": "clue.abismo_saida_para_a_cidade.body",
	},
	"vila_retrato_sem_cara": {
		"mundo": "world.city",
		"titulo": "clue.vila_retrato_sem_cara.title",
		"texto": "clue.vila_retrato_sem_cara.body",
	},
	"mercado_gancho_vazio": {
		"mundo": "world.city",
		"titulo": "clue.mercado_gancho_vazio.title",
		"texto": "clue.mercado_gancho_vazio.body",
	},
	"trem_bilhete_so_ida": {
		"mundo": "world.city",
		"titulo": "clue.trem_bilhete_so_ida.title",
		"texto": "clue.trem_bilhete_so_ida.body",
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
