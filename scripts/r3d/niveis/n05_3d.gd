extends Nivel3D
## N05 -- Coracao da Floresta (BOSS REGIONAL). Aproximacao curta pela floresta
## ja' tomada pela corrupcao, fogueira antes da arena, e a ARENA no oco das
## raizes da arvore-mae, onde bate o CORACAO PUTREFACTO.
## Vitoria = o mesmo que o 2D (`nivel_com_chefe.gd`): marca o chefe derrotado,
## concede `salto_duplo` (HABILIDADE_DO_CHEFE[4]), mostra o cartao
## "region.1.complete" e so' depois abre o portal.

const HABILIDADE_DO_CHEFE := "salto_duplo"
const CARTAO := "region.1.complete"

var chefe: ChefeCoracao3D
var _hab_ganha := ""
var _parede: StaticBody3D
var _parede_vis: Node3D
var _selada := false
var centro_arena := Vector3(0, 0, 52)


func construir() -> void:
	indice = 4
	perfil = 4
	y_morte = -4.0
	spawn = Vector3(0, 0.2, 0)
	# 1. aproximacao: floresta tomada pela corrupcao
	ilha(Vector3(0, 0, 0), 6.5, 6.0, 0.0, 4.0, "terreno_corrompido", 61)
	D.arco(deco, Vector3(0, 0, -4.5), 0.0, 4.2, 4.8, 61, true)
	faixa(Vector3(0, 0, 3), Vector3(2, 0, 24), 5.5, 3.5, "terreno_corrompido", 61)
	for i in 5:
		var z := 6.0 + i * 4.5
		var s := 1.0 if i % 2 == 0 else -1.0
		D.arvore(deco, Vector3(1 + s * 7.5, -0.3, z), randf_range(14, 20), 0.9, 61 + i, true)
		D.corrupcao(deco, Vector3(1 + s * 4.2, 0, z + 1.5), randf_range(0.6, 1.1), 61 + i)
	inimigo("goblin", Vector3(1.5, 0, 12), 2.0)
	inimigo("gosma", Vector3(0.5, 0, 17), 1.5)
	inimigo("goblin", Vector3(2.5, 0, 20), 2.0)
	folhagem(Vector3(1, 0, 12), 6.0, 80, "feto_corrompido", 61)
	folhagem(Vector3(1, 0, 12), 6.0, 60, "erva", 62)
	passo(Vector3(0, 0, 0))
	passo(Vector3(0.8, 0, 8), false, true)
	passo(Vector3(1.5, 0, 16), false, true)
	passo(Vector3(2.0, 0, 22), false, true)
	# 2. antecamara + fogueira (checkpoint antes do chefe)
	ilha(Vector3(1.5, 0, 28), 5.0, 4.0, 0.0, 4.0, "terreno_corrompido", 62)
	fogueira("n05_cp_boss", Vector3(-1.0, 0, 27.5))
	D.menir(deco, Vector3(4.5, 0, 28), 3.2, 61, true)
	passo(Vector3(1.5, 0, 28))
	# 3. arena: o oco das raizes da arvore-mae
	faixa(Vector3(1.5, 0, 30), Vector3(0.5, 0, 37), 4.5, 3.5, "terreno_corrompido", 63)
	ilha(centro_arena, 18.0, 18.0, 0.0, 6.0, "terreno_corrompido", 63)
	_muralha_raizes()
	chefe = ChefeCoracao3D.new()
	chefe.position = centro_arena
	chefe.raio_arena = 16.5
	vivos.add_child(chefe)
	chefe.derrotado.connect(_ao_chefe_derrotado)
	chefe.combate_iniciado.connect(_ao_combate)
	# a arvore-mae por tras/por cima do coracao
	var mae := D.arvore(deco, centro_arena + Vector3(0, -1.0, 22.0), 50.0, 4.2, 66, true, true, false)
	mae.scale = Vector3(1.0, 1.0, 1.0)
	D.raio_luz(deco, centro_arena + Vector3(-3, 0, -2), 34.0, 6.0, true)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		D.corrupcao(deco, centro_arena + Vector3(cos(a), 0, sin(a)) * 14.0, 1.3, 70 + i)
	passo(Vector3(0.8, 0, 35))
	passo(Vector3(0.0, 0, 41), false, true)
	# saida (abre so' depois do cartao)
	saida(centro_arena + Vector3(0, 0, 12.5), PI, false)
	veneno(Vector3(0, -2.5, 30), Vector2(110, 130))
	D.fundo_floresta(deco, Vector3(0, -1, 35), 34.0, 52.0, 36, 5, 0.6)
	VFX.esporos(self, centro_arena + Vector3(0, 4, 0), Vector3(15, 5, 15), Color(1.0, 0.35, 0.7, 0.9), 200)


## Muralha de raizes a toda a volta da arena (com abertura na entrada que se
## fecha quando o combate comeca).
func _muralha_raizes() -> void:
	var c := centro_arena
	var m := K.mat("casca_morta")
	var corpo := StaticBody3D.new()
	terreno.add_child(corpo)
	var n := 22
	for i in n:
		var a := TAU * i / n
		var d := Vector3(cos(a), 0, sin(a))
		var entrada := absf(angle_difference(a, -PI * 0.5)) < 0.35
		if entrada:
			continue
		var p := c + d * 17.2
		var pts := K.curva(PackedVector3Array([p + Vector3.DOWN, p + d * 0.6 + Vector3.UP * 2.5,
			p - d * 0.6 + Vector3.UP * 5.0, p + Vector3.UP * 7.5 - d * 1.2]), 3)
		K.inst(deco, K.tubo(pts, K.afunilar(pts.size(), 1.3, 0.2), 8, 0.25, i), m)
		var f := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(5.2, 9.0, 1.6)
		f.shape = bx
		corpo.add_child(f)
		f.global_transform = Transform3D(Basis(Vector3.UP, -a + PI * 0.5), p + Vector3.UP * 3.5)
	# porta de espinhos (fecha a entrada durante o combate)
	_parede = StaticBody3D.new()
	_parede.collision_layer = 0
	terreno.add_child(_parede)
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(9.0, 8.0, 1.6)
	f.shape = bx
	_parede.add_child(f)
	_parede.global_position = c + Vector3(0, 3.5, -17.2)
	_parede_vis = Node3D.new()
	vivos.add_child(_parede_vis)
	_parede_vis.global_position = c + Vector3(0, 0, -17.2)
	for i in 9:
		var x := -4.0 + i
		var pts := K.curva(PackedVector3Array([Vector3(x, -1, 0), Vector3(x + 0.3, 2.5, 0.3), Vector3(x - 0.2, 5.5, -0.2)]), 3)
		K.inst(_parede_vis, K.tubo(pts, K.afunilar(pts.size(), 0.45, 0.0), 6, 0.2, i), K.mat("corrupcao"))
	_parede_vis.scale = Vector3(1, 0.01, 1)
	_parede_vis.visible = false


func _ao_combate(_c: Node) -> void:
	if _selada:
		return
	_selada = true
	_parede.collision_layer = 1
	_parede_vis.visible = true
	_parede_vis.create_tween().tween_property(_parede_vis, "scale", Vector3.ONE, 0.35)
	Som.toca("raiz_irrompe", -6.0, 0.8)
	camara.foco = chefe


func _ao_chefe_derrotado() -> void:
	camara.foco = null
	EstadoJogo.marcar_chefe_derrotado_por_nivel(EstadoJogo.indice_nivel)
	if not EstadoJogo.tem_habilidade(HABILIDADE_DO_CHEFE):
		EstadoJogo.desbloquear_habilidade(HABILIDADE_DO_CHEFE)
		_hab_ganha = HABILIDADE_DO_CHEFE
	print("KOLIANI 3D | chefe N05 derrotado | habilidade=%s" % EstadoJogo.tem_habilidade(HABILIDADE_DO_CHEFE))
	# a muralha de espinhos recolhe
	var t := _parede_vis.create_tween()
	t.tween_property(_parede_vis, "scale", Vector3(1, 0.01, 1), 0.5)
	_parede.collision_layer = 0
	await get_tree().create_timer(2.2).timeout
	if not is_inside_tree():
		return
	var cartao := preload("res://scripts/cartao_regiao.gd").mostrar(self, CARTAO, _hab_ganha)
	if cartao and cartao.has_signal("fechado"):
		cartao.fechado.connect(_abrir_saida)
		if Nivel3D.qa_auto:
			get_tree().create_timer(1.5).timeout.connect(func() -> void:
				if is_instance_valid(cartao):
					cartao.fechado.emit()
					cartao.queue_free())
	else:
		_abrir_saida()


func _abrir_saida() -> void:
	portal.abrir()
	# rota do bot/camara ate' ao portal
	passo(centro_arena + Vector3(-6, 0, 6))
	passo(centro_arena + Vector3(0, 0, 12.5))
	camara.definir_rota(rota)
