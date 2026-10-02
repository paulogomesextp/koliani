class_name PistaoFornalha
extends Armadilha
## "Pistoes esmagadores" da Regiao IV -- Fornalha (N19, Sala das Pressoes;
## `docs/art_direction/regions/region_04/level_mechanics.png`: "Pistoes de
## esmagamento", set piece "Pistoes de pressao"). A cabeca de um pistao
## industrial desce (ou avanca da parede) e esmaga o que estiver no seu
## trajecto, num ciclo FIXO e legivel:
##   RETRAIDO (`repouso_seg`)  cabeca recolhida: seguro
##   AVISO    (`aviso_seg`)    a cabeca treme e brilha, saltam fagulhas e a
##                             MARCA no chao acende onde vai bater: seguro
##   EXTENDENDO (`extensao_seg`) a cabeca desce rapida: PERIGO
##   ESTENDIDO  (`permanece_seg`) parada em baixo: PERIGO
##   RETRAINDO  (`retracao_seg`)  sobe devagar: PERIGO ate' 1/4 do curso
## Sem aleatorio: o ciclo e' `fase` + relogio. Com `relogio_local` (omissao)
## o relogio conta desde o ARRANQUE do no' -- reaparecer (a cena recarrega)
## repete sempre o mesmo ritmo.
##
## Nunca magoa no mesmo instante em que muda de estado: entre RETRAIDO e a
## primeira pancada ha' sempre `aviso_seg` (>= 0,7 s) de telegrafo.
##
## Geometria: a origem do no' e' a FACE da cabeca quando esta' recolhida; a
## cabeca avanca `curso` px no sentido `direcao` (so' eixos). A colisao e' so'
## a da cabeca (nunca fisica: nao prende nem esmaga a Koliani contra nada, so'
## a fere e a empurra para o lado).
##
## Valvula (`ValvulaFornalha`): com `grupo_valvula` definido, o pistao junta-se
## ao grupo e, enquanto a valvula esta' aberta, recolhe (suavemente, nunca
## "salta") e fica parado; ao fechar recomeca o ciclo em `fase_retoma`.

enum Estado { RETRAIDO, AVISO, EXTENDENDO, ESTENDIDO, RETRAINDO }

## Sentido da extensao (vector unitario sobre um eixo).
@export var direcao := Vector2.DOWN
@export var curso := 230.0 : set = _set_curso
@export var largura := 78.0 : set = _set_largura
@export var altura_cabeca := 54.0
@export var repouso_seg := 2.2
@export var aviso_seg := 0.9
@export var extensao_seg := 0.22
@export var permanece_seg := 0.8
@export var retracao_seg := 0.7
@export var fase := 0.0
## Grupo da `ValvulaFornalha` que o governa ("" = nenhuma).
@export var grupo_valvula := ""
## O que a valvula faz:
##   "pausa"         recolhe e fica parado enquanto aberta; ao fechar recomeca em
##                   `fase_retoma`;
##   "ressincroniza" ao abrir recolhe e recomeca JA' em `fase_retoma` (a
##                   coreografia boa: os pistoes "entram em fase"); ao fechar
##                   recolhe e volta a `fase` (a coreografia desencontrada).
@export_enum("pausa", "ressincroniza") var efeito_valvula := "pausa"
## Posicao (s) do ciclo em que recomeca (-1 = `fase`). Tem de cair no REPOUSO,
## com pelo menos o AVISO inteiro por correr.
@export var fase_retoma := -1.0
## true = o ciclo conta desde o arranque; false = relogio global do jogo.
@export var relogio_local := true
## Marca no chao do ponto de impacto (acende no aviso).
@export var marcar_alvo := true
@export var textura_cabeca: Texture2D
@export var textura_caixa: Texture2D
@export var escala_textura := 0.5

## Fraccao do curso a partir da qual a cabeca magoa.
const LIMIAR_PERIGO := 0.25
const REPETE_DANO := 0.45

var estado := Estado.RETRAIDO
var pausado := false
var _frac := 0.0
var _desloc := 0.0
var _retomar := false
var _destino := 0.0
var _estado_anterior := -1
var _t_dano := 0.0
var _forma: CollisionShape2D
var _haste: Polygon2D
var _caixa: Node2D
var _cabeca: Node2D
var _brilho: Polygon2D
var _alvo: Polygon2D
var _faiscas: CPUParticles2D
var _vapor: CPUParticles2D
var _ultima_frac := -1.0
var _visivel := true


func _set_curso(v: float) -> void:
	curso = maxf(40.0, v)
	if is_node_ready():
		_atualizar_visual(true)


func _set_largura(v: float) -> void:
	largura = maxf(24.0, v)
	if is_node_ready():
		_reconstruir()


# ---------------------------------------------------------------- ciclo puro
func ciclo() -> float:
	return maxf(0.5, repouso_seg + aviso_seg + extensao_seg + permanece_seg + retracao_seg)


func _pos(t_seg: float) -> float:
	return fposmod(t_seg + fase, ciclo())


func estado_em(t_seg: float) -> int:
	return estado_na_posicao(_pos(t_seg))


func estado_na_posicao(p: float) -> int:
	var f := p
	if f < repouso_seg:
		return Estado.RETRAIDO
	f -= repouso_seg
	if f < aviso_seg:
		return Estado.AVISO
	f -= aviso_seg
	if f < extensao_seg:
		return Estado.EXTENDENDO
	f -= extensao_seg
	if f < permanece_seg:
		return Estado.ESTENDIDO
	return Estado.RETRAINDO


## Fraccao 0..1 do curso percorrida (a cabeca ACELERA a descer, trava a subir).
func curso_em(t_seg: float) -> float:
	return curso_na_posicao(_pos(t_seg))


func curso_na_posicao(p: float) -> float:
	var f := p
	if f < repouso_seg + aviso_seg:
		return 0.0
	f -= repouso_seg + aviso_seg
	if f < extensao_seg:
		var k := f / maxf(0.01, extensao_seg)
		return k * k
	f -= extensao_seg
	if f < permanece_seg:
		return 1.0
	f -= permanece_seg
	var k2 := clampf(f / maxf(0.01, retracao_seg), 0.0, 1.0)
	return 1.0 - k2 * k2 * (3.0 - 2.0 * k2)


func perigoso_em(t_seg: float) -> bool:
	return curso_em(t_seg) > LIMIAR_PERIGO


## Segundos de AVISO que ainda faltam ao arrancar na posicao `p` do ciclo (>=
## `aviso_seg` quando o ciclo recomeca dentro do repouso).
func aviso_restante_a_partir_de(p: float) -> float:
	if p < repouso_seg:
		return aviso_seg + (repouso_seg - p)
	if p < repouso_seg + aviso_seg:
		return repouso_seg + aviso_seg - p
	return 0.0


func fase_efetiva_retoma() -> float:
	return fase_retoma if fase_retoma >= 0.0 else fase


## Rectangulo (coordenadas do no') coberto pela cabeca quando percorreu `f`.
func caixa_cabeca(f: float) -> Rect2:
	var d := _eixo()
	var centro := d * (f * curso - altura_cabeca * 0.5)
	var meio := Vector2(largura, altura_cabeca) * 0.5 if absf(d.y) > 0.5 \
		else Vector2(altura_cabeca, largura) * 0.5
	return Rect2(centro - meio, meio * 2.0)


func _eixo() -> Vector2:
	return direcao.normalized() if direcao.length() > 0.01 else Vector2.DOWN


# ----------------------------------------------------------------- arranque
func _pronto() -> void:
	dano = maxi(dano, 24)
	ativa = false
	if grupo_valvula != "":
		add_to_group("valvula_" + grupo_valvula)
	_desloc = -_ahora() if relogio_local else 0.0
	_montar()
	_atualizar_visual(true)
	_montar_visibilidade()


func _ahora() -> float:
	return RelogioFornalha.agora()


func _tempo() -> float:
	return _ahora() + _desloc


func _montar() -> void:
	var rot := _eixo().angle() - PI * 0.5
	_forma = CollisionShape2D.new()
	_forma.name = "Zona"
	var r := RectangleShape2D.new()
	r.size = Vector2(largura * 0.86, altura_cabeca * 0.9)
	_forma.shape = r
	add_child(_forma)
	var d := _eixo()
	# haste (poligono escuro com friso), entre a caixa e a cabeca
	_haste = Polygon2D.new()
	_haste.name = "Haste"
	_haste.color = Color(0.2, 0.18, 0.2)
	_haste.z_index = -1
	add_child(_haste)
	# caixa (cilindro fixo); fica atras da posicao recolhida
	_caixa = Node2D.new()
	_caixa.name = "Caixa"
	_caixa.z_index = 0
	add_child(_caixa)
	if textura_caixa:
		var sc := Sprite2D.new()
		sc.texture = textura_caixa
		sc.scale = Vector2(escala_textura, escala_textura)
		sc.rotation = rot
		_caixa.add_child(sc)
	else:
		var pc := Polygon2D.new()
		var w := largura * 0.5 + 8.0
		pc.polygon = PackedVector2Array([Vector2(-w, -34), Vector2(w, -34), Vector2(w, 34), Vector2(-w, 34)])
		pc.color = Color(0.3, 0.26, 0.28)
		pc.rotation = rot
		_caixa.add_child(pc)
	# cabeca
	_cabeca = Node2D.new()
	_cabeca.name = "Cabeca"
	_cabeca.z_index = 2
	add_child(_cabeca)
	if textura_cabeca:
		var sp := Sprite2D.new()
		sp.name = "Pele"
		sp.texture = textura_cabeca
		sp.scale = Vector2(escala_textura, escala_textura)
		sp.rotation = rot
		# a cabeca do sprite (extremo "de baixo") coincide com a face
		sp.position = d * (-textura_cabeca.get_height() * escala_textura * 0.5 + altura_cabeca * 0.15)
		_cabeca.add_child(sp)
	else:
		var ph := Polygon2D.new()
		ph.name = "Pele"
		var ww := largura * 0.5
		var hh := altura_cabeca
		ph.polygon = PackedVector2Array([Vector2(-ww, -hh), Vector2(ww, -hh), Vector2(ww + 4, 0), Vector2(-ww - 4, 0)])
		ph.color = Color(0.36, 0.3, 0.32)
		ph.rotation = rot
		_cabeca.add_child(ph)
	# brilho quente da face (aviso/pancada)
	_brilho = Polygon2D.new()
	_brilho.name = "Brilho"
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_brilho.material = mat
	var wb := largura * 0.5
	_brilho.polygon = PackedVector2Array([Vector2(-wb, -10), Vector2(wb, -10), Vector2(wb, 0), Vector2(-wb, 0)])
	_brilho.rotation = rot
	_brilho.color = Color(1.0, 0.4, 0.1, 0.0)
	_cabeca.add_child(_brilho)
	# marca de impacto no destino
	if marcar_alvo:
		_alvo = Polygon2D.new()
		_alvo.name = "Alvo"
		_alvo.material = mat
		var wa := largura * 0.5 + 6.0
		_alvo.polygon = PackedVector2Array([Vector2(-wa, -12), Vector2(wa, -12), Vector2(wa, 2), Vector2(-wa, 2)])
		_alvo.rotation = rot
		_alvo.position = d * curso
		_alvo.color = Color(1.0, 0.35, 0.08, 0.0)
		_alvo.z_index = 4
		add_child(_alvo)
	# fagulhas da cabeca (so' emitem no aviso)
	_faiscas = CPUParticles2D.new()
	_faiscas.name = "Faiscas"
	_faiscas.amount = 8
	_faiscas.lifetime = 0.5
	_faiscas.local_coords = false
	_faiscas.direction = -d
	_faiscas.spread = 50.0
	_faiscas.gravity = Vector2(0, 160)
	_faiscas.initial_velocity_min = 40.0
	_faiscas.initial_velocity_max = 110.0
	_faiscas.scale_amount_min = 1.4
	_faiscas.scale_amount_max = 2.6
	_faiscas.emitting = false
	_faiscas.z_index = 3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.9, 0.5, 0.0), Color(1, 0.55, 0.15, 0.95), Color(0.5, 0.1, 0.05, 0.0)])
	_faiscas.color_ramp = ramp
	add_child(_faiscas)
	# vapor da pancada (um sopro)
	_vapor = CPUParticles2D.new()
	_vapor.name = "Vapor"
	_vapor.amount = 10
	_vapor.lifetime = 0.7
	_vapor.one_shot = true
	_vapor.explosiveness = 0.9
	_vapor.local_coords = false
	_vapor.direction = -d
	_vapor.spread = 80.0
	_vapor.gravity = Vector2(0, -30)
	_vapor.initial_velocity_min = 30.0
	_vapor.initial_velocity_max = 90.0
	_vapor.scale_amount_min = 4.0
	_vapor.scale_amount_max = 9.0
	_vapor.emitting = false
	_vapor.z_index = 3
	var rv := Gradient.new()
	rv.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	rv.colors = PackedColorArray([Color(0.8, 0.8, 0.85, 0.0), Color(0.78, 0.78, 0.84, 0.5), Color(0.5, 0.5, 0.55, 0.0)])
	_vapor.color_ramp = rv
	add_child(_vapor)


## Performance (mobile): o estado do pistao e' FUNCAO do tempo, por isso fora do
## ecra nao e' preciso corre-lo -- ao voltar a entrar em vista o primeiro passo
## poe-no exactamente onde devia estar. Quem esta' a meio de uma valvula
## (`pausado`/`_retomar`) continua a correr. Sem renderer (testes/bancadas
## headless) corre sempre.
func _montar_visibilidade() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var n := VisibleOnScreenNotifier2D.new()
	n.name = "Visivel"
	var meia := largura * 0.5 + 60.0
	n.rect = Rect2(-meia, -(altura_cabeca + 130.0), meia * 2.0, curso + altura_cabeca + 260.0)
	n.screen_entered.connect(_ao_ver.bind(true))
	n.screen_exited.connect(_ao_ver.bind(false))
	add_child(n)
	_visivel = n.is_on_screen()
	_atualizar_processamento()


func _ao_ver(sim: bool) -> void:
	_visivel = sim
	_atualizar_processamento()
	if sim:
		passo(0.0, _tempo())


func _atualizar_processamento() -> void:
	set_physics_process(_visivel or pausado or _retomar)


func _reconstruir() -> void:
	if _forma == null:
		return
	(_forma.shape as RectangleShape2D).size = Vector2(largura * 0.86, altura_cabeca * 0.9)


# ------------------------------------------------------------------- passo
func _physics_process(dt: float) -> void:
	passo(dt, _tempo())


## Um passo do pistao (publico para as bancadas, que lhe dao o tempo).
func passo(dt: float, t: float) -> void:
	if pausado:
		_frac = move_toward(_frac, 0.0, dt / maxf(0.05, retracao_seg))
		estado = Estado.RETRAINDO if _frac > 0.0 else Estado.RETRAIDO
		if _retomar and _frac <= 0.0:
			pausado = false
			_retomar = false
			_desloc = _destino - fase - _ahora()
			_atualizar_processamento()
	else:
		_frac = curso_em(t)
		estado = estado_em(t) as Estado
	_atualizar_visual(false, t)
	var perigo := _frac > LIMIAR_PERIGO
	if perigo != ativa:
		ativa = perigo
		if perigo:
			_t_dano = 0.0
			_ferir_presentes()
	if ativa:
		_t_dano -= dt
		if _t_dano <= 0.0:
			_t_dano = REPETE_DANO
			_ferir_presentes()
	if estado != _estado_anterior:
		_ao_mudar_de_estado()


func _ao_mudar_de_estado() -> void:
	var anterior := _estado_anterior
	_estado_anterior = estado
	if _faiscas:
		_faiscas.emitting = estado == Estado.AVISO
	if anterior < 0:
		return
	if estado == Estado.AVISO:
		_som("mecanismo_ciclo", -15.0, 1.0)
	elif estado == Estado.ESTENDIDO and anterior == Estado.EXTENDENDO:
		_som("mecanismo", -8.0, 0.55)
		if _vapor:
			_vapor.global_position = to_global(_eixo() * curso)
			_vapor.restart()


func _som(nome: String, vol: float, pitch: float) -> void:
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca_actor") and som.has_method("em_vista") and som.em_vista(self, 120.0):
		som.call("toca_actor", self, nome, vol, pitch, 0.04, 0.5, "pistao_%d" % get_instance_id())


func _atualizar_visual(forcar: bool, t := 0.0) -> void:
	if _cabeca == null:
		return
	var d := _eixo()
	var tremor := Vector2.ZERO
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
	if estado == Estado.AVISO and not pausado:
		var perp := Vector2(-d.y, d.x)
		tremor = perp * sin(Time.get_ticks_msec() * 0.09) * 2.2
	if forcar or absf(_frac - _ultima_frac) > 0.0005 or tremor != Vector2.ZERO:
		_ultima_frac = _frac
		_cabeca.position = d * (_frac * curso) + tremor
		if _forma:
			_forma.position = d * (_frac * curso - altura_cabeca * 0.5)
		# haste: da caixa (fixa, atras da cabeca recolhida) ate' a cabeca
		var w := largura * 0.2
		var perp2 := Vector2(-d.y, d.x) * w
		var a := d * -(altura_cabeca + 54.0)
		var b := d * (_frac * curso - altura_cabeca * 0.5)
		_haste.polygon = PackedVector2Array([a - perp2, a + perp2, b + perp2, b - perp2])
		_caixa.position = d * -(altura_cabeca + 54.0)
	if _brilho:
		var a := 0.0
		if pausado:
			_brilho.color = Color(0.45, 0.8, 1.0, 0.0)
		elif estado == Estado.AVISO:
			a = 0.35 + 0.4 * pulso
			_brilho.color = Color(1.0, 0.4, 0.1, a)
		elif _frac > LIMIAR_PERIGO:
			_brilho.color = Color(1.0, 0.55, 0.2, 0.7)
		else:
			_brilho.color = Color(1.0, 0.4, 0.1, 0.12)
	if _alvo:
		if pausado:
			_alvo.color = Color(0.3, 0.6, 0.8, 0.12)
		elif estado == Estado.AVISO:
			_alvo.color = Color(1.0, 0.35, 0.08, 0.3 + 0.5 * pulso)
		elif _frac > LIMIAR_PERIGO:
			_alvo.color = Color(1.0, 0.5, 0.15, 0.0)
		else:
			_alvo.color = Color(1.0, 0.35, 0.08, 0.1)
	if _cabeca:
		_cabeca.modulate = Color(0.7, 0.9, 1.0) if pausado else Color(1, 1, 1)


# ----------------------------------------------------------------- valvula
func valvula_mudou(aberta: bool) -> void:
	if efeito_valvula == "ressincroniza":
		# ressincroniza: recolhe e recomeca logo, na fase boa (aberta) ou na de origem
		pausado = true
		_retomar = true
		_destino = fase_efetiva_retoma() if aberta else fase
		_atualizar_processamento()
		return
	if aberta:
		pausado = true
		_retomar = false
	elif pausado:
		_retomar = true
		_destino = fase_efetiva_retoma()
	_atualizar_processamento()


## Volta ao estado de arranque (as bancadas e quem reinicia o nivel).
func reiniciar() -> void:
	pausado = false
	_retomar = false
	_frac = 0.0
	_desloc = -_ahora() if relogio_local else 0.0
	_estado_anterior = -1
	_t_dano = 0.0
	ativa = false
