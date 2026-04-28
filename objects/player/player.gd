class_name Player
extends CharacterBody2D
## Basic Player Controller based on Godot's built-in template.

const SPEED = 150.0

var direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	
	if direction:
		# We don't need to use delta here because _physics_process runs at
		# a fixed FPS regardless of hardware.
		velocity = direction.normalized() * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()
