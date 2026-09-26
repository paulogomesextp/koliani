extends Node2D
## COMBAT LAB v1 -- arena isolada e descartavel (nao esta' ligada a nenhum nivel). Monta o chao, a
## Koliani com o `CombateLab` ligado, o registo de metricas e o HUD; 1/2/3 fazem nascer os alvos.
## Ver `docs/combat_lab_v1.md`.

const KOLIANI_CENA := preload("res://scenes/actors/Koliani.tscn")
const GOBLIN := preload("res://scenes/lab/LabGoblin.tscn")
const GOLEM := preload("res://scenes/lab/LabGolem.tscn")
const PLATAFORMA := preload("res://scenes/actors/Plataforma.tscn")

const LARGURA := 2600.0
const CHAO_Y := 700.0
## Habilidades que o lab concede (so' em memoria; restauram-se ao sair).
const KIT := ["dash", "pogo", "salto_duplo", "especial", "projetil"]

var koliani: Koliani
var lab: CombateLab
var metricas: LabMetricas
var hud: LabHud
var _hab_antes: Array = []
var _modo_dev_antes := false


func _ready() -> void:
	_hab_antes = EstadoJogo.habilidades.duplicate()
	_modo_dev_antes = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = false
	EstadoJogo.habilidades.assign(KIT)
	_montar_cenario()
	metricas = LabMetricas.new()
	metricas.name = "Metricas"
	metricas.imprimir = "--lab-log" in OS.get_cmdline_user_args()
	add_child(metricas)
	koliani = KOLIANI_CENA.instantiate()
	koliani.position = Vector2(400, CHAO_Y - 70.0)
	add_child(koliani)
	lab = koliani.ativar_combat_lab()
	hud = LabHud.new()
	hud.koliani = koliani
	hud.lab = lab
	add_child(hud)
	spawn_goblin()


func _exit_tree() -> void:
	EstadoJogo.habilidades.assign(_hab_antes)
	EstadoJogo.modo_dev = _modo_dev_antes
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


func _spawn(cena: PackedScene, dx: float) -> LabInimigo:
	var e := cena.instantiate() as LabInimigo
	var x := clampf(koliani.global_position.x + dx, 120.0, LARGURA - 120.0)
	e.position = Vector2(x, CHAO_Y - 60.0)
	e.lab_arena_x = Vector2(60.0, LARGURA - 60.0)
	add_child(e)
	return e


func spawn_goblin(dx := 320.0) -> LabInimigo:
	return _spawn(GOBLIN, dx)


func spawn_golem(dx := 380.0) -> LabInimigo:
	return _spawn(GOLEM, dx)


func limpar() -> void:
	for e in get_tree().get_nodes_in_group("lab_inimigos"):
		e.queue_free()


func _process(_dt: float) -> void:
	# lab: nao se morre (o teste e' do combate, nao da sobrevivencia)
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
			spawn_golem(520.0)
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
