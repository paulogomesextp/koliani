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


func _ready() -> void:
	carregar()


## --- Progressao de niveis -------------------------------------------------

func caminho_nivel_atual() -> String:
	return NIVEIS[clampi(indice_nivel, 0, NIVEIS.size() - 1)]


func ha_proximo_nivel() -> bool:
	return indice_nivel + 1 < NIVEIS.size()


func avancar_nivel() -> void:
	if ha_proximo_nivel():
		indice_nivel += 1
		checkpoint = Vector2.ZERO
		guardar()


## --- Vidas / morte ------------------------------------------------------

func perder_vida() -> void:
	vidas = maxi(0, vidas - 1)
	vidas_mudaram.emit(vidas)
	guardar()


func sem_vidas() -> bool:
	return vidas <= 0


## Há um save no disco E com progresso feito (não é um arranque limpo)?
## Usado pelo menu inicial para decidir se mostra "Continuar".
func ha_progresso() -> bool:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return false
	return indice_nivel > 0 or checkpoint != Vector2.ZERO \
		or not habilidades.is_empty() or not pistas.is_empty()


func reiniciar_campanha() -> void:
	vidas = VIDAS_INICIAIS
	indice_nivel = 0
	checkpoint = Vector2.ZERO
	habilidades.clear()
	pistas.clear()
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
	}


func de_dicionario(d: Dictionary) -> void:
	vidas = int(d.get("vidas", VIDAS_INICIAIS))
	indice_nivel = int(d.get("indice_nivel", 0))
	var c: Array = d.get("checkpoint", [0, 0])
	checkpoint = Vector2(c[0], c[1]) if c.size() == 2 else Vector2.ZERO
	habilidades.assign(d.get("habilidades", []))
	pistas.assign(d.get("pistas", []))


func guardar() -> void:
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if f == null:
		push_warning("Nao consegui gravar o progresso em %s" % CAMINHO_SAVE)
		return
	f.store_string(JSON.stringify(para_dicionario(), "\t"))
	f.close()


func carregar() -> void:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if f == null:
		return
	var dados: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if dados is Dictionary:
		de_dicionario(dados)
