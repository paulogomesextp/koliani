extends Node
## Estado global do jogo (autoload "EstadoJogo").
##
## Guarda o progresso da Koliani entre niveis e entre sessoes: vidas,
## mundo/nivel atual, checkpoint ativo, habilidades desbloqueadas e as
## pistas sobre a mae ja encontradas. Toda a logica aqui e pura o
## suficiente para ser testada com `godot --headless` (ver tests/).
##
## Save simples em JSON em `user://progresso.json`. Sem servidor.

const CAMINHO_SAVE := "user://progresso.json"

const VIDAS_INICIAIS := 3

## Modo hardcore: tempo (segundos) para completar cada mundo. Ao esgotar ->
## Game Over e a campanha recomeça do mundo 1. Números de partida -- afinar
## com o jogo a correr.
const TEMPO_HARDCORE := [90.0, 120.0, 120.0, 150.0]

## Sequencia fixa de mundos ate ao Zeriko (platformer por niveis, nao
## roguelite). O agente "gaming" acrescenta/renomeia niveis aqui a medida
## que os desenha; a ordem desta lista E a ordem da campanha.
const NIVEIS := [
	"res://scenes/levels/Floresta_Putrefata.tscn",
	"res://scenes/levels/Prisao_dos_Condenados.tscn",
	"res://scenes/levels/Torres_Esquecidas.tscn",
	"res://scenes/levels/Castelo_de_Zeriko.tscn",
]
# "res://scenes/levels/Level_Test.tscn" fica no repo como sala de treino,
# fora da campanha (correr a cena diretamente no editor).

signal vidas_mudaram(vidas: int)
signal pista_encontrada(id: String, total: int)
signal habilidade_desbloqueada(id: String)

var vidas: int = VIDAS_INICIAIS
var indice_nivel: int = 0
## Posicao do ultimo checkpoint tocado no nivel atual (Vector2.ZERO = usar
## o ponto de spawn do proprio nivel).
var checkpoint: Vector2 = Vector2.ZERO
var habilidades: Array[String] = []
var pistas: Array[String] = []
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
	if ha_proximo_nivel():
		indice_nivel += 1
		checkpoint = Vector2.ZERO
		hardcore_tempo_restante = -1.0  # mundo novo = relógio cheio
		guardar()


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


func reiniciar_campanha() -> void:
	vidas = VIDAS_INICIAIS
	indice_nivel = 0
	checkpoint = Vector2.ZERO
	habilidades.clear()
	pistas.clear()
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
