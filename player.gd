extends Area2D

@export var speed = 200
@export var fire_rate = 0.2  # Tempo entre os disparos
@onready var main = get_tree().get_root().get_node("main")
@onready var projectile_scene = preload("res://projectile.tscn")
@onready var shoot_timer = $ShootTimer  # Timer para controle de tiro
@onready var animated = $AnimatedSprite2D  # Controle de animação

var screen_size
var can_shoot = true
var last_direction = "right"  # Guarda a última direção que o player olhou

func _ready() -> void:
	screen_size = get_viewport_rect().size

	# Configuração do timer de disparo
	if not shoot_timer:
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		add_child(shoot_timer)
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func _process(delta: float) -> void:
	# Movimento do player
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		animated.play("walk-left")
		last_direction = "left"
	elif Input.is_action_pressed("ui_right"):
		velocity.x += 1
		animated.play("walk-right")
		last_direction = "right"

	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		animated.play("walk-up")
	elif Input.is_action_pressed("ui_down"):
		velocity.y += 1
		animated.play("walk-down")

	# Normaliza a velocidade para evitar movimento mais rápido na diagonal
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# Restrição de rotação: Apenas vira para a esquerda ou direita
	var mouse_position = get_global_mouse_position()
	if mouse_position.x < global_position.x:
		last_direction = "left"
		animated.flip_h = true  # Espelha o sprite para olhar à esquerda
	else:
		last_direction = "right"
		animated.flip_h = false  # Mantém o sprite normal para olhar à direita
	
	# Disparo
	if Input.is_action_pressed("attack") and can_shoot:
		shoot()

func shoot() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.global_rotation = 0  # Mantém o projétil reto
	main.add_child(projectile)

	# Define a animação do tiro com base na última direção do jogador
	if last_direction == "left":
		animated.play("shoot-left")
		animated.flip_h = true
	elif last_direction == "right":
		animated.play("shoot-right")
		animated.flip_h = false

	# Inicia o cooldown do disparo
	can_shoot = false
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
