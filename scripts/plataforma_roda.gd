class_name PlataformaRoda
extends AnimatableBody2D
## Plataforma que RODA em vez de deslizar. Duas caras:
##
##  - `amplitude_graus > 0` -> **convés que inclina** (nível 78, Navio da
##    Condenação): tomba para um lado e para o outro à volta do meio. O
##    chão continua debaixo dos pés, mas deixa de ser horizontal.
##  - `amplitude_graus = 0` -> **engrenagem** (nível 56, Distrito das
##    Engrenagens): dá a volta completa, devagar. Anda-se em cima do braço
##    enquanto ele está por baixo do horizonte e sai-se antes de ele
##    subir.
##
## Roda com `sync_to_physics`, que é o que faz um `AnimatableBody2D`
## carregar quem está em cima em vez de o atravessar.
##
## O ângulo é limitado a 26° no modo convés de propósito: acima disso a
## Koliani escorrega sempre (o `floor_max_angle` dela é 45°, mas o atrito
## do jogo não segura uma rampa dessas) e o convés passava de mecânica a
## escorrega.
##
## Constrói o próprio corpo e o próprio visual: não precisa de cena.

## Meia-amplitude da inclinação, em graus. 0 = volta completa.
@export var amplitude_graus := 22.0
## Segundos de um ciclo completo (ida e volta, ou uma volta inteira).
@export var periodo := 4.0
@export var fase := 0.0
## Comprimento da prancha (ou de cada braço da engrenagem), em px.
@export var comprimento := 220.0
@export var espessura := 18.0
## Quantos braços. 1 = uma prancha; 4 = uma cruz de engrenagem.
@export var bracos := 1
@export var cor := Color(0.35, 0.29, 0.24)
## Opt-in (N13): roda de engrenagem pintada por tras dos bracos, com o
## diametro do `comprimento`, a girar com eles. Vazio = so' os bracos.
@export var textura_roda: Texture2D
## Opt-in: textura dos bracos (em mosaico), em vez da cor chapada.
@export var textura_braco: Texture2D

var _t := 0.0

const LIMITE_GRAUS := 26.0


func _ready() -> void:
	sync_to_physics = true
	amplitude_graus = clampf(amplitude_graus, 0.0, LIMITE_GRAUS)
	for i in maxi(1, bracos):
		var ang := PI * float(i) / float(maxi(1, bracos))
		var col := CollisionShape2D.new()
		var f := RectangleShape2D.new()
		f.size = Vector2(comprimento, espessura)
		col.shape = f
		col.rotation = ang
		add_child(col)
		var tab := Polygon2D.new()
		var h := Vector2(comprimento, espessura) * 0.5
		tab.polygon = PackedVector2Array([
			Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
		tab.color = cor
		tab.rotation = ang
		if textura_braco:
			tab.texture = textura_braco
			tab.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			tab.color = Color(0.92, 0.8, 0.64)   # ouro velho, nao latao novo
		add_child(tab)
	# o eixo, ao meio: é o que diz de que lado está o pivô
	var eixo := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 12:
		var a := TAU * float(k) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * (espessura * 0.9))
	eixo.polygon = pts
	eixo.color = Color(0.52, 0.48, 0.44)
	add_child(eixo)
	if textura_roda:
		eixo.visible = false
		var roda := Sprite2D.new()
		roda.name = "Roda"
		roda.texture = textura_roda
		var esc := comprimento * 1.08 / float(maxi(textura_roda.get_width(), textura_roda.get_height()))
		roda.scale = Vector2(esc, esc)
		roda.z_index = -1
		add_child(roda)
	_t = fase * periodo
	_aplicar()


func _aplicar() -> void:
	var u := _t / maxf(0.2, periodo)
	if amplitude_graus <= 0.0:
		rotation = TAU * u                       # volta completa
	else:
		rotation = deg_to_rad(amplitude_graus) * sin(TAU * u)


func _physics_process(dt: float) -> void:
	_t = fmod(_t + dt, maxf(0.2, periodo))
	_aplicar()
