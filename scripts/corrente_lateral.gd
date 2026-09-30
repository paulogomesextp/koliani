class_name CorrenteLateral
extends Area2D
## Correnteza HORIZONTAL: enquanto a Koliani está lá dentro, é arrastada
## para o lado. Irmã da `CorrenteAr` (que só sopra para cima) -- nasceu para
## as câmaras "tapete" e "correnteza" (`gerador_corredor.gd`), onde o
## interesse é o mesmo salto deixar de chegar onde chegava.
##
## Não usa nenhum método da Koliani: soma à `velocity.x` dela no
## `_physics_process`, e o atrito dela própria trata do resto. Assim serve
## qualquer `CharacterBody2D` que passe por cá.
##
## O corpo é construído em código (a Área e a forma) -- não precisa de cena.
## Quem a cria só tem de pôr `tamanho` e `empurrao`.

## Área da correnteza, em px.
@export var tamanho := Vector2(320.0, 120.0)
## Aceleração lateral (px/s²). Negativo = empurra para trás (contra a
## marcha), que é o caso interessante.
@export var empurrao := -640.0
## Velocidade lateral máxima que a correnteza consegue impor sozinha -- sem
## isto, uma correnteza longa acabava por atirar a Koliani a correr para
## trás sem ela poder fazer nada.
@export var vel_max := 210.0
@export var cor := Color(0.55, 0.75, 1.0, 0.16)
## Opt-in (N14, "vento que empurra"): o sopro pintado da prancha em mosaico
## horizontal, a correr no sentido do empurrao. Substitui o retangulo e as
## riscas de placeholder. Vazio = igual a sempre.
@export var pele: Texture2D
@export var vel_pele := 160.0
## Opacidade da pele (aditiva): o vento le'-se sem tapar o cenario.
@export var alfa_pele := 0.55

var _dentro: Array[Node] = []
var _pele_spr: Sprite2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	monitoring = true
	# A Koliani vive na layer 2 (ver `Armadilha`): sem isto a area ficava
	# com a mascara de omissao (layer 1, o mundo) e NUNCA a apanhava.
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(c: Node) -> void:
		if c is CharacterBody2D and not (c in _dentro):
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))
	_montar_visual()


## Riscas a correr no sentido do empurrão -- sem isto a correnteza era
## invisível e o jogador levava com ela sem perceber porquê.
func _montar_visual() -> void:
	if pele:
		_vestir_pele()
		return
	var fundo := ColorRect.new()
	fundo.color = cor
	fundo.size = tamanho
	fundo.position = -tamanho * 0.5
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var sentido := signf(empurrao)
	for i in 5:
		var risca := ColorRect.new()
		risca.color = Color(cor.r, cor.g, cor.b, 0.42)
		risca.size = Vector2(46.0, 3.0)
		var y := -tamanho.y * 0.5 + tamanho.y * (float(i) + 0.5) / 5.0
		risca.position = Vector2(-tamanho.x * 0.5, y)
		add_child(risca)
		var t := create_tween().set_loops()
		t.tween_property(risca, "position:x",
			-tamanho.x * 0.5 + tamanho.x * sentido, 1.4 + 0.2 * float(i))
		t.tween_callback(func() -> void:
			risca.position.x = -tamanho.x * 0.5 - tamanho.x * sentido * 0.0)


func _physics_process(dt: float) -> void:
	for c in _dentro:
		var corpo := c as CharacterBody2D
		if corpo == null:
			continue
		var v := corpo.velocity.x + empurrao * dt
		# a correnteza empurra, mas não passa do seu tecto -- o que a Koliani
		# ganhar por cima disto é dela
		if empurrao < 0.0:
			corpo.velocity.x = maxf(v, minf(corpo.velocity.x, -vel_max))
		else:
			corpo.velocity.x = minf(v, maxf(corpo.velocity.x, vel_max))


const _SHADER_PELE_CODIGO := """
shader_type canvas_item;
render_mode blend_add;
uniform vec2 meio = vec2(1.0);
uniform float borda = 0.22;
varying vec2 p;
void vertex() { p = VERTEX / meio; }
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float fx = smoothstep(1.0, 1.0 - borda * 2.0, abs(p.x));
	float fy = smoothstep(1.0, 1.0 - borda * 2.0, abs(p.y));
	COLOR = vec4(c.rgb, c.a * fx * fy);
}
"""
static var _SHADER_PELE: Shader = null


func _vestir_pele() -> void:
	if _SHADER_PELE == null:
		_SHADER_PELE = Shader.new()
		_SHADER_PELE.code = _SHADER_PELE_CODIGO
	var esc := tamanho.y / float(pele.get_height())
	_pele_spr = Sprite2D.new()
	_pele_spr.name = "Pele"
	_pele_spr.texture = pele
	_pele_spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_pele_spr.region_enabled = true
	_pele_spr.region_rect = Rect2(0.0, 0.0, tamanho.x / esc, float(pele.get_height()))
	_pele_spr.scale = Vector2(esc, esc)
	_pele_spr.modulate = Color(0.8, 0.9, 1.0, alfa_pele)
	# aditiva e com as bordas esbatidas: o sopro nasce e morre no ar, sem se
	# ver o rectangulo da area
	var m := ShaderMaterial.new()
	m.shader = _SHADER_PELE
	m.set_shader_parameter("meio", _pele_spr.region_rect.size * 0.5)
	_pele_spr.material = m
	add_child(_pele_spr)


func _process(dt: float) -> void:
	if _pele_spr:
		# o sopro corre no sentido do empurrao: desliza a janela do mosaico
		var r := _pele_spr.region_rect
		r.position.x = fposmod(r.position.x - signf(empurrao) * vel_pele * dt / _pele_spr.scale.x,
			float(pele.get_width()))
		_pele_spr.region_rect = r
