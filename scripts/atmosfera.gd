extends Node2D
## Montagem de ambiente reutilizável -- a "luz tipo Dead Cells" com
## placeholders, para não a copiar em cada mundo. Junta:
##   - `CanvasModulate` (tom geral do mundo)
##   - `ParallaxBackground` com 2 camadas de silhuetas
##   - `CanvasLayer` de vinheta radial
##   - 2 `PointLight2D` de ambiente
##
## Cada mundo instancia `scenes/fx/Atmosfera.tscn` e afina as cores pelos
## `@export`. As formas ficam propositadamente vagas -- é greybox.

@export var cor_ambiente := Color(0.45, 0.45, 0.5)
@export var cor_fundo := Color(0.05, 0.06, 0.09)
@export var cor_silhueta := Color(0.09, 0.11, 0.16)
@export var cor_luz := Color(0.4, 0.55, 0.9)


func _ready() -> void:
	var modulacao := get_node_or_null("Modulacao") as CanvasModulate
	if modulacao:
		modulacao.color = cor_ambiente

	var longe := get_node_or_null("Parallax/Longe")
	if longe:
		for n in longe.get_children():
			if n is ColorRect:
				n.color = cor_fundo if n.name == "Fundo" else cor_silhueta.darkened(0.3)

	var meio := get_node_or_null("Parallax/Meio")
	if meio:
		for n in meio.get_children():
			if n is ColorRect:
				n.color = Color(cor_silhueta, 0.5) if n.name == "Bruma" else cor_silhueta

	var luzes := get_node_or_null("Luzes")
	if luzes:
		for l in luzes.get_children():
			if l is PointLight2D:
				l.color = cor_luz
