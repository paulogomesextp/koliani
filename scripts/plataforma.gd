@tool
extends StaticBody2D
## Plataforma reutilizavel com TERRENO em camadas (packs CC0 -- ver
## assets/sprites/pixel/CREDITS.md). Define `tamanho` e o resto -- colisao e
## visual -- ajusta-se sozinho. `@tool` para dar para ver no editor.
##
## Ate' 3 set 2026 isto era um `NinePatchRect` com um padrao "seamless"
## recolorido: a 4000 px de largura lia-se como um rectangulo chapado, e as
## 6 regioes eram a mesma laje em 6 tons. Agora cada regiao tem o seu
## material (um pack DIFERENTE por regiao, `tools/gerar_terreno.py`) e o
## terreno monta-se em camadas, que e' o que o faz ler como terreno:
##
##   Capa   -- aresta iluminada + silhueta irregular a sobressair do topo
##   Corpo  -- o miolo do material, em mosaico com deslocamento por plataforma
##   Sombra -- degrade que enterra o fundo da plataforma no escuro
##   Lados  -- o corte lateral lascado
##   Franja -- a rocha a esfarelar-se por baixo
##
## Tudo isto vive dentro do no `Visual` (Node2D), porque meia duzia de
## scripts (plataforma_ritmada/espectral/luz, gerador_corredor, vitral...)
## fazem `get_node("Visual").modulate` para desvanecer a plataforma inteira.
##
## O bioma nao se poe plataforma a plataforma: le-se do no do grupo
## "atmosfera" (o raiz de Atmosfera.tscn). Sem esse no, cai em "floresta".

const DIR_TERRENO := "res://assets/sprites/pixel/terreno"

## Linha da superficie dentro de `topo.png` -- a capa assenta com esta linha
## em cima do topo da colisao, e o que fica acima e' balanco (ver
## `tools/gerar_terreno.py`, constante `folga`).
const SUPERFICIE := 8.0

const BIOMAS := [
	"floresta", "prisao", "torres", "catacumbas", "cidade", "castelo",
]

@export var tamanho := Vector2(200.0, 40.0) : set = _set_tamanho
## Altura do visual (0 = igual a colisao). Maior => "slab" de chao grosso
## que desce por baixo da superficie, sem mexer na colisao.
@export var altura_visual := 0.0 : set = _set_altura_visual
## Mantidas por compatibilidade com as cenas de nivel antigas -- o visual
## e agora pixel-art, portanto estas cores sao ignoradas.
@export var cor_base := Color(0.15, 0.21, 0.11)
@export var cor_topo := Color(0.42, 0.62, 0.28)

static var _cache_tex := {}
static var _grad_sombra: GradientTexture2D = null


func _ready() -> void:
	_aplicar()


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	_aplicar()


func _set_altura_visual(v: float) -> void:
	altura_visual = v
	_aplicar()


## Nome do bioma a usar (do no do grupo "atmosfera"), ou "floresta".
func _nome_bioma() -> String:
	var atm := get_tree().get_first_node_in_group("atmosfera") if is_inside_tree() else null
	if atm and "bioma" in atm and BIOMAS.has(atm.bioma):
		return atm.bioma
	return "floresta"


static func _tex(bioma: String, peca: String) -> Texture2D:
	var chave := "%s/%s" % [bioma, peca]
	if not _cache_tex.has(chave):
		var cam := "%s/%s/%s.png" % [DIR_TERRENO, bioma, peca]
		_cache_tex[chave] = load(cam) if ResourceLoader.exists(cam) else null
	return _cache_tex[chave]


## Degrade transparente -> preto: enterra o fundo da plataforma no escuro.
## E' o truque que faz a plataforma ler como um bloco com volume e nao como
## um autocolante -- em Dead Cells o terreno so' tem luz no primeiro palmo.
static func _sombra() -> GradientTexture2D:
	if _grad_sombra == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
		g.colors = PackedColorArray([
			Color(0, 0, 0, 0.0), Color(0.02, 0.01, 0.04, 0.28), Color(0.01, 0.0, 0.02, 0.82),
		])
		_grad_sombra = GradientTexture2D.new()
		_grad_sombra.gradient = g
		_grad_sombra.width = 8
		_grad_sombra.height = 128
		_grad_sombra.fill_from = Vector2(0, 0)
		_grad_sombra.fill_to = Vector2(0, 1)
	return _grad_sombra


## Sprite em mosaico: `regiao` maior que a textura => a textura repete-se.
## O `desloc` desencontra o mosaico de plataforma para plataforma, senao o
## mesmo tijolo cai sempre no mesmo sitio ao longo do nivel.
func _mosaico(tex: Texture2D, pos: Vector2, tam: Vector2, desloc: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(desloc, tam)
	s.position = pos
	return s


## Semente estavel por posicao -- a mesma plataforma fica sempre igual entre
## sessoes (e entre o editor e o jogo), mas duas plataformas nunca coincidem.
func _semente() -> int:
	var ix := int(position.x)
	var iy := int(position.y)
	return absi(ix * 73856093 ^ iy * 19349663) % 100003


func _aplicar() -> void:
	if not is_node_ready():
		return

	var cs := get_node_or_null("Col") as CollisionShape2D
	if cs:
		var r := RectangleShape2D.new()
		r.size = tamanho
		cs.shape = r

	var vis := get_node_or_null("Visual")
	if vis == null:
		return
	for f in vis.get_children():
		f.queue_free()

	var bioma := _nome_bioma()
	var largura: float = tamanho.x
	var alt: float = maxf(tamanho.y, altura_visual)
	var x0 := -largura * 0.5
	var y0 := -tamanho.y * 0.5              # topo da COLISAO (onde se pousa)

	var rng := RandomNumberGenerator.new()
	rng.seed = _semente()
	var dx := float(rng.randi_range(0, 191))
	var dy := float(rng.randi_range(0, 191))

	var corpo := _tex(bioma, "corpo")
	if corpo == null:                        # terreno por gerar -> nao pinta nada
		return

	# 1. miolo
	vis.add_child(_mosaico(corpo, Vector2(x0, y0), Vector2(largura, alt), Vector2(dx, dy)))

	# 2. sombra de profundidade (por cima do miolo, por baixo de tudo o resto)
	var som := Sprite2D.new()
	som.texture = _sombra()
	som.centered = false
	som.position = Vector2(x0, y0)
	som.scale = Vector2(largura / 8.0, alt / 128.0)
	vis.add_child(som)

	# 3. cortes laterais
	var lado := _tex(bioma, "lado")
	if lado:
		var le := _mosaico(lado, Vector2(x0 - 12.0, y0), Vector2(16.0, alt), Vector2(0, dy))
		vis.add_child(le)
		var ld := _mosaico(lado, Vector2(largura * 0.5 + 12.0, y0), Vector2(16.0, alt), Vector2(0, dy))
		ld.scale.x = -1.0
		vis.add_child(ld)

	# 4. franja de baixo -- so' quando a plataforma tem corpo que valha a pena
	var base := _tex(bioma, "base")
	if base and alt >= 26.0:
		vis.add_child(_mosaico(base, Vector2(x0, y0 + alt), Vector2(largura, 24.0), Vector2(dx, 0)))

	# 5. a capa, por cima de tudo (e a sobressair para cima do plano de pouso)
	var topo := _tex(bioma, "topo")
	if topo:
		vis.add_child(_mosaico(topo, Vector2(x0, y0 - SUPERFICIE), Vector2(largura, 32.0), Vector2(dx, 0)))
