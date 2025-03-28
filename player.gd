extends Area2D

@export var speed = 200
@export var fire_rate = 0.2  # DEFAULT
@onready var main = get_tree().get_root()
@onready var projectile_scene = preload("res://projectile.tscn")
@onready var shoot_timer = $ShootTimer  # Timer para controle de tiro
@onready var animated = $AnimatedSprite2D  # Controle de animação

var screen_size: Vector2
var can_shoot = true

enum WeaponType {
	SINGLE, # DEFAULT
	DOUBLE,
}
@export var weapon_type = WeaponType.SINGLE

enum PlayerDir { RIGHT, DOWN, LEFT, UP }
var last_dir = PlayerDir.RIGHT # Guarda a última direção que o player olhou

func _ready() -> void:
	screen_size = get_viewport_rect().size
	if weapon_type == WeaponType.DOUBLE:
		fire_rate = 1.0
	# Configuração do timer de disparo
	if not shoot_timer:
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		add_child(shoot_timer)
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func _process(delta: float) -> void:
	# Anima o idle
	animate_idle()
	# Movimento do player
	handle_movement_and_animate(delta)
	
	# Disparo
	if Input.is_action_pressed("ui_accept" ) and can_shoot:
		shoot()

	position = position.clamp(Vector2.ZERO, screen_size)
	
func shoot() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.global_rotation = PI / 2 * last_dir # ENUM como int
	# Define a animação com base na última direção do jogador
	if last_dir == PlayerDir.LEFT:
		animated.play("shoot-left")
	elif last_dir == PlayerDir.RIGHT:
		animated.play("shoot-right")
	elif last_dir == PlayerDir.UP:
		animated.play("idle_up") #ADICIONAR SPRITE
	else :
		animated.play("idle_down") #ADICIOINAR SPRITE
	main.add_child(projectile)
	# Inicia o cooldown do disparo
	can_shoot = false
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func animate_idle() -> void:
	if last_dir == PlayerDir.RIGHT :
		animated.play("idle-right")
	elif last_dir == PlayerDir.LEFT:
		animated.play("idle-left")
	elif last_dir == PlayerDir.UP:
		animated.play("idle_up")
	else:
		animated.play("idle-down")

func handle_movement_and_animate(delta: float) -> void:
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		animated.play("walk-left")
		last_dir = PlayerDir.LEFT
		
	elif Input.is_action_pressed("ui_right"):
		velocity.x += 1
		animated.play("walk-right")
		last_dir = PlayerDir.RIGHT 
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		animated.play("walk-up")
		last_dir = PlayerDir.UP
		
	elif Input.is_action_pressed("ui_down"):
		velocity.y += 1
		animated.play("walk-down")
		last_dir = PlayerDir.DOWN
		
	# Normaliza a velocidade para evitar movimento mais rápido na diagonal
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	position += velocity * delta
