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
## F1: a 750 px/s (terminal) o chao tem de aparecer >= 0,6 s antes do impacto,
## ou seja ~450 px abaixo dos pes; a meia altura visivel e' ~257 px, logo o
## look-ahead vertical chega a ~200 px -- mas so' a velocidade terminal e
## cresce com ela (saltos e quedas curtas nao o veem).
const LOOK_QUEDA_Y := 235.0
const QUEDA_VEL_TERMINAL := 750.0
const LOOK_QUEDA_RESPOSTA := 14.0
## px/s: teto da velocidade a que o look-ahead vertical se move (subida ou volta)
const REGRESSO_MAX_VEL := 460.0
const REGRESSO_RESPOSTA := 7.0
const LOOK_VERTICAL_RESPOSTA := 5.0

## SEM `position_smoothing` (Execution 9H.13/14) -- e e' de proposito.
##
## O projecto tem `physics/common/physics_interpolation=true`. O
## `position_smoothing` do `Camera2D` e' resolvido no passo de FISICA; com o
## ecra' acima dos 60 Hz (o do Paulo anda a 165) as duas suavizacoes entram em
## conflito e a vista avanca aos saltos -- era isto que o Game Master via como
## "o fundo do L2 treme constantemente". Medido em
## `tools/probe_jitter_fundo.gd`, no L2, em REGIME PERMANENTE (velocidade
## maxima, >20 frames depois de qualquer inversao de marcha) e com
## `--fixed-fps`, para o tempo de frame nao entrar na conta:
##
##   165 Hz, smoothing ligado : dp/media = 1,70   (1 a 1000 px/s)
##   165 Hz, smoothing fora   : dp/media = 0,87   (max. 187 px/s)
##    60 Hz (ecra = fisica)   : dp/media = 0,22   -- nunca tremeu
##
## HIPOTESE TESTADA E DESCARTADA: refazer o atraso aqui no `_process`
## (lerp de `global_position` para dentro do `offset`). Da' PIOR -- 2781 px/s
## de pico. Em `_process`, `global_position` e' a posicao da FISICA, que anda
## aos degraus de 60 Hz; somar um atraso calculado sobre ela a uma camara ja'
## interpolada e' misturar dois relogios. Com a interpolacao ligada o motor
## ja' entrega a posicao do jogador suave frame a frame -- a camara nao
## precisa de atraso nenhum, e o que da' o toque de camara e' o look-ahead
## (`_seguimento`), que continua tal e qual.
##
## HIPOTESE TESTADA E DESCARTADA (2): "o `ParallaxBackground` e' legado e nao
## sabe de interpolacao, por isso o fundo atrasa-se em relacao ao mundo". NAO
## se confirma. Medido frame a frame a 165 Hz, `scroll_offset.x` e a origem da
## `canvas_transform` sao IGUAIS ate' a' milesima -- atraso 0,000 em todos os
## frames. O fundo nunca esteve dessincronizado da camara; o que tremia era a
## camara, e as duas coisas tremiam juntas. Nao ha' aqui migracao para
## `Parallax2D` a fazer.

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
				(deslocamento_chao - QUEDA_DISTANCIA_LIMIAR) / 80.0, 0.0, 1.0)
			var por_velocidade := clampf(
				(velocidade.y * sinal_grav - QUEDA_LOOK_LIMIAR) / (QUEDA_VEL_TERMINAL - QUEDA_LOOK_LIMIAR), 0.0, 1.0)
			# Os dois sinais têm de entrar no blend: assim cruzar um limiar com o
			# outro já alto não provoca um salto súbito do alvo vertical.
			var peso_queda := minf(por_distancia, por_velocidade)
			alvo_grav_y = lerpf(-DEADZONE_VERTICAL, LOOK_QUEDA_Y, peso_queda)
	# a olhar para baixo em queda rapida a resposta e' mais viva (o alvo cresce
	# com a velocidade); a volta ao enquadramento normal usa a resposta suave
	var resposta_y := LOOK_VERTICAL_RESPOSTA
	if alvo_grav_y * sinal_grav > _seguimento.y * sinal_grav and alvo_grav_y * sinal_grav > 0.0:
		resposta_y = LOOK_QUEDA_RESPOSTA
	var peso_y := 1.0 - exp(-resposta_y * dt)
	var voltando := absf(alvo_grav_y) < absf(_seguimento.y) and alvo_grav_y * sinal_grav < _seguimento.y * sinal_grav
	if voltando and _seguimento.y * sinal_grav > 0.0:
		peso_y = 1.0 - exp(-REGRESSO_RESPOSTA * dt)
	var novo_y := lerpf(_seguimento.y, alvo_grav_y * sinal_grav, peso_y)
	# a volta ao enquadramento apos uma queda rapida (offset grande) nao pode
	# ser um estalo: limita a velocidade de regresso da camara
	var passo_y := novo_y - _seguimento.y
	if voltando and _seguimento.y * sinal_grav > 0.0:
		passo_y = clampf(passo_y, -REGRESSO_MAX_VEL * dt, REGRESSO_MAX_VEL * dt)
	_seguimento.y = _seguimento.y + passo_y
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
