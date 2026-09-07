extends Camera2D
## Câmara da Koliani: seguimento de movimento + screen shake. Ambos ficam no
## `offset`, por isso não disputam `position` com enquadramento de salas/boss.
##
## Trata também do **zoom por ecrã**. O `stretch/aspect` do projecto é
## `expand`: num telemóvel de 20:9 o viewport passa de 1280x720 para
## 1600x720 e o jogo mostra 25% mais mundo à largura -- é o "zoom out" que
## se vê no telemóvel e não se vê no executável de Windows. Aqui o zoom da
## câmara sobe na mesma proporção, portanto **vê-se sempre o mesmo mundo**
## em qualquer ecrã, e a UI continua a ter o ecrã todo para se arrumar (que
## era o que se perdia se se mexesse no `aspect` do projecto).

## O zoom desenhado na cena, a 1280x720. Tudo o resto sai daqui.
const ZOOM_BASE := Vector2(1.4, 1.4)
const REF := Vector2(1280.0, 720.0)

## Tunables do primeiro passe de Camera Feel (Execution 4A).
const LOOK_AHEAD_X := 112.0
const LOOK_AHEAD_VEL_MIN := 36.0
const LOOK_AHEAD_INPUT_MIN := 0.34
const LOOK_AHEAD_ATRASO_VIRAGEM := 0.14
const LOOK_AHEAD_RESPOSTA := 3.8
const DEADZONE_VERTICAL := 68.0
const QUEDA_LOOK_LIMIAR := 300.0
const QUEDA_DISTANCIA_LIMIAR := 84.0
const LOOK_QUEDA_Y := 92.0
const LOOK_VERTICAL_RESPOSTA := 5.0

enum IntensidadeTremor { DESLIGADO, REDUZIDO, COMPLETO }

var _tremor := Tremor.new()
var _intensidade_tremor := IntensidadeTremor.COMPLETO
var _seguimento := Vector2.ZERO
var _direcao_look := 0.0
var _direcao_candidata := 0.0
var _tempo_candidata := 0.0
var _chao_y := 0.0
var _tem_chao_y := false
var _sinal_grav := 1.0


func _ready() -> void:
	_ajustar_zoom()
	get_viewport().size_changed.connect(_ajustar_zoom)
	var jogador := get_parent() as CharacterBody2D
	if jogador:
		_chao_y = jogador.global_position.y
		_tem_chao_y = true


func _ajustar_zoom() -> void:
	var v := Vector2(get_viewport().get_visible_rect().size)
	if v.x <= 0.0 or v.y <= 0.0:
		return
	# `max` e não `min`: assim o mundo visível nunca é MAIOR do que a 16:9,
	# nem num ecrã mais largo (telemóvel) nem num mais alto (tablet 4:3).
	var f := maxf(v.x / REF.x, v.y / REF.y)
	zoom = ZOOM_BASE * f


func bater(forca: float) -> void:
	_tremor.bater(forca * fator_tremor())


## API mínima para uma futura opção de acessibilidade; não cria UI nesta
## execução. Valores inválidos ficam presos ao intervalo conhecido.
func definir_intensidade_tremor(valor: int) -> void:
	_intensidade_tremor = clampi(valor,
		IntensidadeTremor.DESLIGADO, IntensidadeTremor.COMPLETO)
	if _intensidade_tremor == IntensidadeTremor.DESLIGADO:
		_tremor = Tremor.new()


func fator_tremor() -> float:
	match _intensidade_tremor:
		IntensidadeTremor.DESLIGADO:
			return 0.0
		IntensidadeTremor.REDUZIDO:
			return 0.4
		_:
			return 1.0


## Passo determinístico/testável do seguimento. `deslocamento_chao` mede a
## altura desde o último chão estável, no sentido da gravidade.
func passo_seguimento(dt: float, input_x: float, velocidade: Vector2,
		deslocamento_chao: float, no_chao: bool, sinal_grav: float = 1.0) -> Vector2:
	var direcao_pedida := 0.0
	if absf(input_x) >= LOOK_AHEAD_INPUT_MIN \
			and absf(velocidade.x) >= LOOK_AHEAD_VEL_MIN:
		direcao_pedida = signf(input_x)

	if direcao_pedida != 0.0 and direcao_pedida != _direcao_look:
		if direcao_pedida != _direcao_candidata:
			_direcao_candidata = direcao_pedida
			_tempo_candidata = 0.0
		_tempo_candidata += dt
		if _tempo_candidata >= LOOK_AHEAD_ATRASO_VIRAGEM:
			_direcao_look = _direcao_candidata
			_direcao_candidata = 0.0
			_tempo_candidata = 0.0
	else:
		_direcao_candidata = 0.0
		_tempo_candidata = 0.0

	var proporcao_vel := clampf(absf(velocidade.x) / Movimento.VEL_CORRIDA, 0.0, 1.0)
	var alvo_x := _direcao_look * LOOK_AHEAD_X * proporcao_vel
	if absf(velocidade.x) < LOOK_AHEAD_VEL_MIN:
		alvo_x = 0.0
	var peso_x := 1.0 - exp(-LOOK_AHEAD_RESPOSTA * dt)
	_seguimento.x = lerpf(_seguimento.x, alvo_x, peso_x)

	var alvo_grav_y := 0.0
	if not no_chao:
		# Até à deadzone, o offset cancela o deslocamento da personagem: hops
		# pequenos não arrastam o enquadramento. Acima dela, a câmara acompanha.
		alvo_grav_y = -signf(deslocamento_chao) * minf(
			absf(deslocamento_chao), DEADZONE_VERTICAL)
		if deslocamento_chao > QUEDA_DISTANCIA_LIMIAR \
				and velocidade.y * sinal_grav > QUEDA_LOOK_LIMIAR:
			var por_distancia := clampf(
				(deslocamento_chao - QUEDA_DISTANCIA_LIMIAR) / 180.0, 0.0, 1.0)
			var por_velocidade := clampf(
				(velocidade.y * sinal_grav - QUEDA_LOOK_LIMIAR) / 420.0, 0.0, 1.0)
			# Os dois sinais têm de entrar no blend: assim cruzar um limiar com o
			# outro já alto não provoca um salto súbito do alvo vertical.
			var peso_queda := minf(por_distancia, por_velocidade)
			alvo_grav_y = lerpf(-DEADZONE_VERTICAL, LOOK_QUEDA_Y, peso_queda)
	var peso_y := 1.0 - exp(-LOOK_VERTICAL_RESPOSTA * dt)
	_seguimento.y = lerpf(_seguimento.y, alvo_grav_y * sinal_grav, peso_y)
	return _seguimento


func _process(dt: float) -> void:
	var jogador := get_parent() as CharacterBody2D
	if jogador:
		var sinal_jogador: Variant = jogador.get("_sinal_grav")
		if sinal_jogador is float:
			_sinal_grav = signf(sinal_jogador)
		if jogador.is_on_floor():
			_chao_y = jogador.global_position.y
			_tem_chao_y = true
		elif not _tem_chao_y:
			_chao_y = jogador.global_position.y
			_tem_chao_y = true
		var deslocamento := (jogador.global_position.y - _chao_y) * _sinal_grav
		passo_seguimento(dt,
			Input.get_axis("mover_esquerda", "mover_direita"),
			jogador.velocity, deslocamento, jogador.is_on_floor(),
			_sinal_grav)
	var deslocamento_tremor := _tremor.passo(dt) if _tremor.ativo() else Vector2.ZERO
	offset = _seguimento + deslocamento_tremor
