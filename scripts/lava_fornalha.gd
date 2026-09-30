class_name LavaFornalha
extends AguaVenenosa
## Lava da Regiao IV -- Fornalha. A `AguaVenenosa` e' um fosso que mata ao
## toque; a prancha da regiao pede outra coisa ("Lava: dano continuo, alta
## letalidade, pode ter variacoes", `implementation_sheet` §4) e o N16 fala em
## "lava rasa". Aqui a lava MAGOA em vez de matar: cada toque leva `dano_lava`
## e, enquanto se estiver dentro, repete-se a cada `repete_seg` (com os
## i-frames da Koliani pelo meio). Com `letal = true` volta a ser o fosso
## (as lavas fundas do N18 em diante). A poca deve ter chao por baixo para se
## poder sair dela a saltar; quem a desenha e' que garante isso.

@export var dano_lava := 22
@export var repete_seg := 0.6
@export var letal := false
@export var impulso_saida := 0.0

## Pintura da superficie (`r4_lava_estatica`, prancha). Se existir, substitui
## o poligono ondulado da `AguaVenenosa` -- que excede a poca uma vaga para
## cada lado e, num fosso entre dois chaos, deixava a lava a espreitar por
## cima deles -- por uma caixa EXACTA da largura da poca.
@export var textura_lava: Texture2D
@export var escala_textura := 0.5

var _t_rep := 0.0
var _tex: Sprite2D
var _linha: Polygon2D
var _glow: Polygon2D


func _pronto() -> void:
	super._pronto()
	dano = 999 if letal else dano_lava
	if textura_lava:
		_montar_textura()


func _montar_textura() -> void:
	for n in [_sup, _faixa, _rim]:
		if n:
			(n as CanvasItem).visible = false
	for v in _veu:
		v.visible = false
	var hw := largura * 0.5
	var hh := altura * 0.5
	var base := Polygon2D.new()
	base.color = Color(0.5, 0.1, 0.03, 1.0)
	base.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh)])
	add_child(base)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_tex = Sprite2D.new()
	_tex.texture = textura_lava
	_tex.centered = false
	_tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_tex.region_enabled = true
	_tex.region_rect = Rect2(0.0, 0.0, largura / escala_textura, altura / escala_textura)
	_tex.scale = Vector2(escala_textura, escala_textura)
	_tex.position = Vector2(-hw, -hh)
	_tex.material = mat
	add_child(_tex)
	# linha de fusao no topo: brilho estreito + halo largo e fraco
	_glow = Polygon2D.new()
	_glow.color = Color(1.0, 0.45, 0.12, 0.35)
	_glow.polygon = PackedVector2Array([Vector2(-hw, -hh - 8.0), Vector2(hw, -hh - 8.0),
		Vector2(hw, -hh + 6.0), Vector2(-hw, -hh + 6.0)])
	add_child(_glow)
	_linha = Polygon2D.new()
	_linha.color = Color(1.0, 0.82, 0.45, 0.95)
	_linha.polygon = PackedVector2Array([Vector2(-hw, -hh - 1.0), Vector2(hw, -hh - 1.0),
		Vector2(hw, -hh + 2.0), Vector2(-hw, -hh + 2.0)])
	add_child(_linha)
	for n in [base, _tex, _glow, _linha]:
		(n as Node).physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(dt: float) -> void:
	super._process(dt)
	if _tex:
		_tex.region_rect.position.x += dt * 9.0 / escala_textura
		var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003)
		_tex.modulate = Color(1.0, 0.85 + 0.1 * p, 0.8, 0.8 + 0.2 * p)
		_linha.color.a = 0.8 + 0.2 * p
	if letal:
		return
	_t_rep -= dt
	if _t_rep <= 0.0:
		_t_rep = repete_seg
		_ferir_presentes()


func _ferir(corpo: Node) -> void:
	super._ferir(corpo)
	if not letal and impulso_saida > 0.0 and corpo is Koliani and ativa:
		corpo.velocity.y = -impulso_saida
