extends Area2D

var screen_size: Vector2
var can_shoot = true

enum FireType {
	SINGLE,    # Default straight shot
	DOUBLE,    # Two parallel shots
	TRIPLE,    # Three-way spread
	QUAD,      # Four directional
	SINE,      # Wavy projectile pattern
	ORBIT      # Rotating orbiting shots
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
@export var knockback_force := 300.0
@export var knockback_duration := 0.2
#@export var blink_animation_player: AnimationPlayer

@onready var main = get_tree().get_root().get_node("main") 
@onready var ui = get_node("/root/main/UI")
@onready var projectile_scene = preload("res://scenes/projectile.tscn")
@onready var shoot_timer = $ShootTimer
@onready var animated = $AnimatedSprite2D

var knockback_timer := 0.0
var knockback_direction := Vector2.ZERO
enum PlayerDir { RIGHT, UP, LEFT, DOWN }
var last_dir := PlayerDir.RIGHT
var orbit_angle := 0.0
var orbit_projectiles := []

func _ready() -> void:
	screen_size = get_viewport_rect().size
	configure_fire_type()

	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = 100
		add_child(health_component)

	health_component.health_depleted.connect(_on_health_depleted)
	health_component.health_changed.connect(ui.update_health)  # Conexão do sinal

	# Força um intervalo de tempo entre disparos
	if not shoot_timer:
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		add_child(shoot_timer)
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func set_fire_type(type:FireType) -> void:
	fire_type = type
	configure_fire_type()

func configure_fire_type() -> void:
	match fire_type:
		FireType.SINGLE:
			fire_rate = 0.2
		FireType.DOUBLE:
			fire_rate = 0.3
		FireType.TRIPLE:
			fire_rate = 0.4
		FireType.QUAD:
			fire_rate = 0.5
		FireType.SINE:
			fire_rate = 0.25
		FireType.ORBIT:
			fire_rate = 0.15
			# Limpa os projéteis ao setar modo orbit
			clear_orbit_projectiles()

func _process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
		var knockback_velocity = knockback_direction * knockback_force
		position += knockback_velocity * delta
	else:
		# Example movement code (replace with yours)
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		position += direction * speed * delta
	
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)
	
	animate_movement()
	handle_fire_mode_selection()
	
	if Input.is_action_pressed("ui_accept") and can_shoot:
		shoot()
	
	# Lida com o comportamento dos projéteis no modo orbita
	if fire_type == FireType.ORBIT && !orbit_projectiles.is_empty():
		update_orbit_projectiles(delta)
	
	position = position.clamp(Vector2.ZERO, screen_size)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func animate_idle() -> void:
	match last_dir:
		PlayerDir.RIGHT:
			animated.play("idle-right")
		PlayerDir.LEFT:
			animated.play("idle-left")
		PlayerDir.UP:
			animated.play("idle-up")
		PlayerDir.DOWN:
			animated.play("idle-down")

func handle_fire_mode_selection() -> void:
	if Input.is_action_just_pressed("select-1"):
		set_fire_type(FireType.TRIPLE)
	if Input.is_action_just_pressed("select-2"):
		set_fire_type(FireType.ORBIT)
	if Input.is_action_just_pressed("select-3"):
		set_fire_type(FireType.DOUBLE)

func animate_movement() -> void:
	if Input.is_action_pressed("ui_left"):
		animated.play("walk-left")
		last_dir = PlayerDir.LEFT
	elif Input.is_action_pressed("ui_right"):
		animated.play("walk-right")
		last_dir = PlayerDir.RIGHT 
	if Input.is_action_pressed("ui_up"):
		animated.play("walk-up")
		last_dir = PlayerDir.UP
	elif Input.is_action_pressed("ui_down"):
		animated.play("walk-down")
		last_dir = PlayerDir.DOWN
		
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
	
	#Animação do tiro
	match last_dir:
		PlayerDir.LEFT:
			animated.play("shoot-left")
		PlayerDir.RIGHT:
			animated.play("shoot-right")
		PlayerDir.UP:
			animated.play("shoot-up") #TODO: ADICIONAR ESSA ANIMAÇÃO
		PlayerDir.DOWN:
			animated.play("shoot-down") #TODO: ADICIONAR ESSA ANIMAÇÃO
	
	can_shoot = false
	shoot_timer.start()

func fire_projectile(offset: Vector2 = Vector2.ZERO, 
				   angle_offset: float = 0.0, 
				   is_sine: bool = false,
				   is_orbit: bool = false) -> Node2D:
	var projectile = projectile_scene.instantiate()
	
	# Posição
	var spawn_pos = global_position + offset.rotated(get_shoot_direction_angle())
	projectile.global_position = spawn_pos
	
	# Direção e Velocidade
	var direction_angle = get_shoot_direction_angle() + angle_offset
	projectile.direction = Vector2(cos(direction_angle), sin(direction_angle))
	projectile.speed = projectile_speed
	
	# Configura tipos especiais
	if is_sine:
		projectile.set_meta("is_sine", true)
		projectile.set_meta("sine_amplitude", sine_amplitude)
		projectile.set_meta("sine_frequency", sine_frequency)
		projectile.set_meta("initial_angle", direction_angle)
		projectile.set_meta("timeout", 10)
	
	if is_orbit:
		projectile.set_meta("is_orbit", true)
		projectile.speed = 0  # Player controla o movimento
		projectile.set_meta("orbit_angle", orbit_angle)
		orbit_angle += PI/4  # Espaço entre projéteis
		projectile.set_meta("timeout", 10)
	
	main.add_child(projectile)
	return projectile

## Retorna um ângulo em radiano correspondente a ultima tecla de movimentação apertada
## Usado para direcionar o tiro
func get_shoot_direction_angle() -> float:
	match last_dir:
		PlayerDir.RIGHT: return 0.0
		PlayerDir.UP: return -PI/2
		PlayerDir.LEFT: return PI
		PlayerDir.DOWN: return PI/2
	return 0.0

## Funcão auxiliar, gerencia e atualiza os projéteis orbitando
func update_orbit_projectiles(delta: float) -> void:
	orbit_angle += orbit_speed * delta
	
	for proj in orbit_projectiles:
		if is_instance_valid(proj):
			# Atualiza metadados
			var angle = proj.get_meta("orbit_angle") + orbit_speed * delta
			proj.set_meta("orbit_angle", angle)
			
			# Posição
			var orbit_pos = Vector2(cos(angle), sin(angle)) * orbit_radius
			proj.global_position = global_position + orbit_pos
		else:
			# Remove os objetos invalidados por timeout ou colisão 
			orbit_projectiles.erase(proj)

## Esse metodo limpa os projéteis após modificar o fire_type
func clear_orbit_projectiles() -> void:
	for proj in orbit_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	orbit_projectiles.clear()
	
func _on_health_changed(old_value: int, new_value: int) -> void:
	pass

# TODO: Tela de Game-Over
func _on_health_depleted() -> void:
	queue_free()
	print("GAME-OVER")
	get_tree().reload_current_scene() 

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		print(health_component.current_health)
		health_component.take_damage(5)
		knockback_direction = (global_position - body.global_position).normalized()
		knockback_timer = knockback_duration
