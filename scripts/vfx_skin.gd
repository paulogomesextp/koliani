class_name VfxSkin
extends RefCounted
## VFX COSMETICOS DA SKIN EQUIPADA. Camadas separadas do
## corpo: nascem no pai da Koliani, nunca dentro dos frames, e nao tocam em
## fisica, hitbox, tempos nem input. Tudo o que a skin nao tiver devolve
## `false`/vazio e o jogo cai no VFX original -- por isso e' seguro sem arte.
## Slots: vfx_slash_basic, double_jump_ring, land_impact, pogo_impact, particulas.

## slot -> {frames, fps, escala, desloc (para a direita, y para baixo)}
const SLOTS := {
	"double_jump_ring": {"n": 6, "fps": 20.0, "escala": 1.0, "desloc": Vector2(0.0, 20.0)},
	"land_impact": {"n": 6, "fps": 18.0, "escala": 1.0, "desloc": Vector2(0.0, 24.0)},
	"pogo_impact": {"n": 6, "fps": 24.0, "escala": 1.0, "desloc": Vector2.ZERO},
}
static var _cache := {}
## Perfis visuais aprovados; a Shadowblade conserva o seu perfil original.
const PERFIS := {
	"anjo": {"cor": Color("f4c95d"), "luz": Color("d6f5ff"), "tema": "penas"},
	"demonio": {"cor": Color("f45b28"), "luz": Color("ffe3a0"), "tema": "brasas"},
	"abadia_afogada": {"cor": Color("25baa9"), "luz": Color("bcfff4"), "tema": "agua"},
	"celestial": {"cor": Color("dcb350"), "luz": Color("fff2bc"), "tema": "estrelas"},
}

static func perfil() -> Dictionary:
	return PERFIS.get(CosmeticosVisuais.dir_skin().get_file(), {})

## Cabelo prata: o corpo usa a propria paleta, sem saturacao pelas luzes
## roxas do cenario. Os efeitos separados continuam iluminados normalmente.
static func forca_glow_corpo() -> float:
	return 0.55 if not perfil().is_empty() or CosmeticosVisuais.dir_skin() == CosmeticosVisuais.DIR_SKIN["skin_shadowblade"] else 1.0

static func mascara_luz_corpo() -> int:
	return 0 if forca_glow_corpo() < 1.0 else 1

static func atualizar_aura(k: Node2D, corpo: AnimatedSprite2D, flash: float, tempo: float) -> void:
	if corpo == null:
		return
	var pai := corpo.get_parent()
	var aura := pai.get_node_or_null("ShadowbladeAura")
	if mascara_luz_corpo() != 0:
		if aura:
			pai.remove_child(aura)
			aura.queue_free()
		return
	var tipo := "premium" if not perfil().is_empty() else "shadowblade"
	if aura != null and aura.get_meta("tipo_skin", "shadowblade") != tipo:
		pai.remove_child(aura)
		aura.queue_free()
		aura = null
	if aura == null:
		aura = load("res://scripts/skins_premium_aura.gd" if tipo == "premium" else "res://scripts/shadowblade_aura.gd").new()
		aura.set_meta("tipo_skin", tipo)
		pai.add_child(aura)
	# Equipar em runtime tambem atualiza a cor, sem guardar estado no save.
	if aura.has_method("configurar"):
		aura.configurar(perfil())
	aura.atualizar(corpo, flash, tempo)


## Pasta `vfx/` da skin equipada ("" se nao tiver).
static func pasta(id := "") -> String:
	var d := CosmeticosVisuais.dir_skin(id)
	if d == "":
		return ""
	var v := d + "/vfx"
	return v if ResourceLoader.exists(v + "/particulas/particulas_001.png") else ""


static func frames(slot: String, n: int, id := "") -> SpriteFrames:
	var p := pasta(id)
	if p == "":
		return null
	var chave := p + "|" + slot
	if _cache.has(chave):
		return _cache[chave]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("fx")
	sf.set_animation_loop("fx", false)
	for i in n:
		var cam := "%s/%s/%s_%03d.png" % [p, slot, slot, i + 1]
		if not ResourceLoader.exists(cam):
			_cache[chave] = null
			return null
		sf.add_frame("fx", load(cam))
	_cache[chave] = sf
	return sf


## Arco do golpe da skin (os 6 frames do Golden Set repintados) ou null.
static func frames_golpe() -> SpriteFrames:
	var sf := frames("vfx_slash_basic", 6)
	if sf == null:
		return null
	var out := SpriteFrames.new()
	out.remove_animation("default")
	out.add_animation("slash")
	out.set_animation_loop("slash", false)
	for i in 6:
		out.add_frame("slash", sf.get_frame_texture("fx", i))
	return out


## Toca `slot` em `pos` (mundo). true = tocou (o chamador salta o VFX original).
static func tocar(k: Node2D, slot: String, pos: Vector2, inverter_y := false, giro := 0.0) -> bool:
	if not SLOTS.has(slot) or k.get_parent() == null:
		return false
	var cfg: Dictionary = SLOTS[slot]
	var sf := frames(slot, int(cfg["n"]))
	if sf == null:
		return false
	var a := AnimatedSprite2D.new()
	a.name = "SkinVFX_" + slot
	a.sprite_frames = sf
	sf.set_animation_speed("fx", float(cfg["fps"]))
	a.scale = Vector2.ONE * float(cfg["escala"]) * Vector2(1.0, -1.0 if inverter_y else 1.0)
	a.rotation = giro
	a.global_position = pos
	a.z_index = 1
	a.material = _aditivo()
	a.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	a.animation_finished.connect(a.queue_free)
	k.get_parent().add_child(a)
	a.play("fx")
	return true


static func desloc(slot: String) -> Vector2:
	return (SLOTS[slot]["desloc"] as Vector2) if SLOTS.has(slot) else Vector2.ZERO


## Motes de sombra (folha `particulas`): n particulas a voar de `pos`.
static func particulas(k: Node2D, pos: Vector2, n: int, dir: Vector2, vel: float, vida := 0.5) -> void:
	var sf := frames("particulas", 4)
	if sf == null or k.get_parent() == null:
		return
	var p := CPUParticles2D.new()
	p.name = "SkinVFX_particulas"
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = n
	p.lifetime = vida
	p.direction = dir
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.texture = sf.get_frame_texture("fx", 1)
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1, 1, 1, 0.9))
	rampa.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = rampa
	p.material = _aditivo()
	p.global_position = pos
	p.z_index = 1
	k.get_parent().add_child(p)
	p.emitting = true
	k.get_tree().create_timer(vida + 0.2, false).timeout.connect(p.queue_free)


static var _mat_add: CanvasItemMaterial = null

static func _aditivo() -> CanvasItemMaterial:
	if _mat_add == null:
		_mat_add = CanvasItemMaterial.new()
		_mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _mat_add
