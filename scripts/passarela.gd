@tool
class_name Passarela
extends Node2D
## Estrutura de passarela / ponte de madeira e ferro sob um vão de
## plataformas -- a "identidade visual" das arenas suspensas sobre o abismo
## (Fornalha, Prisão...). Puramente decorativa: não tem colisão (a
## `Plataforma` por cima é que dá o chão). Desenha-se em `_draw()`:
##   - deck de tábuas com juntas
##   - postes verticais a descer para o escuro, com escoras diagonais
##   - ferragens nos apoios + (opcional) correntes penduradas com barriga
##
## Colocar como filho do nível, centrado no vão, `z_index` negativo para as
## plataformas e a Koliani ficarem à frente.

@export var vao := 900.0
## Espessura do deck (a face de cima alinha com y = 0).
@export var espessura_deck := 16.0
## Distância entre postes.
@export var passo_poste := 170.0
## Até onde descem os postes.
@export var profundidade := 460.0
@export var correntes := true
@export var cor_madeira := Color(0.30, 0.19, 0.11)
@export var cor_madeira_esc := Color(0.16, 0.10, 0.06)
@export var cor_metal := Color(0.24, 0.22, 0.26)


func _ready() -> void:
	queue_redraw()


func _process(_dt: float) -> void:
	# live-preview no editor: redesenha se afinarem os @export
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	var meia := vao * 0.5
	var deck_topo := 0.0
	var deck_base := espessura_deck

	# --- deck de tábuas ---
	draw_rect(Rect2(-meia, deck_topo, vao, espessura_deck), cor_madeira)
	draw_rect(Rect2(-meia, deck_topo, vao, 3.0), cor_madeira.lightened(0.18))
	draw_rect(Rect2(-meia, deck_base - 3.0, vao, 3.0), cor_madeira_esc)
	var x := -meia
	while x < meia:
		draw_line(Vector2(x, deck_topo), Vector2(x, deck_base), cor_madeira_esc, 2.0)
		x += 46.0

	# --- postes + escoras ---
	var n := int(vao / passo_poste)
	for i in n + 1:
		var px := -meia + float(i) * (vao / float(maxi(1, n)))
		var largura_poste := 12.0
		# poste
		draw_rect(Rect2(px - largura_poste * 0.5, deck_base, largura_poste, profundidade),
				cor_madeira_esc)
		draw_rect(Rect2(px - largura_poste * 0.5, deck_base, 3.0, profundidade),
				cor_madeira.darkened(0.1))
		# ferragem no topo do poste
		draw_rect(Rect2(px - 10.0, deck_base - 2.0, 20.0, 8.0), cor_metal)
		# escoras diagonais para o poste seguinte
		if i < n:
			var px2 := px + (vao / float(maxi(1, n)))
			var y0 := deck_base + profundidade * 0.28
			var y1 := deck_base + profundidade * 0.72
			draw_line(Vector2(px, y0), Vector2(px2, y1), cor_madeira_esc, 5.0)
			draw_line(Vector2(px2, y0), Vector2(px, y1), cor_madeira_esc, 5.0)
			# travessa horizontal
			draw_line(Vector2(px, y0), Vector2(px2, y0), cor_madeira_esc, 4.0)
		# ponta do poste esboroada
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - largura_poste * 0.5, deck_base + profundidade),
			Vector2(px + largura_poste * 0.5, deck_base + profundidade),
			Vector2(px + randf_range(-4.0, 4.0), deck_base + profundidade + randf_range(6.0, 20.0)),
		]), cor_madeira_esc)

	# --- correntes penduradas entre alguns postes ---
	if correntes and n >= 2:
		for i in n:
			if i % 2 != 0:
				continue
			var ax := -meia + float(i) * (vao / float(maxi(1, n)))
			var bx := ax + (vao / float(maxi(1, n))) * 2.0
			if bx > meia:
				break
			var sag := 42.0
			var pts := PackedVector2Array()
			for s in 13:
				var t := float(s) / 12.0
				var cx := lerpf(ax, bx, t)
				var cy := deck_base + 10.0 + sin(t * PI) * sag
				pts.append(Vector2(cx, cy))
			draw_polyline(pts, cor_metal, 3.0)
