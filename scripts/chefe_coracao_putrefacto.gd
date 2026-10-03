class_name ChefeCoracaoPutrefacto
extends ChefeBase
## Regiao I / nivel 05 -- O Coracao Putrefacto: BOSS REGIONAL, o exame da Floresta Corrompida.
## Nao se desloca: e' uma massa no centro da arena, e a luta e' um ciclo legivel
##
##   PROTEGIDO -> MECANICA -> EXPOSTO (PUNISH) -> RECOVER -> PROTEGIDO ...
##
## PROTEGIDO  a casca de corrupcao aguenta o golpe (`RESIST_CASCA` do dano, sem recuo); a luta nao
##            se ganha a fazer spam. A pele fica baca e escura.
## MECANICA   um ataque SEMPRE com aviso (o coracao pisca e o aviso desenha-se no chao) antes de
##            haver dano:
##   RAIZES   marcas no chao (racha visivel 1,5 s) em volta da Koliani -> sai-se dali (movimento/salto).
##   PULSO    o coracao brilha e duas ondas rasteiras (uma para cada lado) percorrem o chao:
##            salta-se por cima OU atravessa-se de DASH (invulneravel). E' a janela do Dash.
##   BROTOS   dois brotos crescem no chao (alvos de POGO): ressaltar num broto (BAIXO+ATAQUE em cima
##            dele) rebenta-o, abre o nucleo de imediato e alonga a janela em 50 %. Ignora-los nao
##            castiga: o nucleo abre na mesma, so' que mais tarde e mais curto.
## EXPOSTO    o nucleo abre-se (brilho + pulso), o coracao NAO magoa por contacto; e' aqui que a
##            espada entra por inteiro e que o ESPECIAL rende (a onda atravessa e da' 2,6x). A
##            Energia decide QUANDO gastar: 3 cargas, ~130 cada. Nao chega para ganhar sozinho.
## RECOVER    o nucleo pisca 0,4 s antes de fechar (aviso legivel).
##
## FASE 2 (< 50 %): o mesmo vocabulario encadeado (raizes + pulso, pulso duplo, raizes + brotos),
## avisos ~15 % mais curtos, janela ~20 % mais curta, uma 2.a zona de raizes. Nao ha' tiros nem
## gravidade alterada. Regra global: nada arranca fora do campo visual (`Som.em_vista`).

const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")
const BROTO := preload("res://scripts/broto_coracao.gd")

enum Fase { DORME, DECIDE, RAIZES_MARCAS, PULSO_TEL, PULSO_LANCA, BROTOS_TEL, BROTOS_ESPERA, EXPOSTO, ROAR }

## Fracao do dano que a casca deixa passar fora da janela.
const RESIST_CASCA := 0.05
const PADRAO_F1 := ["RAIZES", "PULSO", "BROTOS", "PULSO"]
const PADRAO_F2 := ["RAIZES+PULSO", "BROTOS", "PULSO+PULSO", "RAIZES+BROTOS"]

## Tempos proprios (nao levam o escalonamento `dur_*` do ChefeBase).
@export var t_marcas := 0.7
@export var t_pulso_tel := 0.95
@export var t_brotos_tel := 0.6
@export var t_brotos_espera := 1.7
@export var janela_aberta := 2.6
@export var atraso_raiz := 1.5
@export var vel_onda := 400.0
@export var dano_raiz := 18
@export var dano_pulso := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _nivel := 1  ## 1 ou 2
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 460
var _combate := false
var _f2 := false
var _seq: Array = []          # mecanicas ainda por fazer neste ciclo
var _dur_janela := 0.0
var _broto_estourado := false
var _brotos: Array = []
var _marcas_pulso: Array = []
var _casca_cd := 0.0
## Diagnostico/testes: quantas vezes arrancou cada mecanica, e o historico de estados.
var contagem := {"RAIZES": 0, "PULSO": 0, "BROTOS": 0, "JANELAS": 0, "BROTOS_ESTOURADOS": 0}
var historico: Array = []

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")

## Execution 9E.2 -- arte de produção (Região I, manifesto dos inimigos). Com
## ela: fase 1 = forma contida, fase 2 = forma intensificada (`idle_f2`,
## `hit_f2`), erupção de corrupção na transição, núcleo alinhado com o da arte.
## Sem ela, tudo fica como antes. Nada disto toca em vida, dano ou tempos.
const CORACAO_ID := "coracao_putrefacto"
var _prod := false
## 9G: aura de corrupção da fase 2.
var _aura_f2: AnimatedSprite2D


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 360)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_prod = not Inimigos9D.entrada(self, CORACAO_ID).is_empty()
	if _prod:
		_alinhar_nucleo("fase_1")
		# a luz da sístole foi pensada para o coração pequeno do legado: a este
		# raio (~300 px no ecrã) lava o corpo todo de rosa. Encolhida, fica um
		# brilho só no núcleo -- a janela de dano continua a ler-se (a energia
		# e o tempo não mudam).
		var luz_n := _nucleo.get_node_or_null("Luz") as Node2D if _nucleo else null
		if luz_n:
			luz_n.scale *= 0.4
		# idem para a luz magenta constante do coração (~330 px): pinta a casca
		# escura de rosa. Fica um halo à volta do núcleo.
		var luz_c := get_node_or_null("Sprite/LuzCoracao") as Node2D
		if luz_c:
			luz_c.scale *= 0.4
	_mostrar_nucleo(false)


## O Coração de produção é mais largo que alto: com o teto de 110 dos
## guardiões ficava raso. A 150 mantém a altura de sempre (100 x 1.7).
func _largura_alvo() -> float:
	if not Inimigos9D.entrada(self, CORACAO_ID).is_empty():
		return 150.0
	return super._largura_alvo()


## Fase 2 da arte: a forma intensificada substitui a contida; o golpe da fase
## 2 recua a forma intensificada. A fase 1 é o comportamento de sempre.
func _atualizar_anim() -> void:
	if not _prod or _nivel < 2:
		super._atualizar_anim()
		return
	if _morto:
		return
	if _anim.animation in ["hit", "hit_f2"] and _anim.is_playing():
		return
	if _anim.animation != "idle_f2":
		_anim.play("idle_f2")


## Põe o ponto fraco (`Nucleo`) e a luz em cima do núcleo desenhado na arte.
func _alinhar_nucleo(fase: String) -> void:
	var c: Array = (Inimigos9D.entrada(self, CORACAO_ID).get("nucleo_no_frame", {}) as Dictionary).get(fase, [])
	if c.size() < 2 or _anim == null or _anim.sprite_frames == null:
		return
	var tex := _anim.sprite_frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var meio := Vector2(tex.get_width(), tex.get_height()) * 0.5
	var pos := _anim.position + (Vector2(float(c[0]), float(c[1])) - meio) * _anim.scale
	if _nucleo:
		_nucleo.position = pos
	var luz := get_node_or_null("Sprite/LuzCoracao") as Node2D
	if luz:
		luz.position = pos


## VFX separado da transição para a fase 2: a erupção de corrupção da
## autoridade, na base do corpo, a subir e a apagar-se. Só visual.
func _erupcao() -> void:
	var v: Dictionary = (Inimigos9D.entrada(self, CORACAO_ID).get("vfx", {}) as Dictionary).get("erupcao", {})
	var tex := load(String(v.get("ficheiro", ""))) as Texture2D if not v.is_empty() else null
	if tex == null:
		return
	var s := Sprite2D.new()
	s.name = "Erupcao9E2"
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = 1
	s.scale = Vector2.ONE * escala_visual
	var base_y := 0.0
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		base_y = col.position.y + (col.shape as RectangleShape2D).size.y * 0.5
	s.position = Vector2(0.0, base_y - tex.get_height() * escala_visual * 0.5)
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", s.position.y - 22.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 1.1).set_delay(0.35)
	tw.tween_callback(s.queue_free)


## 9G: a fase 2 não é só "mais depressa" -- a corrupção passa a arder à volta
## do corpo, sem tocar no núcleo (é o ponto fraco) nem tapar a silhueta.
func _aura_fase2() -> void:
	if _aura_f2 != null or not Vfx9G.ativo(self):
		return
	_aura_f2 = Vfx9G.novo("charge_aura_corrupcao", true)
	if _aura_f2 == null:
		return
	_aura_f2.z_index = -2
	_aura_f2.scale = Vector2.ONE * 2.6
	_aura_f2.modulate.a = 0.55
	_aura_f2.position = Vector2(0.0, 10.0)
	add_child(_aura_f2)
	_aura_f2.play("ciclo")


func _process(dt: float) -> void:
	super._process(dt)
	_casca_cd = maxf(0.0, _casca_cd - dt)
	_pulso += dt
	if _sprite:
		var amp := 0.05 if not _nucleo_exposto else 0.12
		var p := 1.0 + amp * sin(_pulso * (PI * 2.0 / 2.0) * (2.0 if _nucleo_exposto else 1.0))
		_sprite.scale = Vector2(_direcao * escala_visual * p, escala_visual * p)
	if _nucleo and _nucleo_exposto:
		var q := 1.0 + 0.18 * sin(_pulso * 12.0)
		_nucleo.scale = Vector2(q, q)
		# RECOVER: a janela esta' a fechar, o nucleo pisca (aviso legivel)
		if _dur_janela - _t < 0.4 and _dur_janela > 0.0:
			var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
			if brilho:
				brilho.visible = int(_pulso * 12.0) % 2 == 0


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	_atualiza_fase()
	match _fase:
		Fase.DORME:
			if _ve_koliani() and Som.em_vista(self):
				provocar()
				_combate = true
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			# PROTEGIDO: nada arranca com o boss fora do campo visual
			if _t >= 0.55 and Som.em_vista(self):
				_arrancar()
		Fase.RAIZES_MARCAS:
			if _t >= t_marcas:
				_piscar(false)
				_mecanica_feita()
		Fase.PULSO_TEL:
			# o aviso: brilho + marcas no chao dos dois lados, ate' as ondas partirem
			if _t >= t_pulso_tel:
				_piscar(false)
				_lancar_ondas()
				_ir(Fase.PULSO_LANCA)
		Fase.PULSO_LANCA:
			if _t >= 0.5:
				_mecanica_feita()
		Fase.BROTOS_TEL:
			if _t >= t_brotos_tel:
				_piscar(false)
				_criar_brotos()
				_ir(Fase.BROTOS_ESPERA)
		Fase.BROTOS_ESPERA:
			if _broto_estourado:
				_abrir_janela(janela_aberta * 1.5 * (0.8 if _f2 else 1.0))
			elif _t >= t_brotos_espera * (0.8 if _f2 else 1.0):
				_mecanica_feita()
		Fase.EXPOSTO:
			if _t >= _dur_janela:
				_fechar_janela()
		Fase.ROAR:
			if _t >= 0.9:
				_piscar(false)
				_ir(Fase.DECIDE)
	_t += dt


## --- maquina de estados ---------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0
	historico.append(int(f))


func _vulneravel() -> bool:
	return _fase == Fase.EXPOSTO


func _proxima_mecanica() -> String:
	var padrao: Array = PADRAO_F2 if _f2 else PADRAO_F1
	return String(padrao[_ciclos % padrao.size()])


## Escolhe o padrao do ciclo e arranca a 1.a mecanica (com o aviso).
func _arrancar() -> void:
	_seq = Array(_proxima_mecanica().split("+"))
	_broto_estourado = false
	_iniciar_mecanica(String(_seq.pop_front()))


func _iniciar_mecanica(nome: String) -> void:
	match nome:
		"RAIZES":
			contagem["RAIZES"] += 1
			_piscar(true)
			_som_ataque("praga", -8.0, 1.0)
			_plantar_zona()
			_ir(Fase.RAIZES_MARCAS)
		"PULSO":
			contagem["PULSO"] += 1
			_piscar(true)
			_som_ataque("olho_carregar", -8.0, 0.6)
			_abanar_camera(1.5)
			_marcar_ondas(true)
			_ir(Fase.PULSO_TEL)
		"BROTOS":
			contagem["BROTOS"] += 1
			_piscar(true)
			_som_ataque("praga", -9.0, 0.8)
			_ir(Fase.BROTOS_TEL)


## Fim de uma mecanica: se o ciclo tem outra encadeada arranca-a, senao abre a janela.
func _mecanica_feita() -> void:
	_limpar_brotos()
	if not _seq.is_empty():
		_iniciar_mecanica(String(_seq.pop_front()))
		return
	_abrir_janela(janela_aberta * (0.8 if _f2 else 1.0))


func _abrir_janela(dur: float) -> void:
	_dur_janela = dur
	contagem["JANELAS"] += 1
	_mostrar_nucleo(true)
	_ir(Fase.EXPOSTO)
	Som.toca("mecanismo", -14.0, 1.5, 0.02, 0.2, "coracao_abre", Som.Prioridade.NORMAL)


func _fechar_janela() -> void:
	_mostrar_nucleo(false)
	_limpar_brotos()
	_dur_janela = 0.0
	_ciclos += 1
	_ir(Fase.DECIDE)


func _atualiza_fase() -> void:
	if _ja_derrotado:
		return
	var novo := fase_por_vida(vida, _vida_max)
	# a fase 2 so' arranca com o ciclo resolvido (nunca a meio de uma mecanica ou de uma janela)
	if novo != _nivel and _fase in [Fase.DORME, Fase.DECIDE, Fase.ROAR]:
		_nivel = novo
		_atualizar_frame()
		if _prod and _nivel == 2:
			_alinhar_nucleo("fase_2")
			_erupcao()
		if _nivel == 2:
			_aura_fase2()
			_entrar_fase2()
		_som_fase("carne")
		_abanar_camera(6.0)


## Fase 2: o mesmo vocabulario, avisos e janela mais curtos. So' comeca com o ciclo em curso
## resolvido -- se calhar a meio de uma mecanica, esta acaba e o ROAR entra a seguir.
func _entrar_fase2() -> void:
	_f2 = true
	t_marcas *= 0.85
	t_pulso_tel *= 0.85
	t_brotos_tel *= 0.85
	_ciclos = 0
	_seq.clear()
	_limpar_brotos()
	_marcar_ondas(false)
	_mostrar_nucleo(false)
	_piscar(true)
	_ir(Fase.ROAR)


static func fase_por_vida(vida_atual: int, vida_maxima: int) -> int:
	return 2 if vida_atual <= int(maxi(vida_maxima, 1) * 0.5) else 1


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= 520.0 and absf(d.y) <= 320.0


## --- mecanicas ---------------------------------------------------------

## RAIZES: 3 raizes em volta da Koliani com o racha visivel `atraso_raiz` s antes de irromperem
## (nunca nascem sem aviso); na fase 2 ha' mais 2 do lado oposto, mais tarde.
func _plantar_zona() -> void:
	var x0 := _x_koliani()
	for i in [-1, 0, 1]:
		_raiz_em(x0 + float(i) * 105.0, atraso_raiz)
	if _f2:
		var lado := -signf(_dir_para_koliani())
		if lado == 0.0:
			lado = 1.0
		_raiz_em(x0 + lado * 300.0, atraso_raiz + 0.45)
		_raiz_em(x0 + lado * 405.0, atraso_raiz + 0.45)


func _raiz_em(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	if _arena_ok:
		x = clampf(x, _arena_esq + 30.0, _arena_dir - 30.0)
	var r := RAIZ.instantiate()
	pai.add_child(r)
	r.global_position = Vector2(x, _chao_y(x))
	r.avisar(int(round(dano_raiz * (1.15 if _f2 else 1.0))), maxf(atraso, 0.9))


## PULSO: marcas no chao (tira magenta a piscar) dos dois lados durante o aviso.
func _marcar_ondas(ligado: bool) -> void:
	for m in _marcas_pulso:
		if is_instance_valid(m):
			m.queue_free()
	_marcas_pulso.clear()
	if not ligado:
		return
	var pai := get_parent()
	if pai == null:
		return
	for lado in [-1.0, 1.0]:
		var m := Polygon2D.new()   # PLACEHOLDER: falta a arte aprovada do aviso de onda
		m.polygon = PackedVector2Array([Vector2(0, -3), Vector2(320, -3), Vector2(320, 3), Vector2(0, 3)])
		m.color = Color(1.0, 0.35, 0.85, 0.85)
		m.scale.x = 1.0 if lado > 0.0 else -1.0
		m.global_position = Vector2(global_position.x + lado * 60.0, _chao_y(global_position.x + lado * 80.0) - 2.0)
		m.z_index = 5
		pai.add_child(m)
		var t := m.create_tween().set_loops()
		t.tween_property(m, "modulate:a", 0.25, 0.14)
		t.tween_property(m, "modulate:a", 1.0, 0.14)
		_marcas_pulso.append(m)


func _lancar_ondas() -> void:
	_marcar_ondas(false)
	_som_impacto("esmagar", -6.0, 0.8)
	_abanar_camera(4.0)
	_onda(-1.0, vel_onda)
	_onda(1.0, vel_onda)


## Onda rasteira (44x40): so' magoa quem a apanhar no chao -- salta-se por cima ou atravessa-se de
## Dash (invulneravel). Cada onda fere no maximo uma vez.
func _onda(dir: float, vel: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var esq := _arena_esq if _arena_ok else global_position.x - 460.0
	var dr := _arena_dir if _arena_ok else global_position.x + 460.0
	var x0 := global_position.x + dir * 70.0
	var alvo := (dr + 40.0) if dir > 0.0 else (esq - 40.0)
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(44.0, 40.0)
	forma.shape = rs
	a.add_child(forma)
	var poly := Polygon2D.new()   # PLACEHOLDER: falta a arte aprovada da onda de esporos
	poly.polygon = PackedVector2Array([Vector2(-22, 20), Vector2(-14, -10), Vector2(0, -20), Vector2(14, -10), Vector2(22, 20)])
	poly.color = Color(0.95, 0.3, 0.8, 0.9)
	a.add_child(poly)
	pai.add_child(a)
	a.global_position = Vector2(x0, _chao_y(x0) - 20.0)
	var dano := int(round(dano_pulso * (1.15 if _f2 else 1.0)))
	var bateu := [false]
	a.body_entered.connect(func(corpo: Node) -> void:
		if not bateu[0] and corpo is Koliani:
			bateu[0] = true
			corpo.receber_dano(dano, dir))
	var tw := a.create_tween()
	tw.tween_property(a, "global_position:x", alvo, absf(alvo - x0) / maxf(vel, 1.0))
	tw.tween_callback(a.queue_free)


## BROTOS: dois brotos nos flancos (alvos de Pogo, sem dano).
func _criar_brotos() -> void:
	_limpar_brotos()
	var pai := get_parent()
	if pai == null:
		return
	for lado in [-1.0, 1.0]:
		var x: float = global_position.x + lado * 240.0
		if _arena_ok:
			x = clampf(x, _arena_esq + 40.0, _arena_dir - 40.0)
		var b: Area2D = BROTO.new()
		pai.add_child(b)
		b.global_position = Vector2(x, _chao_y(x))
		b.estourou.connect(_ao_broto_estourar)
		_brotos.append(b)


func _ao_broto_estourar() -> void:
	if _fase != Fase.BROTOS_ESPERA:
		return
	contagem["BROTOS_ESTOURADOS"] += 1
	_broto_estourado = true
	_abanar_camera(3.0)
	_som_impacto("esmagar", -8.0, 1.2)


func _limpar_brotos() -> void:
	for b in _brotos:
		if is_instance_valid(b):
			b.murchar()
	_brotos.clear()


## --- núcleo / dano ----------------------------------------------------

## Escolhe o frame da tira pixel-art conforme o estado: sístole (batida) usa
## o frame "grande/aceso"; entre batidas usa o frame da fase actual.
func _atualizar_frame() -> void:
	if _corpo == null:
		return
	if _nucleo_exposto:
		_corpo.frame = 2 if _nivel >= 2 else 1
	else:
		_corpo.frame = 0


func _mostrar_nucleo(v: bool) -> void:
	_nucleo_exposto = v
	_atualizar_frame()
	if _sprite:
		_sprite.modulate = Color(1.35, 1.2, 1.1) if v else Color(0.88, 0.9, 0.95)
	if _nucleo == null:
		return
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.8 if v else 0.14
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


## O nucleo absorve parte da onda espectral (Especial/tiro): passa 45 % do dano. Assim o Especial ajuda
## na janela sem resolver a luta -- e gasta-lo com o coracao PROTEGIDO desperdica a Energia.
## 3 out 2026: era 0,6. Medido em segundos de JOGO (o teste media mal antes -- ver `_coracao_luta`),
## o Especial cortava o TTK a 0,48x (alvo >= 0,55x). Valor PROPOSTO, a confirmar em playtest.
const RESIST_TIRO := 0.45


func receber_tiro(quantidade: int, dir_empurrao := 0.0) -> void:
	receber_dano(maxi(1, int(round(float(quantidade) * RESIST_TIRO))), dir_empurrao)


## Na janela o coracao esta' ABERTO: encostar-se para bater nao magoa. Fora dela o contacto magoa.
func _ao_tocar(corpo: Node) -> void:
	if _vulneravel():
		return
	super._ao_tocar(corpo)


func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if not ligado and _sprite:
		_sprite.modulate = Color(1.35, 1.2, 1.1) if _nucleo_exposto else Color(0.88, 0.9, 0.95)


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if _vulneravel() or _fase == Fase.DORME:
		super.receber_dano(quantidade, dir_empurrao, critico)
		if _prod and _nivel >= 2 and _anim and _anim.animation == "hit" 				and _anim.sprite_frames.has_animation("hit_f2"):
			_anim.play("hit_f2")
		return
	# CASCA: o golpe entra so' em fracao, sem recuo e sem critico
	var q := maxi(1, int(round(float(quantidade) * RESIST_CASCA)))
	if vida - q <= 0:
		super.receber_dano(quantidade, dir_empurrao, false)
		return
	vida -= q
	vida_mudou.emit(maxi(vida, 0), _vida_maxima)
	if _casca_cd <= 0.0:
		_casca_cd = 0.1
		Som.toca("bloqueio", -9.0, 0.85, 0.03, 0.0, "", Som.Prioridade.NORMAL)
		Impacto.rebentar(self, global_position + Vector2(0.0, -30.0 * maxf(0.8, escala_visual)),
			Color(0.62, 0.4, 0.62), 1.3)


## --- utilitários ----------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return global_position.y + 200.0
	var de := Vector2(x, global_position.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 600.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 260.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
