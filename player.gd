
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -305.0
const DASH_VELOCITY = 700.0
const DASH_DURATION = 0.2
const jump_pad_height: float = -500.0

@onready var animated_sprite = $AnimatedSprite2D

var is_dashing = false
var facing_direction = 1

func _physics_process(delta):

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0:
		facing_direction = sign(direction)
		animated_sprite.flip_h = direction < 0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("dash") and not is_dashing:
		dash()

	if is_dashing:
		pass
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Animations
	if is_dashing:
		pass
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	move_and_slide()


func dash():
	is_dashing = true
	velocity.x = facing_direction * DASH_VELOCITY
	animated_sprite.play("dash")
	await get_tree().create_timer(DASH_DURATION).timeout
	is_dashing = false
