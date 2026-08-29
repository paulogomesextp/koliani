class_name ChefeBase
extends DemonioBase
## Base dos chefes de mundo. Herda de `DemonioBase` (vida, dano por
## contacto, flash, estilhaços) e acrescenta o que todos os chefes
## partilham: o sinal `derrotado` (o nível usa-o para abrir a porta), a
## referência à Koliani e um telegrafo (pausa + brilho) antes dos ataques.
##
## Cada chefe concreto herda daqui e implementa o seu `_physics_process`
## com a sua máquina de estados. NÃO usar `DemonioBase` diretamente para
## chefes.

signal derrotado

var _koliani: Node2D
## Fica > 0 durante um golpe forte do chefe (o contacto magoa mais).
var _ataque_forte := 0.0
var _ja_derrotado := false
## true assim que o combate começa (troca a música para a do chefe). Fica
## false num chefe recém-instanciado (após morte/recarga), por isso a
## música só volta a mudar quando a luta recomeça de facto.
var _musica_boss := false


func _e_chefe() -> bool:
	return true


func _ready() -> void:
	super._ready()
	add_to_group("chefes")
	# chefe mais perigoso ao contacto nos mundos mais avançados (a vida-base
	# é definida por cada chefe concreto no seu _ready)
	dano_contacto = int(round(dano_contacto * (1.0 + 0.09 * float(clampi(EstadoJogo.indice_nivel, 0, 3)))))


func _process(dt: float) -> void:
	super._process(dt)
	# rede de segurança: se o chefe se atirar para fora do mapa (investida
	# num fosso, etc.), conta como derrotado -- senão o nível fica
	# bloqueado porque a porta nunca abre.
	if not _ja_derrotado and global_position.y - _origem.y > 520.0:
		_cair_derrotado()


## Marca o início do combate: troca para a música de chefe. Idempotente --
## cada chefe concreto chama isto quando a sua máquina de estados sai da
## patrulha (deteta a Koliani); `chefe_base` também chama ao trocar o
## primeiro golpe. Não basta ver o chefe: é preciso "começar a fight".
func provocar() -> void:
	if _musica_boss or _ja_derrotado:
		return
	_musica_boss = true
	Musica.boss()


func _cair_derrotado() -> void:
	_ja_derrotado = true
	Som.toca("chefe_cai", -6.0)
	Som.toca("conquista", -4.0)  # som de "conquista", distinto de matar um inimigo
	derrotado.emit()
	queue_free()


func _obter_koliani() -> Node2D:
	if not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani")
	return _koliani


func _vetor_para_koliani() -> Vector2:
	var k := _obter_koliani()
	return (k.global_position - global_position) if k else Vector2.ZERO


func _dir_para_koliani() -> float:
	var dx := _vetor_para_koliani().x
	return signf(dx) if absf(dx) > 1.0 else _direcao


## Vira o sprite para a Koliani.
func _encarar_koliani() -> void:
	_direcao = _dir_para_koliani()
	if _sprite:
		_sprite.scale.x = _direcao


func _piscar(ligado: bool) -> void:
	if _sprite:
		_sprite.modulate = Color(1.7, 1.25, 1.5) if ligado else Color(1, 1, 1)
	if ligado:
		anticipacao = 1.0  # wind-up visual (ver DemonioBase._process)


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		provocar()  # trocar o primeiro golpe = combate a sério
		var dano := int(round(dano_contacto * (1.8 if _ataque_forte > 0.0 else 1.0)))
		corpo.receber_dano(dano, signf(corpo.global_position.x - global_position.x))


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()  # levou o primeiro golpe = combate a sério
	vida -= quantidade
	global_position.x += dir_empurrao * 3.0
	if vida <= 0:
		_ja_derrotado = true
		Som.toca("chefe_cai", -6.0)
		Som.toca("conquista", -4.0)  # som de "conquista", distinto de matar um inimigo
		derrotado.emit()
		soltar_estilhacos()
		queue_free()
	else:
		piscar_dano()
