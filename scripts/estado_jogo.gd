extends Node
## Estado global do jogo (autoload "EstadoJogo").
##
## Guarda o progresso da Koliani entre niveis e entre sessoes: vidas,
## mundo/nivel atual, checkpoint ativo, habilidades desbloqueadas, pistas
## sobre a mae e que niveis/regioes ja foram concluidos. Toda a logica aqui e pura o
## suficiente para ser testada com `godot --headless` (ver tests/).
##
## Save simples em JSON em `user://progresso.json`. Sem servidor.

## O modo HARDCORE **não persiste** (é esse o conceito -- perder = recomeçar
## tudo, game over). Só o modo normal grava, e num ficheiro que o hardcore
## nunca toca. Ver `guardar()`/`carregar()`.
const CAMINHO_SAVE := "user://progresso.json"

## Tabela do equipamento. `preload` por caminho (e não o nome global
## `Equipamento`) porque este autoload é o 1.º a arrancar -- não pode
## depender do registo de classes globais ainda estar pronto.
const _EQUIP := preload("res://scripts/equipamento.gd")
const _MELHORIAS := preload("res://scripts/melhorias.gd")

## Vidas com que se começa a campanha. Pedido do Paulo (4 set 2026): eram 3,
## passam a 5, e cada nível concluído dá +1 (ver `avancar_nivel`).
const VIDAS_INICIAIS := 5
## Vidas ganhas por cada nível concluído.
const VIDAS_POR_NIVEL := 1
## Tecto, só para o "x%d" do HUD nunca crescer sem fim -- ao ritmo de +1 por
## nível, 100 níveis dariam 105 vidas.
const VIDAS_MAX := 99

## Todas as habilidades da campanha (o modo dev desbloqueia-as de uma vez).
const HABILIDADES_TODAS := ["salto_duplo", "dash_aereo", "partir_paredes", "escudo", "projetil", "escalar_paredes", "planar"]
## Habilidades que a Koliani já tem no arranque da campanha (nível 1). O
## salto duplo deixou de ser um Coletavel a caçar: é básico desde o início
## (ver koliani.gd). Garantido em `reiniciar_campanha()` e ao carregar saves
## antigos que ainda não o tinham.
const HABILIDADES_INICIAIS: Array[String] = ["salto_duplo"]

## Modo hardcore: tempo (segundos) para completar cada NÍVEL. Ao esgotar ->
## Game Over e a campanha recomeça do nível 1. Uma entrada por nível (mesma
## ordem de `NIVEIS`), a subir por região e com folga extra nos níveis-fim
## de região; o nível 30 (Zeriko, 4 formas) leva o mais tempo. Ainda "a olho".
# NB (2 set 2026): reperfilado outra vez -- `comprimento_base` da Jornada
# desceu de 6200 para 1800 (nível 1 "básico, ~1 minuto") e `por_nivel` subiu
# de 880 para 1050 (para o nível 30 continuar a chegar perto do
# comprimento_max de antes). Estes valores escalam pela MESMA proporção
# (comprimento novo / antigo, nível a nível) em vez de reinventar as
# margens -- mantém a forma já afinada, só corrige o comprimento.
const TEMPO_HARDCORE := [
	49.0, 74.0, 98.0, 120.0, 154.0,        # I   Floresta
	146.0, 166.0, 185.0, 204.0, 239.0,     # II  Prisão
	221.0, 240.0, 258.0, 276.0, 316.0,     # III Torres
	289.0, 307.0, 325.0, 343.0, 389.0,     # IV  Catacumbas
	354.0, 372.0, 390.0, 407.0, 455.0,     # V   Cidade
	418.0, 435.0, 453.0, 470.0, 646.0,     # VI  Castelo (+ Zeriko)
]

## Sequencia fixa de mundos ate ao Zeriko (platformer por niveis, nao
## roguelite). O agente "gaming" acrescenta/renomeia niveis aqui a medida
## que os desenha; a ordem desta lista E a ordem da campanha.
const NIVEIS := [
	"res://scenes/levels/Floresta_Putrefata.tscn",
	"res://scenes/levels/Pantano_dos_Sussurros.tscn",
	"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
	"res://scenes/levels/A_Arvore_que_Chora.tscn",
	"res://scenes/levels/Coracao_da_Floresta.tscn",
	"res://scenes/levels/Prisao_dos_Condenados.tscn",
	"res://scenes/levels/Fornalha_dos_Pecadores.tscn",
	"res://scenes/levels/Corredor_das_Execucoes.tscn",
	"res://scenes/levels/Ala_dos_Mortos.tscn",
	"res://scenes/levels/A_Cela_Zero.tscn",
	"res://scenes/levels/Torre_dos_Sinos.tscn",
	"res://scenes/levels/Torre_dos_Ventos.tscn",
	"res://scenes/levels/Torre_da_Tempestade.tscn",
	"res://scenes/levels/Observatorio_Lunar.tscn",
	"res://scenes/levels/O_Pico_Esquecido.tscn",
	"res://scenes/levels/Cemiterio_dos_Reis.tscn",
	"res://scenes/levels/Galeria_dos_Ossos.tscn",
	"res://scenes/levels/Cripta_das_Mil_Velas.tscn",
	"res://scenes/levels/Templo_da_Serpente.tscn",
	"res://scenes/levels/O_Abismo.tscn",
	"res://scenes/levels/Vila_dos_Sem_Rosto.tscn",
	"res://scenes/levels/Mercado_da_Carne.tscn",
	"res://scenes/levels/Trem_dos_Mortos.tscn",
	"res://scenes/levels/Catedral_da_Corrupcao.tscn",
	"res://scenes/levels/Praca_do_Eclipse.tscn",
	"res://scenes/levels/Portoes_de_Zeriko.tscn",
	"res://scenes/levels/Salao_dos_Espelhos.tscn",
	"res://scenes/levels/Banquete_dos_Imortais.tscn",
	"res://scenes/levels/Torre_do_Coracao_Negro.tscn",
	"res://scenes/levels/O_Trono_de_Zeriko.tscn",
	# --- niveis 31-100 (docs/plano_niveis_31_100.md) ---------------------
	"res://scenes/levels/Estrada_das_Cinzas.tscn",
	"res://scenes/levels/Rio_de_Magma.tscn",
	"res://scenes/levels/A_Forja_dos_Demonios.tscn",
	"res://scenes/levels/Vulcao_do_Rei_Morto.tscn",
	"res://scenes/levels/O_Ceu_em_Chamas.tscn",
	"res://scenes/levels/Porto_dos_Afogados.tscn",
	"res://scenes/levels/Cidade_Submersa.tscn",
	"res://scenes/levels/Palacio_das_Sereias_Mortas.tscn",
	"res://scenes/levels/Ossario_das_Baleias.tscn",
	"res://scenes/levels/Abismo_Oceanico.tscn",
	"res://scenes/levels/Floresta_Congelada.tscn",
	"res://scenes/levels/Montanha_dos_Ventos.tscn",
	"res://scenes/levels/Cavernas_Cristalinas.tscn",
	"res://scenes/levels/Castelo_Congelado.tscn",
	"res://scenes/levels/Coracao_do_Inverno.tscn",
	"res://scenes/levels/Mar_de_Areia.tscn",
	"res://scenes/levels/Templo_Sem_Nome.tscn",
	"res://scenes/levels/Vale_dos_Escorpioes.tscn",
	"res://scenes/levels/Cidade_Enterrada.tscn",
	"res://scenes/levels/Piramide_Negra.tscn",
	"res://scenes/levels/Jardim_das_Rosas_Negras.tscn",
	"res://scenes/levels/Labirinto_Verde.tscn",
	"res://scenes/levels/Jardim_das_Almas.tscn",
	"res://scenes/levels/Estufa_Maldita.tscn",
	"res://scenes/levels/Arvore_do_Rei.tscn",
	"res://scenes/levels/Distrito_das_Engrenagens.tscn",
	"res://scenes/levels/Linha_13.tscn",
	"res://scenes/levels/Fabrica_dos_Homunculos.tscn",
	"res://scenes/levels/Torre_Electrica.tscn",
	"res://scenes/levels/Coracao_da_Maquina.tscn",
	"res://scenes/levels/Ilhas_Flutuantes.tscn",
	"res://scenes/levels/Templo_do_Trovao.tscn",
	"res://scenes/levels/Cidade_dos_Anjos_Mortos.tscn",
	"res://scenes/levels/Lua_Quebrada.tscn",
	"res://scenes/levels/O_Fim_do_Ceu.tscn",
	"res://scenes/levels/Vila_dos_Sonhos.tscn",
	"res://scenes/levels/Mundo_Invertido.tscn",
	"res://scenes/levels/Quarto_das_Criancas_Mortas.tscn",
	"res://scenes/levels/Pesadelo.tscn",
	"res://scenes/levels/A_Mente.tscn",
	"res://scenes/levels/Avenida_dos_Mortos.tscn",
	"res://scenes/levels/Cemiterio_Infinito.tscn",
	"res://scenes/levels/Catedral_Fantasma.tscn",
	"res://scenes/levels/Palacio_dos_Reis_Mortos.tscn",
	"res://scenes/levels/Trono_da_Morte.tscn",
	"res://scenes/levels/Margem_do_Sangue.tscn",
	"res://scenes/levels/Serpentes_do_Mar.tscn",
	"res://scenes/levels/Navio_da_Condenacao.tscn",
	"res://scenes/levels/Fortaleza_Kraken.tscn",
	"res://scenes/levels/Coracao_Vermelho.tscn",
	"res://scenes/levels/Portao_Infernal.tscn",
	"res://scenes/levels/Cidade_dos_Demonios.tscn",
	"res://scenes/levels/Rio_das_Almas.tscn",
	"res://scenes/levels/Palacio_de_Sangue.tscn",
	"res://scenes/levels/Trono_Infernal.tscn",
	"res://scenes/levels/Primeiro_Vazio.tscn",
	"res://scenes/levels/Segundo_Vazio.tscn",
	"res://scenes/levels/Labirinto_Impossivel.tscn",
	"res://scenes/levels/A_Coisa_Atras_do_Mundo.tscn",
	"res://scenes/levels/Centro_do_Vazio.tscn",
	"res://scenes/levels/Campo_de_Batalha.tscn",
	"res://scenes/levels/Ceu_em_Guerra.tscn",
	"res://scenes/levels/Cerco_ao_Castelo.tscn",
	"res://scenes/levels/Torre_da_Corrupcao.tscn",
	"res://scenes/levels/Os_Cem_Guerreiros.tscn",
	"res://scenes/levels/O_Reino_Antes_da_Corrupcao.tscn",
	"res://scenes/levels/O_Primeiro_Castelo.tscn",
	"res://scenes/levels/O_Coracao_de_Zeriko.tscn",
	"res://scenes/levels/O_Fim_de_Tudo.tscn",
	"res://scenes/levels/O_Ultimo_Salto.tscn",
]
# "res://scenes/levels/Level_Test.tscn" fica no repo como sala de treino,
# fora da campanha (correr a cena diretamente no editor).

## As 20 regioes da campanha (5 niveis cada; plano em `docs/niveis.md` e
## `docs/plano_niveis_31_100.md`). Cada regiao agrupa indices de `NIVEIS`;
## o mapa, o carrossel e o cabecalho da HUD leem esta tabela. A ordem aqui
## E a ordem das regioes na campanha.
##
##   chave -- chave i18n do nome (`world.*` nos 6 assets/i18n/*.json). O
##            campo `nome` e' so' para as ferramentas e para os logs: o que
##            o jogador ve' vem sempre da chave.
##   cor   -- a cor do luar da regiao (o `cor_luz` do seu primeiro nivel).
##            Serve as pastilhas do carrossel e o cabecalho da HUD, para
##            cada regiao ter a sua cor mesmo antes de se ver o cenario.
const REGIOES := [
	{"id": "floresta", "nome": "Floresta Putrefacta", "niveis": [0, 1, 2, 3, 4], "chave": "world.forest", "cor": Color(0.62, 1.00, 0.72)},
	{"id": "prisao", "nome": "Prisao dos Condenados", "niveis": [5, 6, 7, 8, 9], "chave": "world.prison", "cor": Color(0.60, 0.68, 1.00)},
	{"id": "torres", "nome": "Torres Esquecidas", "niveis": [10, 11, 12, 13, 14], "chave": "world.towers", "cor": Color(1.00, 0.74, 0.46)},
	{"id": "catacumbas", "nome": "Catacumbas do Abismo", "niveis": [15, 16, 17, 18, 19], "chave": "world.catacombs", "cor": Color(0.86, 0.70, 0.78)},
	{"id": "cidade", "nome": "Cidade Corrompida", "niveis": [20, 21, 22, 23, 24], "chave": "world.city", "cor": Color(1.00, 0.62, 0.72)},
	{"id": "castelo", "nome": "Castelo de Zeriko", "niveis": [25, 26, 27, 28, 29], "chave": "world.castle", "cor": Color(1.00, 0.44, 0.96)},
	{"id": "queimadas", "nome": "Terras Queimadas", "niveis": [30, 31, 32, 33, 34], "chave": "world.burned", "cor": Color(1.00, 0.52, 0.18)},
	{"id": "mar", "nome": "Mar dos Mortos", "niveis": [35, 36, 37, 38, 39], "chave": "world.deadsea", "cor": Color(0.42, 0.90, 0.98)},
	{"id": "gelo", "nome": "Reino do Gelo", "niveis": [40, 41, 42, 43, 44], "chave": "world.ice", "cor": Color(0.80, 0.96, 1.00)},
	{"id": "deserto", "nome": "Deserto dos Esquecidos", "niveis": [45, 46, 47, 48, 49], "chave": "world.desert", "cor": Color(1.00, 0.86, 0.48)},
	{"id": "jardins", "nome": "Jardins do Rei", "niveis": [50, 51, 52, 53, 54], "chave": "world.gardens", "cor": Color(0.90, 0.30, 0.52)},
	{"id": "maquinas", "nome": "Cidade das Máquinas", "niveis": [55, 56, 57, 58, 59], "chave": "world.machines", "cor": Color(0.55, 0.85, 1.00)},
	{"id": "ceu", "nome": "Céu Partido", "niveis": [60, 61, 62, 63, 64], "chave": "world.sky", "cor": Color(0.62, 0.70, 1.00)},
	{"id": "sonhos", "nome": "Reino dos Sonhos", "niveis": [65, 66, 67, 68, 69], "chave": "world.dreams", "cor": Color(0.92, 0.66, 0.96)},
	{"id": "mortos", "nome": "Cidade dos Mortos", "niveis": [70, 71, 72, 73, 74], "chave": "world.deadcity", "cor": Color(0.72, 0.92, 0.80)},
	{"id": "mar_vermelho", "nome": "Mar Vermelho", "niveis": [75, 76, 77, 78, 79], "chave": "world.redsea", "cor": Color(1.00, 0.30, 0.32)},
	{"id": "inferno", "nome": "Inferno", "niveis": [80, 81, 82, 83, 84], "chave": "world.hell", "cor": Color(1.00, 0.52, 0.10)},
	{"id": "vazio", "nome": "O Vazio", "niveis": [85, 86, 87, 88, 89], "chave": "world.void", "cor": Color(0.86, 0.80, 1.00)},
	{"id": "guerra", "nome": "Guerra dos Reinos", "niveis": [90, 91, 92, 93, 94], "chave": "world.war", "cor": Color(1.00, 0.74, 0.44)},
	{"id": "ultimo", "nome": "O Último Caminho", "niveis": [95, 96, 97, 98, 99], "chave": "world.lastroad", "cor": Color(1.00, 0.92, 0.60)},
]

signal vidas_mudaram(vidas: int)
signal pista_encontrada(id: String, total: int)
signal habilidade_desbloqueada(id: String)
## Ganhou-se um equipamento ao acabar um nível (`tipo` = "arma"|"armadura").
## Economia: total de essência mudou / uma melhoria subiu de rank.
signal essencia_mudou(total: int)
signal melhoria_comprada(id: String, rank: int)
signal equipamento_ganho(tipo: String, id: String)
## Trocou-se a arma ou a armadura equipada.
signal equipamento_mudou(tipo: String, id: String)

## Dano do ataque corpo-a-corpo sem arma equipada (punhos/lâmina base).
## Dano-base DUPLICADO a pedido do Paulo (ago 2026) -- espada e tiros o dobro.
const DANO_BASE := 50

var vidas: int = VIDAS_INICIAIS
var indice_nivel: int = 0
## Posicao do ultimo checkpoint tocado no nivel atual (Vector2.ZERO = usar
## o ponto de spawn do proprio nivel).
var checkpoint: Vector2 = Vector2.ZERO
var habilidades: Array[String] = HABILIDADES_INICIAIS.duplicate()
var pistas: Array[String] = []
## Equipamento ganho ao longo da campanha (ids de `Equipamento.ARMAS` /
## `.ARMADURAS`). `*_equipada` = o que está a ser usado ("" = nada).
var armas: Array[String] = []
var armaduras: Array[String] = []
var arma_equipada: String = ""
var armadura_equipada: String = ""
## Indices de `NIVEIS` ja concluidos (Porta atravessada). Sobrevive ao save;
## `reiniciar_campanha()` limpa. E' o que o mapa de regioes usa para marcar
## niveis/regioes como feitos.
var concluidos: Array[int] = []

## --- ECONOMIA -------------------------------------------------------------
## Essência: moeda mágica largada por inimigos + em caches nas alcovas dos
## níveis. Gasta-se no Santuário em MELHORIAS permanentes (`melhorias.gd`).
## NÃO se perde na morte (jogo por níveis). `reiniciar_campanha()` zera.
var essencia: int = 0
## id da melhoria -> rank atual (int, 0..Melhorias.max_rank).
var melhorias: Dictionary = {}

## Campanha a decorrer em modo hardcore (tempo limite por mundo). Fica
## gravada no save -- um LOAD GAME retoma no mesmo modo. O menu inicial é
## que a liga/desliga; `reiniciar_campanha()` de propósito NÃO lhe mexe
## (assim o Game Over do hardcore recomeça já em hardcore).
var hardcore: bool = false
## Segundos que faltam no relógio do mundo atual (modo hardcore). < 0 =
## "ainda não começou / recomeçar cheio". Gravado no save e mantido em
## memória através das mortes -- por isso o tempo **continua a contar** a
## cada morte; só `avancar_nivel()` / `reiniciar_campanha()` o repõem.
var hardcore_tempo_restante: float = -1.0

## Posto a true pelos testes (ver tests/run_tests.gd) para NÃO tocar no
## ficheiro de save real ao instanciar o estado fora do jogo.
var modo_teste: bool = false

## Âncora da JORNADA de aproximação do nível atual (ver `gerador_corredor.gd`):
## o ponto onde a Koliani nasceria SEM jornada. Fica em memória (não é
## gravada) para a jornada se reconstruir igual a cada morte/recarga -- se
## fosse recalculada da posição atual da Koliani, um respawn num checkpoint
## a meio partia a geometria. Limpa-se ao mudar de nível.
var _jornada_ancora: Vector2 = Vector2.ZERO
var _jornada_ancora_idx: int = -1


## Devolve a âncora da jornada para o nível `idx`, calculando-a uma vez
## (na 1.ª entrada fresca) com `calcular` e reutilizando-a nas recargas.
func jornada_ancora_para(idx: int, calcular: Callable) -> Vector2:
	if _jornada_ancora_idx != idx:
		_jornada_ancora = calcular.call()
		_jornada_ancora_idx = idx
	return _jornada_ancora


func _limpar_jornada_ancora() -> void:
	_jornada_ancora = Vector2.ZERO
	_jornada_ancora_idx = -1

## Modo de testes do Paulo ("DEVELOPER MODE"): habilidades todas,
## energia infinita e sem perder vida (ver koliani.gd). NÃO é gravado no
## save -- vive só nesta sessão e o save real fica intacto.
var modo_dev: bool = false


func _ready() -> void:
	carregar()


## --- Progressao de niveis -------------------------------------------------

func caminho_nivel_atual() -> String:
	return NIVEIS[clampi(indice_nivel, 0, NIVEIS.size() - 1)]


func ha_proximo_nivel() -> bool:
	return indice_nivel + 1 < NIVEIS.size()


## Tempo limite (segundos) do mundo atual em modo hardcore.
func tempo_hardcore_nivel() -> float:
	return TEMPO_HARDCORE[clampi(indice_nivel, 0, TEMPO_HARDCORE.size() - 1)]


## Posto a true quando `avancar_nivel()` salta mesmo de nível; a cena de
## jogo lê-o uma vez (banner "Avançou para o Nível N") e limpa. Não é
## gravado -- vive só entre a Porta e o `_ready` do nível seguinte.
var anunciar_avanco := false


func avancar_nivel() -> void:
	marcar_nivel_concluido(indice_nivel)
	if ha_proximo_nivel():
		# +1 vida por nível passado (pedido do Paulo). No hardcore não: lá as
		# vidas são o próprio limite do run.
		if not hardcore:
			vidas = mini(VIDAS_MAX, vidas + VIDAS_POR_NIVEL)
			vidas_mudaram.emit(vidas)
		indice_nivel += 1
		checkpoint = Vector2.ZERO
		hardcore_tempo_restante = -1.0  # mundo novo = relógio cheio
		anunciar_avanco = true
		_limpar_jornada_ancora()
		guardar()


## --- Regiões / conclusão ---------------------------------------------------

func marcar_nivel_concluido(indice: int) -> void:
	if indice < 0 or indice >= NIVEIS.size() or indice in concluidos:
		return
	concluidos.append(indice)
	concluidos.sort()
	conceder_recompensa(indice)
	guardar()


## --- Equipamento (armas / armaduras) -------------------------------------

## Dá o equipamento por acabar o nível `indice` (0-based). Equipa-o já se o
## slot estiver vazio ou se for melhor que o atual. Idempotente por id.
##
## Desde 3 set 2026 um nível pode dar DOIS prémios (nos múltiplos de 10 cai
## uma arma e uma armadura) -- ver `Equipamento.recompensas_do_nivel`.
func conceder_recompensa(indice: int) -> void:
	var houve := false
	for r: Dictionary in _EQUIP.recompensas_do_nivel(indice):
		if _conceder_um(r):
			houve = true
	if houve:
		guardar()


## Um prémio. Devolve `true` se era novo (e portanto vale a pena gravar).
func _conceder_um(r: Dictionary) -> bool:
	var id: String = r["id"]
	if r["tipo"] == "arma":
		if id in armas:
			return false
		armas.append(id)
		var atual: Dictionary = _EQUIP.arma(arma_equipada)
		var nova: Dictionary = _EQUIP.arma(id)
		if arma_equipada == "" or int(nova.get("dano", 0)) >= int(atual.get("dano", 0)):
			arma_equipada = id
			equipamento_mudou.emit("arma", id)
	else:
		if id in armaduras:
			return false
		armaduras.append(id)
		var atual2: Dictionary = _EQUIP.armadura(armadura_equipada)
		var nova2: Dictionary = _EQUIP.armadura(id)
		if armadura_equipada == "" or int(nova2.get("vida_bonus", 0)) >= int(atual2.get("vida_bonus", 0)):
			armadura_equipada = id
			equipamento_mudou.emit("armadura", id)
	equipamento_ganho.emit(r["tipo"], id)
	return true


func tem_arma(id: String) -> bool:
	return id in armas


func tem_armadura(id: String) -> bool:
	return id in armaduras


func equipar_arma(id: String) -> void:
	if id in armas and id != arma_equipada:
		arma_equipada = id
		equipamento_mudou.emit("arma", id)
		guardar()


func equipar_armadura(id: String) -> void:
	if id in armaduras and id != armadura_equipada:
		armadura_equipada = id
		equipamento_mudou.emit("armadura", id)
		guardar()


## Arma seguinte / anterior na lista das que já se têm (troca em jogo).
func ciclar_arma(passo: int) -> void:
	if armas.size() < 2:
		return
	var ordem: Array[String] = []
	for a in _EQUIP.ARMAS:
		if a["id"] in armas:
			ordem.append(a["id"])
	var i := ordem.find(arma_equipada)
	if i < 0:
		i = 0
	equipar_arma(ordem[(i + passo + ordem.size()) % ordem.size()])


## Dano do ataque corpo-a-corpo (arma equipada ou base).
func dano_ataque() -> int:
	var a: Dictionary = _EQUIP.arma(arma_equipada)
	var base: int = int(a.get("dano", DANO_BASE)) if not a.is_empty() else DANO_BASE
	return maxi(1, int(round(base * (1.0 + bonus("dano_mult")))))  # melhoria "forca"


## Vida máxima extra dada pela armadura equipada + melhoria "vitalidade".
func vida_bonus_armadura() -> int:
	return int(_EQUIP.armadura(armadura_equipada).get("vida_bonus", 0)) + int(bonus("vida_max"))


## Fração (0..1) de dano recebido que a armadura equipada corta.
func reducao_armadura() -> float:
	return float(_EQUIP.armadura(armadura_equipada).get("reducao", 0.0))


func nivel_esta_concluido(indice: int) -> bool:
	return indice in concluidos


## Região (0..REGIOES.size()-1) a que pertence o nível `indice`, ou -1.
func regiao_do_nivel(indice: int) -> int:
	for r in REGIOES.size():
		if indice in REGIOES[r]["niveis"]:
			return r
	return -1


## Região do nível que está a ser jogado agora.
func regiao_atual() -> int:
	return regiao_do_nivel(indice_nivel)


## Chave i18n do nome da região do nível `indice` (`world.unknown` se o
## nível estiver fora das regiões -- p.ex. a sala de treino).
func chave_regiao_do_nivel(indice: int) -> String:
	var r := regiao_do_nivel(indice)
	if r < 0:
		return "world.unknown"
	return REGIOES[r].get("chave", "world.unknown")


## Cor do luar da região do nível `indice` (branco fora das regiões).
func cor_regiao_do_nivel(indice: int) -> Color:
	var r := regiao_do_nivel(indice)
	if r < 0:
		return Color.WHITE
	return REGIOES[r].get("cor", Color.WHITE)


## Posição do nível `indice` dentro da sua região: [n, total] com n a começar
## em 1. Fora das regiões devolve [0, 0].
func passo_na_regiao(indice: int) -> Array[int]:
	var r := regiao_do_nivel(indice)
	if r < 0:
		return [0, 0]
	var niveis: Array = REGIOES[r]["niveis"]
	return [niveis.find(indice) + 1, niveis.size()]


## Um nível é jogável no mapa se for o primeiro, se a campanha linear já lá
## chegou (`indice_nivel`), ou se o nível anterior está concluído.
func nivel_desbloqueado(indice: int) -> bool:
	if indice <= 0:
		return true
	if indice >= NIVEIS.size():
		return false
	return indice <= indice_nivel or (indice - 1) in concluidos


## Índice do nível mais avançado que já se pode jogar (a "fronteira").
func fronteira() -> int:
	var f := 0
	for i in NIVEIS.size():
		if nivel_desbloqueado(i):
			f = i
	return f


## Todos os níveis da campanha concluídos?
func campanha_concluida() -> bool:
	for i in NIVEIS.size():
		if i not in concluidos:
			return false
	return true


## Uma região está concluída quando tem níveis e todos estão concluídos.
func regiao_esta_concluida(regiao: int) -> bool:
	if regiao < 0 or regiao >= REGIOES.size():
		return false
	var ns: Array = REGIOES[regiao]["niveis"]
	if ns.is_empty():
		return false
	for i in ns:
		if i not in concluidos:
			return false
	return true


## --- Vidas / morte ------------------------------------------------------

## Vidas com que se (re)começa: as iniciais mais uma por cada nível já
## concluído. Ver `VIDAS_POR_NIVEL`.
func vidas_de_partida() -> int:
	return mini(VIDAS_MAX, VIDAS_INICIAIS + concluidos.size() * VIDAS_POR_NIVEL)


func perder_vida() -> void:
	vidas = maxi(0, vidas - 1)
	vidas_mudaram.emit(vidas)
	guardar()


func sem_vidas() -> bool:
	return vidas <= 0


## Há progresso feito (não é um arranque limpo)? O estado já foi carregado
## do save em `_ready`, por isso basta olhar para os campos. Usado pelo
## menu inicial para decidir se mostra o "LOAD GAME".
func ha_progresso() -> bool:
	# as habilidades iniciais (salto duplo) não contam como progresso
	var habilidade_ganha := habilidades.any(
		func(h: String) -> bool: return h not in HABILIDADES_INICIAIS)
	return indice_nivel > 0 or checkpoint != Vector2.ZERO \
		or habilidade_ganha or not pistas.is_empty()


## Liga o modo de testes: sandbox limpo em memória (nível 1, todas as
## habilidades, muitas vidas) SEM tocar no ficheiro de save -- ao sair do
## jogo o progresso real continua lá. `koliani.gd` lê `modo_dev` para dar
## energia infinita e ignorar dano.
func ativar_modo_dev() -> void:
	modo_dev = true
	hardcore = false
	vidas = 99
	indice_nivel = 0
	checkpoint = Vector2.ZERO
	hardcore_tempo_restante = -1.0
	_limpar_jornada_ancora()
	habilidades.assign(HABILIDADES_TODAS)
	# modo dev: também todo o equipamento desbloqueado (a arma/armadura mais
	# fortes equipadas)
	armas.clear()
	for a in _EQUIP.ARMAS:
		armas.append(a["id"])
	armaduras.clear()
	for a in _EQUIP.ARMADURAS:
		armaduras.append(a["id"])
	arma_equipada = _EQUIP.ARMAS[_EQUIP.ARMAS.size() - 1]["id"]
	armadura_equipada = _EQUIP.ARMADURAS[_EQUIP.ARMADURAS.size() - 1]["id"]
	# pistas/concluidos ficam como estão -- não interessam ao sandbox
	vidas_mudaram.emit(vidas)
	for h in HABILIDADES_TODAS:
		habilidade_desbloqueada.emit(h)
	equipamento_mudou.emit("arma", arma_equipada)
	equipamento_mudou.emit("armadura", armadura_equipada)


## Modo normal: gastaram-se as vidas todas, MAS o progresso fica. Volta-se
## ao início do nível actual (o seguinte ao último chefe morto) com as
## vidas cheias -- habilidades, pistas, níveis concluídos e equipamento
## mantêm-se. (No hardcore isto não corre: lá gastar as vidas é o fim do run.)
##
## As vidas voltam ao valor de PARTIDA para o ponto onde ele já vai -- não a
## 5 secas: com o +1 por nível, mandá-lo de volta às 5 no nível 60 era um
## castigo que o pedido não pede.
func reiniciar_run() -> void:
	vidas = vidas_de_partida()
	checkpoint = Vector2.ZERO
	hardcore_tempo_restante = -1.0  # nova tentativa -> relógio do nível cheio
	_limpar_jornada_ancora()
	# nunca à frente do progresso: nível a seguir ao último chefe derrotado
	var teto := -1
	for i in concluidos:
		teto = maxi(teto, i)
	indice_nivel = clampi(indice_nivel, 0, mini(teto + 1, NIVEIS.size() - 1))
	vidas_mudaram.emit(vidas)
	guardar()


func reiniciar_campanha() -> void:
	modo_dev = false
	vidas = VIDAS_INICIAIS
	indice_nivel = 0
	checkpoint = Vector2.ZERO
	habilidades.assign(HABILIDADES_INICIAIS)
	pistas.clear()
	concluidos.clear()
	armas.clear()
	armaduras.clear()
	arma_equipada = ""
	armadura_equipada = ""
	essencia = 0
	melhorias.clear()
	hardcore_tempo_restante = -1.0  # NB: `hardcore` (o modo) fica como está
	_limpar_jornada_ancora()
	vidas_mudaram.emit(vidas)
	guardar()


## --- Checkpoints ------------------------------------------------------

func definir_checkpoint(posicao: Vector2) -> void:
	checkpoint = posicao
	guardar()


## --- Habilidades / pistas -------------------------------------------------

func desbloquear_habilidade(id: String) -> void:
	if id in habilidades:
		return
	habilidades.append(id)
	habilidade_desbloqueada.emit(id)
	guardar()


## Habilidades SUSPENSAS -- tiradas por uma sala, nao pelo save (nivel 98,
## O Coracao de Zeriko). Vivem so' em memoria e nunca chegam ao ficheiro:
## e' de proposito, porque uma habilidade que se perdesse no disco por
## causa de um crash dentro da sala era um save estragado.
var habilidades_suspensas: Array[String] = []


func suspender_habilidade(id: String) -> void:
	if id != "" and id not in habilidades_suspensas:
		habilidades_suspensas.append(id)


func devolver_habilidade(id: String) -> void:
	habilidades_suspensas.erase(id)


func devolver_habilidades_todas() -> void:
	habilidades_suspensas.clear()


func tem_habilidade(id: String) -> bool:
	return id in habilidades and id not in habilidades_suspensas


func registar_pista(id: String) -> void:
	if id in pistas:
		return
	pistas.append(id)
	pista_encontrada.emit(id, pistas.size())
	guardar()


## --- Economia / Melhorias ---------------------------------------------

func ganhar_essencia(n: int) -> void:
	if n <= 0:
		return
	essencia += n
	essencia_mudou.emit(essencia)
	guardar()


func rank_melhoria(id: String) -> int:
	return int(melhorias.get(id, 0))


## Custo da próxima subida de rank de `id`. -1 = no máximo.
func custo_melhoria(id: String) -> int:
	return _MELHORIAS.custo(id, rank_melhoria(id))


func pode_comprar_melhoria(id: String) -> bool:
	var c := custo_melhoria(id)
	return c >= 0 and essencia >= c


## Compra 1 rank da melhoria `id`. Devolve true se comprou.
func comprar_melhoria(id: String) -> bool:
	if not pode_comprar_melhoria(id):
		return false
	essencia -= custo_melhoria(id)
	melhorias[id] = rank_melhoria(id) + 1
	essencia_mudou.emit(essencia)
	melhoria_comprada.emit(id, melhorias[id])
	guardar()
	return true


## Soma o efeito de TODAS as melhorias cujo `efeito` é `chave`. A Koliani
## chama isto para os bónus: "vida_max", "dano_mult", "regen_energia",
## "iframes_roll", "crit_mult", "escudo_cargas".
func bonus(chave: String) -> float:
	var total := 0.0
	for id: String in melhorias:
		var cfg: Dictionary = _MELHORIAS.CATALOGO.get(id, {})
		if cfg.get("efeito", "") == chave:
			total += _MELHORIAS.efeito_total(id, int(melhorias[id]))
	return total


## --- Persistencia ------------------------------------------------------

func para_dicionario() -> Dictionary:
	return {
		"vidas": vidas,
		"indice_nivel": indice_nivel,
		"checkpoint": [checkpoint.x, checkpoint.y],
		"habilidades": habilidades,
		"pistas": pistas,
		"concluidos": concluidos,
		"armas": armas,
		"armaduras": armaduras,
		"arma_equipada": arma_equipada,
		"armadura_equipada": armadura_equipada,
		"hardcore": hardcore,
		"hardcore_tempo_restante": hardcore_tempo_restante,
		"essencia": essencia,
		"melhorias": melhorias.duplicate(),
	}


func de_dicionario(d: Dictionary) -> void:
	vidas = int(d.get("vidas", VIDAS_INICIAIS))
	indice_nivel = int(d.get("indice_nivel", 0))
	var c: Array = d.get("checkpoint", [0, 0])
	checkpoint = Vector2(c[0], c[1]) if c.size() == 2 else Vector2.ZERO
	habilidades.assign(d.get("habilidades", []))
	# saves antigos (feitos antes de o salto duplo passar a básico) podem não
	# ter as habilidades iniciais -- garante-as sempre
	for h in HABILIDADES_INICIAIS:
		if h not in habilidades:
			habilidades.append(h)
	pistas.assign(d.get("pistas", []))
	armas.assign(d.get("armas", []))
	armaduras.assign(d.get("armaduras", []))
	arma_equipada = str(d.get("arma_equipada", ""))
	armadura_equipada = str(d.get("armadura_equipada", ""))
	# JSON traz os índices como float -> converter para int
	var cs: Array = d.get("concluidos", [])
	concluidos.clear()
	for ci in cs:
		concluidos.append(int(ci))
	hardcore = bool(d.get("hardcore", false))
	hardcore_tempo_restante = float(d.get("hardcore_tempo_restante", -1.0))
	essencia = int(d.get("essencia", 0))
	melhorias.clear()
	var ms: Dictionary = d.get("melhorias", {})
	for k in ms:
		melhorias[str(k)] = int(ms[k])


func guardar() -> void:
	if modo_teste or hardcore:  # hardcore não persiste -- perder = recomeçar tudo
		return
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if f == null:
		push_warning("Nao consegui gravar o progresso em %s" % CAMINHO_SAVE)
		return
	f.store_string(JSON.stringify(para_dicionario(), "\t"))
	f.close()


func carregar() -> void:
	if modo_teste or hardcore:
		return
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if f == null:
		return
	var dados: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if dados is Dictionary:
		de_dicionario(dados)
