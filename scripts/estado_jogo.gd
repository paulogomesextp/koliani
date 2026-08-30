extends Node
## Estado global do jogo (autoload "EstadoJogo").
##
## Guarda o progresso da Koliani entre niveis e entre sessoes: vidas,
## mundo/nivel atual, checkpoint ativo, habilidades desbloqueadas, pistas
## sobre a mae e que niveis/regioes ja foram concluidos. Toda a logica aqui e pura o
## suficiente para ser testada com `godot --headless` (ver tests/).
##
## Save simples em JSON em `user://progresso.json`. Sem servidor.

const CAMINHO_SAVE := "user://progresso.json"

## Tabela do equipamento. `preload` por caminho (e não o nome global
## `Equipamento`) porque este autoload é o 1.º a arrancar -- não pode
## depender do registo de classes globais ainda estar pronto.
const _EQUIP := preload("res://scripts/equipamento.gd")

const VIDAS_INICIAIS := 3

## Todas as habilidades da campanha (o modo dev desbloqueia-as de uma vez).
const HABILIDADES_TODAS := ["salto_duplo", "dash_aereo", "partir_paredes", "escudo", "projetil", "escalar_paredes"]

## Modo hardcore: tempo (segundos) para completar cada NÍVEL. Ao esgotar ->
## Game Over e a campanha recomeça do nível 1. Uma entrada por nível (mesma
## ordem de `NIVEIS`), a subir por região e com folga extra nos níveis-fim
## de região; o nível 30 (Zeriko, 4 formas) leva o dobro. Ainda "a olho" --
## afinar com o jogo a correr.
const TEMPO_HARDCORE := [
	95.0, 105.0, 110.0, 115.0, 130.0,      # I   Floresta
	120.0, 125.0, 130.0, 135.0, 150.0,     # II  Prisão
	135.0, 140.0, 145.0, 150.0, 170.0,     # III Torres
	150.0, 155.0, 160.0, 165.0, 185.0,     # IV  Catacumbas
	165.0, 170.0, 175.0, 180.0, 200.0,     # V   Cidade
	180.0, 185.0, 190.0, 195.0, 240.0,     # VI  Castelo (+ Zeriko)
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
]
# "res://scenes/levels/Level_Test.tscn" fica no repo como sala de treino,
# fora da campanha (correr a cena diretamente no editor).

## As 6 regioes da campanha-alvo (plano completo em `docs/niveis.md`). Cada
## regiao agrupa indices de `NIVEIS`; o menu/mapa passa a listar regioes e o
## seu estado de conclusao. Uma regiao com `niveis` vazio ainda esta por
## construir -- o agente vai enchendo `NIVEIS` e estes indices a medida que
## desenha os niveis. A ordem aqui E a ordem das regioes na campanha.
const REGIOES := [
	{"id": "floresta", "nome": "Floresta Putrefacta", "niveis": [0, 1, 2, 3, 4]},
	{"id": "prisao", "nome": "Prisao dos Condenados", "niveis": [5, 6, 7, 8, 9]},
	{"id": "torres", "nome": "Torres Esquecidas", "niveis": [10, 11, 12, 13, 14]},
	{"id": "catacumbas", "nome": "Catacumbas do Abismo", "niveis": [15, 16, 17, 18, 19]},
	{"id": "cidade", "nome": "Cidade Corrompida", "niveis": [20, 21, 22, 23, 24]},
	{"id": "castelo", "nome": "Castelo de Zeriko", "niveis": [25, 26, 27, 28, 29]},
]

signal vidas_mudaram(vidas: int)
signal pista_encontrada(id: String, total: int)
signal habilidade_desbloqueada(id: String)
## Ganhou-se um equipamento ao acabar um nível (`tipo` = "arma"|"armadura").
signal equipamento_ganho(tipo: String, id: String)
## Trocou-se a arma ou a armadura equipada.
signal equipamento_mudou(tipo: String, id: String)

## Dano do ataque corpo-a-corpo sem arma equipada (punhos/lâmina base).
const DANO_BASE := 25

var vidas: int = VIDAS_INICIAIS
var indice_nivel: int = 0
## Posicao do ultimo checkpoint tocado no nivel atual (Vector2.ZERO = usar
## o ponto de spawn do proprio nivel).
var checkpoint: Vector2 = Vector2.ZERO
var habilidades: Array[String] = []
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

## Modo de testes do Paulo ("PAULITOS JENSATH DEV MODE"): habilidades todas,
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


func avancar_nivel() -> void:
	marcar_nivel_concluido(indice_nivel)
	if ha_proximo_nivel():
		indice_nivel += 1
		checkpoint = Vector2.ZERO
		hardcore_tempo_restante = -1.0  # mundo novo = relógio cheio
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
func conceder_recompensa(indice: int) -> void:
	var r: Dictionary = _EQUIP.recompensa_do_nivel(indice)
	if r.is_empty():
		return
	var id: String = r["id"]
	if r["tipo"] == "arma":
		if id in armas:
			return
		armas.append(id)
		var atual: Dictionary = _EQUIP.arma(arma_equipada)
		var nova: Dictionary = _EQUIP.arma(id)
		if arma_equipada == "" or int(nova.get("dano", 0)) >= int(atual.get("dano", 0)):
			arma_equipada = id
			equipamento_mudou.emit("arma", id)
	else:
		if id in armaduras:
			return
		armaduras.append(id)
		var atual2: Dictionary = _EQUIP.armadura(armadura_equipada)
		var nova2: Dictionary = _EQUIP.armadura(id)
		if armadura_equipada == "" or int(nova2.get("vida_bonus", 0)) >= int(atual2.get("vida_bonus", 0)):
			armadura_equipada = id
			equipamento_mudou.emit("armadura", id)
	equipamento_ganho.emit(r["tipo"], id)
	guardar()


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
	return int(a.get("dano", DANO_BASE)) if not a.is_empty() else DANO_BASE


## Vida máxima extra dada pela armadura equipada.
func vida_bonus_armadura() -> int:
	return int(_EQUIP.armadura(armadura_equipada).get("vida_bonus", 0))


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
	return indice_nivel > 0 or checkpoint != Vector2.ZERO \
		or not habilidades.is_empty() or not pistas.is_empty()


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


func reiniciar_campanha() -> void:
	modo_dev = false
	vidas = VIDAS_INICIAIS
	indice_nivel = 0
	checkpoint = Vector2.ZERO
	habilidades.clear()
	pistas.clear()
	concluidos.clear()
	armas.clear()
	armaduras.clear()
	arma_equipada = ""
	armadura_equipada = ""
	hardcore_tempo_restante = -1.0  # NB: `hardcore` (o modo) fica como está
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


func tem_habilidade(id: String) -> bool:
	return id in habilidades


func registar_pista(id: String) -> void:
	if id in pistas:
		return
	pistas.append(id)
	pista_encontrada.emit(id, pistas.size())
	guardar()


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
	}


func de_dicionario(d: Dictionary) -> void:
	vidas = int(d.get("vidas", VIDAS_INICIAIS))
	indice_nivel = int(d.get("indice_nivel", 0))
	var c: Array = d.get("checkpoint", [0, 0])
	checkpoint = Vector2(c[0], c[1]) if c.size() == 2 else Vector2.ZERO
	habilidades.assign(d.get("habilidades", []))
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


func guardar() -> void:
	if modo_teste:
		return
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if f == null:
		push_warning("Nao consegui gravar o progresso em %s" % CAMINHO_SAVE)
		return
	f.store_string(JSON.stringify(para_dicionario(), "\t"))
	f.close()


func carregar() -> void:
	if modo_teste:
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
