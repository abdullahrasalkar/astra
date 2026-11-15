extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_pressed("Rewind"):
		return
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	#if velocity.length() > 0:
		#$AnimatedSprite2D.play()
	#elif:
		#$AnimatedSprite2D.flip_h = velocity.x < 0
		#$AnimationSprite2D.play()
	#else:
		#$AnimatedSprite2D.stop()
		#
	if Input.is_action_just_pressed("ui_left"):
		$AnimatedSprite2D.play("run")
		
	if Input.is_action_just_pressed("ui_left"):
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.animation = ("run")
	move_and_slide()
