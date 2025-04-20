extends CharacterBody2D

var screen_size: Vector2
var can_shoot = true

enum FireType {
	SINGLE,
	DOUBLE,
	TRIPLE,
	QUAD,
	SINE,
	ORBIT
}

@export var fire_type := FireType.SINGLE
@export var speed := 200
@export var fire_rate := 0.2
@export var projectile_speed := 300
@export var sine_amplitude := 115.0
@export var sine_frequency := 10.0
@export var orbit_radius := 30.0
@export var orbit_speed := 3.0
@export var health_component: HealthComponent
@export var knockback_force := 150.0
@export var knockback_duration := 0.2

@onready var main = get_tree().get_root().get_node("main")
@onready var ui = get_node("/root/main/UI")
@onready var projectile_scene = preload("res://scenes/projectile.tscn")
@onready var shoot_timer = $ShootTimer
@onready var animated = $AnimatedSprite2D

var knockback_timer := 0.0
var knockback_direction := Vector2.ZERO
enum PlayerDir { RIGHT, UP, LEFT, DOWN }
var last_dir := PlayerDir.RIGHT
var orbit_angle := 1
var orbit_projectiles := []

# Controle de animação de tiro
var is_shooting := false
var shooting_timer := 0.0
const SHOOT_ANIM_DURATION := 0.4

func _ready() -> void:
	screen_size = get_viewport_rect().size
	configure_fire_type()

	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = 100
		add_child(health_component)

	health_component.health_depleted.connect(_on_health_depleted)
	health_component.health_changed.connect(ui.update_health)

	if not shoot_timer:
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		add_child(shoot_timer)
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func set_fire_type(type: FireType) -> void:
	fire_type = type
	configure_fire_type()

func configure_fire_type() -> void:
	match fire_type:
		FireType.SINGLE: fire_rate = 0.2
		FireType.DOUBLE: fire_rate = 0.3
		FireType.TRIPLE: fire_rate = 0.4
		FireType.QUAD: fire_rate = 0.5
		FireType.SINE: fire_rate = 0.25
		FireType.ORBIT:
			fire_rate = 0.15
			clear_orbit_projectiles()

func _process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
		var knockback_velocity = knockback_direction * knockback_force
		position += knockback_velocity * delta
	else:
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction * speed
		move_and_slide()

	position = position.clamp(Vector2.ZERO, screen_size)

	# Timer da animação de tiro
	if is_shooting:
		shooting_timer -= delta
		if shooting_timer <= 0:
			is_shooting = false

	# Só anima se não estiver atirando
	if not is_shooting:
		animate_movement()

	handle_fire_mode_selection()

	if Input.is_action_pressed("ui_accept") and can_shoot:
		shoot()

	if fire_type == FireType.ORBIT and !orbit_projectiles.is_empty():
		update_orbit_projectiles(delta)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func animate_idle() -> void:
	match last_dir:
		PlayerDir.LEFT:
			animated.play("idle-left")
		PlayerDir.RIGHT:
			animated.play("idle-right")
		PlayerDir.UP:
			animated.play("idle-up")
		PlayerDir.DOWN:
			animated.play("idle-down")

func animate_movement() -> void:
	if Input.is_action_pressed("ui_left"):
		animated.play("walk-left")
		last_dir = PlayerDir.LEFT
	elif Input.is_action_pressed("ui_right"):
		animated.play("walk-right")
		last_dir = PlayerDir.RIGHT
	elif Input.is_action_pressed("ui_up"):
		animated.play("walk-up")
		last_dir = PlayerDir.UP
	elif Input.is_action_pressed("ui_down"):
		animated.play("walk-down")
		last_dir = PlayerDir.DOWN
	else:
		animate_idle()

func handle_fire_mode_selection() -> void:
	if Input.is_action_just_pressed("select-1"):
		set_fire_type(FireType.SINGLE)
	if Input.is_action_just_pressed("select-2"):
		set_fire_type(FireType.DOUBLE)
	if Input.is_action_just_pressed("select-3"):
		set_fire_type(FireType.TRIPLE)
	if Input.is_action_just_pressed("select-4"):
		set_fire_type(FireType.QUAD)
	if Input.is_action_just_pressed("select-5"):
		set_fire_type(FireType.SINE)
	if Input.is_action_just_pressed("select-6"):
		set_fire_type(FireType.ORBIT)

func shoot() -> void:
	match fire_type:
		FireType.SINGLE:
			fire_projectile()
		FireType.DOUBLE:
			fire_projectile(Vector2(0, -15))
			fire_projectile(Vector2(0, 15))
		FireType.TRIPLE:
			fire_projectile()
			fire_projectile(Vector2(-20, 0), deg_to_rad(-15))
			fire_projectile(Vector2(20, 0), deg_to_rad(15))
		FireType.QUAD:
			fire_projectile(Vector2(0, -20), deg_to_rad(0))
			fire_projectile(Vector2(20, 0), deg_to_rad(90))
			fire_projectile(Vector2(0, 20), deg_to_rad(180))
			fire_projectile(Vector2(-20, 0), deg_to_rad(270))
		FireType.SINE:
			fire_projectile(Vector2.ZERO, 0, true)
		FireType.ORBIT:
			var proj = fire_projectile(Vector2.ZERO, 0, false, true)
			if proj:
				orbit_projectiles.append(proj)

	# Ativa animação de tiro conforme direção
	match last_dir:
		PlayerDir.LEFT:
			animated.play("shoot-left")
		PlayerDir.RIGHT:
			animated.play("shoot-right")
		PlayerDir.UP:
			animated.play("shoot-up")
		PlayerDir.DOWN:
			animated.play("shoot-down") # opcional

	is_shooting = true
	shooting_timer = SHOOT_ANIM_DURATION

	can_shoot = false
	shoot_timer.start()

func fire_projectile(offset: Vector2 = Vector2.ZERO,
					 angle_offset: float = 0.0,
					 is_sine: bool = false,
					 is_orbit: bool = false) -> Node2D:
	var projectile = projectile_scene.instantiate()
	
	projectile.set_meta("is_enemy_projectile", false)
	projectile.set_meta("shooter", self)

	# Offset dinâmico baseado na direção do tiro
	var base_offset := Vector2.ZERO
	match last_dir:
		PlayerDir.RIGHT:
			base_offset = Vector2(40, 20)
		PlayerDir.LEFT:
			base_offset = Vector2(-30, 25)
		PlayerDir.UP:
			base_offset = Vector2(0, -15)
		PlayerDir.DOWN:
			base_offset = Vector2(10, 50)


	# Posição final de spawn do projétil
	var spawn_pos = global_position + base_offset + offset
	projectile.global_position = spawn_pos

	# Direção e velocidade do projétil
	var direction_angle = get_shoot_direction_angle() + angle_offset
	var direction = Vector2(cos(direction_angle), sin(direction_angle)).normalized()
	projectile.direction = direction
	projectile.set_meta("direction", direction)
	projectile.speed = projectile_speed

	# Rotaciona o sprite do projétil (caso exista)
	if projectile.has_node("AnimatedSprite2D"):
		var sprite = projectile.get_node("AnimatedSprite2D")
		sprite.rotation = direction.angle()

	# Configurações para modos especiais de tiro
	if is_sine:
		projectile.set_meta("is_sine", true)
		projectile.set_meta("sine_amplitude", sine_amplitude)
		projectile.set_meta("sine_frequency", sine_frequency)
		projectile.set_meta("initial_angle", direction_angle)
		projectile.set_meta("timeout", 10)

	if is_orbit:
		projectile.set_meta("is_orbit", true)
		projectile.speed = 0
		projectile.set_meta("orbit_angle", orbit_angle)
		projectile.set_meta("timeout", 10)

	main.add_child(projectile)
	return projectile

func get_shoot_direction_angle() -> float:
	match last_dir:
		PlayerDir.RIGHT: return 0.0
		PlayerDir.UP: return -PI / 2
		PlayerDir.LEFT: return PI
		PlayerDir.DOWN: return PI / 2
	return 0.0

func update_orbit_projectiles(delta: float) -> void:
	orbit_angle += orbit_speed * delta
	for proj in orbit_projectiles:
		if is_instance_valid(proj):
			var angle = proj.get_meta("orbit_angle") + orbit_speed * delta
			proj.set_meta("orbit_angle", angle)
			var orbit_pos = Vector2(cos(angle), sin(angle)) * orbit_radius
			proj.global_position = global_position + orbit_pos
		else:
			orbit_projectiles.erase(proj)

func clear_orbit_projectiles() -> void:
	for proj in orbit_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	orbit_projectiles.clear()

func _on_health_changed(old_value: int, new_value: int) -> void:
	if health_component:
		health_component.take_damage(old_value - new_value)

		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE
	else:
		printerr("Cannot take damage, HealthComponent is missing!")

func _on_health_depleted() -> void:
	queue_free()
	print("GAME-OVER")
	get_tree().reload_current_scene()

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)

		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE
	else:
		printerr("Cannot take damage, HealthComponent is missing!")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		knockback_direction = (global_position - body.global_position).normalized()
		knockback_timer = knockback_duration
