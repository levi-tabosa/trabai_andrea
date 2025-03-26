# Projectile.gd
extends Area2D

@export var SPEED = 750
@export var lifetime = 2.0  # How long the projectile lasts in seconds

func _ready() -> void:
	# Add a timer for projectile lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.connect("timeout", _on_lifetime_timeout)
	add_child(timer)
	timer.start()

func _physics_process(delta: float) -> void:
	# Move in the direction we're facing
	position += transform.x * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	# Check if we hit something we should destroy
	if body.is_in_group("mobs"):
		body.queue_free()
	queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
