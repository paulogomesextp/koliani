extends CharacterBody2D

@export var speed := 220.0
@export var jump_velocity := -420.0
@export var gravity := 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var attacking := false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sprite.play("jump")

	if Input.is_action_just_pressed("ui_accept") and not is_on_floor() and sprite.animation != "double_jump":
		velocity.y = jump_velocity
		sprite.play("double_jump")

	if Input.is_action_just_pressed("ui_down") and not attacking:
		attacking = true
		sprite.play("attack")

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = move_toward(velocity.x, direction * speed, speed * 8.0 * delta)
	if direction != 0:
		sprite.flip_h = direction < 0

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if attacking:
		if sprite.frame == sprite.sprite_frames.get_frame_count("attack") - 1:
			attacking = false
		return
	if not is_on_floor():
		return
	if Input.is_action_pressed("ui_down"):
		sprite.play("crouch")
	elif direction != 0:
		sprite.play("run")
	else:
		sprite.play("idle")
