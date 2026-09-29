extends Node2D
## FASE 11 -- PRODUCTION COMBAT QA ARENA: valida o Core Combat (Fases 2-9) com a KOLIANI REAL de
## produção (`scenes/actors/Koliani.tscn`, o MESMO recurso que os 100 níveis usam) e os DOIS
## pilotos reais do Enemy Combat Contract v1 -- não personagens duplicadas, não o Combat Lab.
## Isolada e descartável: não está ligada ao campaign flow (nenhum nível a carrega).
## Ver `docs/plano_integracao_combate_producao.md` e `docs/combat_production_integration_report.md`.

const KOLIANI_CENA := preload("res://scenes/actors/Koliani.tscn")
const DEMONIO_CENA := preload("res://scenes/actors/DemonioBase.tscn")
const PLATAFORMA := preload("res://scenes/actors/Plataforma.tscn")

const LARGURA := 2600.0
const CHAO_Y := 700.0
## Habilidades para testar tudo (dash/pogo/salto duplo/especial/projetil) -- so' em memoria.
const KIT := ["dash", "pogo", "salto_duplo", "especial", "projetil"]

var koliani: Koliani
var core: CoreCombate
var metricas: LabMetricas
var hud: QaCombateHud
var _hab_antes: Array = []
var _modo_dev_antes := false
var _indice_nivel_antes := 0
## `DemonioBase._ready()` escala vida/dano_contacto/velocidade por `EstadoJogo.indice_nivel`
## (curva de dificuldade da campanha) -- para os pilotos nascerem EXACTAMENTE como em produção,
## a arena tem de fixar o indice do nivel de casa de cada um antes de os instanciar.
const INDICE_N1 := 0
const INDICE_N6 := 5


func _ready() -> void:
	_hab_antes = EstadoJogo.habilidades.duplicate()
	_modo_dev_antes = EstadoJogo.modo_dev
	_indice_nivel_antes = EstadoJogo.indice_nivel
	EstadoJogo.modo_dev = false   # dano real -- e' um teste de combate, nao de sobrevivencia (ver _process)
	EstadoJogo.habilidades.assign(KIT)
	_montar_cenario()
	metricas = LabMetricas.new()
	metricas.name = "Metricas"
	metricas.imprimir = "--qa-log" in OS.get_cmdline_user_args()
	add_child(metricas)
	koliani = KOLIANI_CENA.instantiate()
	koliani.position = Vector2(400, CHAO_Y - 70.0)
	# a MESMA Koliani dos niveis de producao (golden set + prototipo premium) -- ver commit 30975ccd
	koliani.usar_prototipo_premium = true
	koliani.usar_golden_set = true
	add_child(koliani)
	core = koliani.ativar_core_combate()
	hud = QaCombateHud.new()
	hud.koliani = koliani
	hud.core = core
	add_child(hud)
	spawn_goblin()


func _exit_tree() -> void:
	EstadoJogo.habilidades.assign(_hab_antes)
	EstadoJogo.modo_dev = _modo_dev_antes
	EstadoJogo.indice_nivel = _indice_nivel_antes
	Engine.time_scale = 1.0


func _montar_cenario() -> void:
	var fundo := CanvasLayer.new()
	fundo.layer = -20
	var cor := ColorRect.new()
	cor.color = Color(0.09, 0.08, 0.14)
	cor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(cor)
	add_child(fundo)
	var chao := PLATAFORMA.instantiate()
	chao.position = Vector2(LARGURA * 0.5, CHAO_Y + 30.0)
	chao.tamanho = Vector2(LARGURA, 60.0)
	add_child(chao)
	for x in [-40.0, LARGURA + 40.0]:
		var parede := StaticBody2D.new()
		parede.collision_layer = 1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(80.0, 1600.0)
		cs.shape = r
		parede.add_child(cs)
		parede.position = Vector2(x, 0.0)
		add_child(parede)


## Configuração IDÊNTICA à instância real de produção -- ver `scenes/levels/Floresta_Putrefata.tscn`
## (`GoblinAprendiz`, Fase 8) / `scenes/levels/Prisao_dos_Condenados.tscn` (`EliteGolem`, Fase 9).
## Não duplica o inimigo: reproduz os MESMOS exports da instância piloto real.
func spawn_goblin(dx := 320.0) -> DemonioBase:
	EstadoJogo.indice_nivel = INDICE_N1
	var e := DEMONIO_CENA.instantiate() as DemonioBase
	e.especie = "goblin"
	e.comportamento = "carga"
	e.alcance_patrulha = 110.0
	e.piloto_combate_v1 = true
	e.peso = "leve"
	e.pode_ser_lancado = true
	var x := clampf(koliani.global_position.x + dx, 120.0, LARGURA - 120.0)
	e.position = Vector2(x, CHAO_Y - 60.0)
	add_child(e)
	return e


func spawn_golem(dx := 480.0) -> DemonioBase:
	EstadoJogo.indice_nivel = INDICE_N6
	var e := DEMONIO_CENA.instantiate() as DemonioBase
	e.especie = "golem_aereo"
	e.elite = true
	e.scale = Vector2(1.4, 1.4)
	e.vida = 165
	e.dano_contacto = 22
	e.comportamento = "carga"
	e.alcance_patrulha = 150.0
	e.cor_rim = Color(0.6, 0.55, 1.0, 1)
	e.piloto_combate_v1 = true
	e.peso = "pesado"
	e.pode_ser_lancado = false
	e.tem_guarda_v1 = true
	e.guarda_max_v1 = 100.0
	var x := clampf(koliani.global_position.x + dx, 120.0, LARGURA - 120.0)
	e.position = Vector2(x, CHAO_Y - 60.0)
	add_child(e)
	return e


func limpar() -> void:
	for e in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(e) and e != koliani:
			e.queue_free()


func _process(_dt: float) -> void:
	# QA de combate, nao de sobrevivencia: a Koliani nao morre nesta arena.
	if koliani and koliani.vida < 40:
		koliani.vida = koliani._vida_max()
		koliani.vida_mudou.emit(koliani.vida, koliani._vida_max())


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	match (ev as InputEventKey).physical_keycode:
		KEY_1:
			spawn_goblin()
		KEY_2:
			spawn_golem()
		KEY_3:
			spawn_goblin(300.0)
			spawn_golem(560.0)
		KEY_R:
			limpar()
			koliani.global_position = Vector2(400, CHAO_Y - 70.0)
			koliani.vida = koliani._vida_max()
			koliani.ganhar_energia(99.0)
			metricas.limpar()
		KEY_P:
			print(metricas.resumo())
		KEY_H:
			hud.alternar_ajuda()
