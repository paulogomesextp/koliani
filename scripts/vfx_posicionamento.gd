class_name VfxPosicionamento
extends RefCounted
## Alinha a margem visivel do arco depois da espada, para qualquer skin.
## AABB dos frames, cache por textura; nao consulta nem altera hitboxes.
static var _limites := {}

static func caixa(tex: Texture2D) -> Rect2:
	var chave := tex.get_instance_id()
	if not _limites.has(chave):
		var img := tex.get_image()
		_limites[chave] = Rect2(img.get_used_rect()) if img else Rect2(Vector2.ZERO, tex.get_size())
	return _limites[chave]

static func frente_espada(corpo: AnimatedSprite2D, animacao: String) -> float:
	if corpo == null or not corpo.sprite_frames.has_animation(animacao):
		return 40.0
	var frente := 0.0
	for i in corpo.sprite_frames.get_frame_count(animacao):
		var tex := corpo.sprite_frames.get_frame_texture(animacao, i)
		var r := caixa(tex)
		var centro := tex.get_size()*0.5 if corpo.centered else Vector2.ZERO
		frente = maxf(frente, (r.end.x-centro.x+corpo.offset.x)*absf(corpo.scale.x))
	return frente

static func minimo_frontal(efeito: AnimatedSprite2D, sentido: float) -> float:
	var minimo := INF
	var transformacao := Transform2D(efeito.rotation, efeito.scale, 0.0, Vector2.ZERO)
	for i in efeito.sprite_frames.get_frame_count(efeito.animation):
		var tex := efeito.sprite_frames.get_frame_texture(efeito.animation, i)
		var r := caixa(tex)
		var centro := tex.get_size()*0.5 if efeito.centered else Vector2.ZERO
		for canto in [r.position, Vector2(r.end.x,r.position.y), r.end, Vector2(r.position.x,r.end.y)]:
			var p: Vector2 = transformacao*(canto-centro+efeito.offset)
			minimo = minf(minimo, p.x*sentido)
	return minimo

static func alinhar(efeito: AnimatedSprite2D, corpo: AnimatedSprite2D, animacao: String, sentido: float) -> void:
	var frente := frente_espada(corpo, animacao)
	efeito.position.x = sentido*(frente+2.0-minimo_frontal(efeito, sentido))
