class_name PlataformaQuebra
extends StaticBody2D
## Plataforma que ESBOROA quando a Koliani lhe pisa: estremece um instante,
## cai, e volta a formar-se passado um tempo. Mecânica de plataforma
## partilhada dos percursos -- obriga a não parar. Anti-softlock: quem a
## semeia põe-na SEMPRE sobre chão seguro ou como atalho opcional.
##
## @export tamanho / atraso / respawn

@export var tamanho := Vector2(90.0, 18.0) : set = _set_tamanho
## Segundos a estremecer antes de cair.
@export var atraso := 0.6
## Segundos até voltar a formar-se.
@export var respawn := 2.6
## Pele de TERRENO (opt-in, N12 da Regiao III): em vez da laje cinzenta
## chapada, a plataforma veste o miolo do material do bioma do nivel (o
## mesmo `corpo` que a `Plataforma` usa, via `Plataforma._tex`), com uma
## aresta de pedra clara por cima. O aviso a vermelho continua a ler-se:
## tinge a textura em vez de a trocar. `false` = igual a sempre.
@export var pele_terreno := false

const PLATAFORMA := preload("res://scripts/plataforma.gd")
const COR_LISA := Color(0.32, 0.29, 0.34)
const COR_AVISO := Color(0.95, 0.35, 0.12)
var _cor_repouso := COR_LISA

enum { FIRME, TREME, IDA, FORA }

var _estado := FIRME
var _t := 0.0
var _base := Vector2.ZERO
var _col: CollisionShape2D
var _vis: Polygon2D
var _borda: Line2D
var _deteta: Area2D
var _som: Node


func _ready() -> void:
	add_to_group("plataformas_quebra")
	collision_layer = 1
	collision_mask = 0
	_base = position
	_som = get_node_or_null("/root/Som")
	# Treme e cai no `_process`, com a posicao dela propria.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_montar()


func _montar() -> void:
	_col = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = tamanho
	_col.shape = r
	add_child(_col)

	var hw := tamanho.x * 0.5
	var hh := tamanho.y * 0.5
	_vis = Polygon2D.new()
	_vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	_vis.color = COR_LISA
	if pele_terreno:
		var tex := _textura_terreno()
		if tex:
			_vis.texture = tex
			_vis.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			# ancora a textura ao mundo: degraus vizinhos nao repetem o
			# mesmo recorte do mosaico
			_vis.texture_offset = Vector2(fposmod(position.x * 0.5, 192.0), fposmod(position.y * 0.5, 192.0))
			_vis.texture_scale = Vector2(2.0, 2.0)
			_cor_repouso = Color(1.0, 0.96, 1.0)
			_vis.color = _cor_repouso
	add_child(_vis)
	# "fissuras"
	var fiss := Line2D.new()
	fiss.points = PackedVector2Array([
		Vector2(-hw * 0.5, -hh), Vector2(-hw * 0.2, hh * 0.3),
		Vector2(hw * 0.1, -hh * 0.4), Vector2(hw * 0.5, hh)])
	fiss.width = 1.5
	fiss.default_color = Color(0.12, 0.1, 0.14, 0.8)
	add_child(fiss)
	_borda = Line2D.new()
	_borda.points = _vis.polygon
	_borda.closed = true
	_borda.width = 2.0
	_borda.default_color = Color(0.5, 0.42, 0.5, 0.7)
	add_child(_borda)

	_deteta = Area2D.new()
	_deteta.collision_layer = 0
	_deteta.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size = Vector2(tamanho.x, tamanho.y + 26.0)
	cs.shape = rr
	cs.position = Vector2(0, -13.0)
	_deteta.add_child(cs)
	_deteta.body_entered.connect(_ao_pisar)
	add_child(_deteta)


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	if is_node_ready():
		for c in [_col, _vis, _borda, _deteta]:
			if c:
				c.queue_free()
		_montar()


func _ao_pisar(corpo: Node) -> void:
	if _estado == FIRME and corpo is Koliani:
		_estado = TREME
		_t = 0.0
		# TELEGRAFO. A plataforma ja' avisava com cor e trepidacao, mas quem
		# estivesse a olhar para um inimigo nao via nada -- e o abanao e' a
		# unica deixa que ela da'. Um evento por pisada; a maquina de estados
		# ja' garante que so' se entra em TREME vindo de FIRME.
		_tocar("pedra_racha", -14.0, 1.0)


func _process(dt: float) -> void:
	match _estado:
		TREME:
			_t += dt
			var aviso := clampf(_t / atraso, 0.0, 1.0)
			var trepidar := 1.0 + aviso * 2.0  # o abanão cresce -- lê-se "vai cair"
			position = _base + Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0)) * trepidar
			if _vis:
				_vis.color = _cor_repouso.lerp(COR_AVISO, aviso)
			if _borda:
				_borda.default_color = Color(0.5, 0.42, 0.5).lerp(Color(1.0, 0.5, 0.2), aviso)
				_borda.default_color.a = 0.7 + 0.3 * sin(_t * 40.0)
			if _t >= atraso:
				_estado = IDA
				_t = 0.0
				_col.set_deferred("disabled", true)
				# ACTIVATION: o chao a ceder. Nao ha' terceiro som no fim da
				# queda -- ela desaparece por fade, nao bate em lado nenhum,
				# e um impacto que nao se ve' e' ruido.
				_tocar("pedra_parte", -13.0, 1.18)
		IDA:
			_t += dt
			position.y += 220.0 * _t
			modulate.a = maxf(0.0, 1.0 - _t * 2.2)
			if _t >= 0.5:
				_estado = FORA
				_t = 0.0
				visible = false
		FORA:
			_t += dt
			if _t >= respawn:
				_estado = FIRME
				position = _base
				modulate.a = 1.0
				visible = true
				if _vis:
					_vis.color = _cor_repouso
				if _borda:
					_borda.default_color = Color(0.5, 0.42, 0.5, 0.7)
				_col.set_deferred("disabled", false)


## O `corpo` do bioma do nivel (le-se do no' do grupo "atmosfera", como a
## `Plataforma`). `null` fora de uma cena com Atmosfera -> fica a laje lisa.
func _textura_terreno() -> Texture2D:
	if not is_inside_tree():
		return null
	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm == null or not ("bioma" in atm):
		return null
	return PLATAFORMA._tex(String(atm.bioma), "corpo")


## Toca pelo CAMINHO do autoload, para a classe continuar a compilar em
## `--script` (onde os autoloads nao existem e as bancadas correm).
func _tocar(nome: String, db: float, pitch: float) -> void:
	if _som and _som.has_method("toca") and _som.call("em_vista", self):
		_som.call("toca", nome, db, pitch, 0.05,
			0.25, "%s_%d" % [nome, get_instance_id()])
