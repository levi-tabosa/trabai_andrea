extends Area2D

@export var speed := 750
@export var damage := 4
#@export var timeout := 2.0

var direction := Vector2.RIGHT  # Default
var is_sine := false
var is_orbit := false
var sine_amplitude := 50.0
var sine_frequency := 2.0
var initial_angle := 0.0
var orbit_angle := 0.0
var orbit_radius := 0.0
var time_alive := 0.0

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = get_meta("timeout", 2.0)
	timer.one_shot = true
	timer.connect("timeout", _on_timeout)
	add_child(timer)
	timer.start()
	
	# Check for special behaviors
	if has_meta("is_sine"):
		is_sine = get_meta("is_sine")
		sine_amplitude = get_meta("sine_amplitude")
		sine_frequency = get_meta("sine_frequency")
		initial_angle = get_meta("initial_angle")
	
	if has_meta("is_orbit"):
		is_orbit = get_meta("is_orbit")
		orbit_angle = get_meta("orbit_angle", 0.0)
		orbit_radius = get_meta("orbit_radius", 30.0)
		speed = 0  # Orbit projectiles don't move forward

func _physics_process(delta: float) -> void:
	time_alive += delta
	
	if is_orbit:
		# Comportamento em modo orbita gerenciado pelo Player
		return
	elif is_sine:
		var forward_movement = direction * speed * delta
		var perpendicular = direction.rotated(PI/2)
		var sine_offset = perpendicular * sin(time_alive * sine_frequency) * sine_amplitude * delta
		position += forward_movement + sine_offset
	else:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	queue_free()

func _on_timeout() -> void:
	queue_free()
