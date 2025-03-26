# Player.gd
extends Area2D

@export var speed = 200
@export var fire_rate = 0.2  # Shots per second
@onready var main = get_tree().get_root().get_node("main")
@onready var projectile_scene = preload("res://projectile.tscn")
@onready var shoot_timer = $ShootTimer  # Add a Timer node named "ShootTimer" in the editor

var screen_size
var can_shoot = true

func _ready() -> void:
	screen_size = get_viewport_rect().size
	# Set up the shoot timer
	if not shoot_timer:
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		add_child(shoot_timer)
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func _process(delta: float) -> void:
	# Movement
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	
	# Rotate towards mouse
	look_at(get_global_mouse_position())
	
	# Handle movement
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# Shooting
	if Input.is_action_pressed("attack") and can_shoot:
		shoot()

func shoot() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.global_rotation = global_rotation
	main.add_child(projectile)
	
	# Start cooldown
	can_shoot = false
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
