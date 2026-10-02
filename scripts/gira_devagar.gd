class_name GiraDevagar
extends Sprite2D
## Roda decorativa que gira devagar (marco visual da Sala das Pressoes, N19).
## So' pintura: sem fisica, sem som, sem colisao. `graus_por_seg` negativo gira
## ao contrario.

@export var graus_por_seg := 3.0


func _process(dt: float) -> void:
	rotation += deg_to_rad(graus_por_seg) * dt
