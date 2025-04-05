extends Area2D

@export var speed := 750
@export var damage := 4

var direction := Vector2.RIGHT
var is_sine := false
var is_orbit := false
var sine_amplitude := 50.0
var sine_frequency := 2.0
var initial_angle := 0.0
var orbit_angle := 0.0
var orbit_radius := 0.0
var time_alive := 0.0

@onready var animated_sprite := $AnimatedSprite2D

func _ready() -> void:
	if animated_sprite and animated_sprite.has_animation("bullet"):
		animated_sprite.play("bullet")

	var timer = Timer.new()
	timer.wait_time = get_meta("timeout", 2.0)
	timer.one_shot = true
	timer.connect("timeout", _on_timeout)
	add_child(timer)
	timer.start()

	if has_meta("is_sine"):
		is_sine = get_meta("is_sine")
		sine_amplitude = get_meta("sine_amplitude")
		sine_frequency = get_meta("sine_frequency")
		initial_angle = get_meta("initial_angle")

	if has_meta("is_orbit"):
		is_orbit = get_meta("is_orbit")
		orbit_angle = get_meta("orbit_angle", 0.0)
		orbit_radius = get_meta("orbit_radius", 30.0)
		speed = 0

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

	# Rotaciona o sprite para a direção do movimento
	if animated_sprite:
		animated_sprite.rotation = direction.angle()

func _physics_process(delta: float) -> void:
	time_alive += delta

	if is_orbit:
		return
	elif is_sine:
		var forward = direction * speed * delta
		var perp = direction.rotated(PI / 2)
		var sine_offset = perp * sin(time_alive * sine_frequency) * sine_amplitude * delta
		position += forward + sine_offset
	else:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_timeout() -> void:
	queue_free()
