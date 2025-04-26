extends CharacterBody2D

class_name Enemy

@export var speed := 100.0
@export var chase_distance := 100.0
@export var path_node: NodePath
@export var player_node: NodePath
@export var health_component: HealthComponent
@export var score_value := 10
@export var patrol_loops := 0
@export var can_shoot := true
@export var fire_rate := 1.0 
@export var projectile_speed := 150.0 
@export var shooting_range := 150.0 
@export var mov_state := MOB_BEHAVIOR.PATROLLING
@export var fire_state := FIRE_BEHAVIOR.ON_CHASE
@export var has_projectile := false
@onready var animated = $AnimatedSprite2D


var last_direction := Vector2.DOWN
var path_points: Array[Vector2] = []
var current_point_index := 0
var player: Node2D = null 
var loops_completed := 0
var force_chase_after_loops := false 
var shoot_timer: Timer
var projectile_scene: PackedScene

enum MOB_BEHAVIOR {
	CHASING,
	PATROLLING
}

enum FIRE_BEHAVIOR {
	ON_CHASE,
	IN_RANGE,
}

func _ready() -> void:
	add_to_group("mobs")

	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = 50
		add_child(health_component)

	if health_component:
		if not health_component.health_depleted.is_connected(_on_death):
			health_component.health_depleted.connect(_on_death)
	else:
		printerr("Enemy requires a HealthComponent!")

	player = get_tree().get_root().get_node("main").get_node("player")
	assert(player != null)

	if path_node:
		var path = get_node_or_null(path_node)
		if path and path is Path2D:
			if path.get_script() != null:
				configure_from_path(path)

			if path.curve and path.curve.get_point_count() > 0:
				var local_points = path.curve.get_baked_points()
				if local_points:
					for local_point in local_points:
						var global_point = path.to_global(local_point)
						path_points.append(global_point)
				else:
					printerr("Failed to bake points from Path2D curve. Path: ", path_node)
			else:
				printerr("Path2D node found, but its curve has no points. Path: ", path_node)
		elif path:
			printerr("Node found at 'path_node' is not a Path2D! Path: ", path_node)
		else:
			printerr("Path node not found! Check 'path_node' export variable in the inspector. Path was: ", path_node)
	else:
		printerr("'path_node' export variable not assigned in the inspector.")

	if path_points.size() == 0 and mov_state == MOB_BEHAVIOR.CHASING:
		force_chase_after_loops = true
	elif patrol_loops < 0:
		patrol_loops = 0xFFFF_FFFF

	projectile_scene = preload("res://scenes/projectile.tscn")
	if not projectile_scene:
		printerr("Failed to load projectile scene. Enemy won't be able to shoot.")
	
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.wait_time = fire_rate
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)
	add_child(shoot_timer)

func configure_from_path(blz_path_node: Node) -> void:
	if blz_path_node.has_method("get_script") and blz_path_node.get_script() != null:
		if blz_path_node.get("enemy_speed") != null:
			speed = blz_path_node.enemy_speed
		if blz_path_node.get("enemy_chase_distance") != null:
			chase_distance = blz_path_node.enemy_chase_distance
		if blz_path_node.get("enemy_patrol_loops") != null:
			patrol_loops = blz_path_node.enemy_patrol_loops
		if blz_path_node.get("enemy_fire_rate") != null:
			fire_rate = blz_path_node.enemy_fire_rate
			if shoot_timer:
				shoot_timer.wait_time = fire_rate
		if blz_path_node.get("enemy_projectile_speed") != null:
			projectile_speed = blz_path_node.enemy_projectile_speed
		if blz_path_node.get("enemy_shooting_range") != null:
			shooting_range = blz_path_node.enemy_shooting_range
		if blz_path_node.get("enemy_mov_state") != null:
			mov_state = blz_path_node.enemy_mov_state
		if blz_path_node.get("enemy_fire_state") != null:
			fire_state = blz_path_node.enemy_fire_state
		if blz_path_node.get("enemy_scale_factor") != null:
			scale = Vector2(blz_path_node.enemy_scale_factor, blz_path_node.enemy_scale_factor)
		if blz_path_node.get("enemy_sprite_frames") != null:
			animated.sprite_frames = blz_path_node.enemy_sprite_frames
		if blz_path_node.get("enemy_has_projectile") != null:
			has_projectile = blz_path_node.enemy_has_projectile

func _physics_process(delta: float) -> void:
	if not player or (mov_state == MOB_BEHAVIOR.PATROLLING and path_points.size() == 0):
		velocity = Vector2.ZERO
		update_animation()
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player < chase_distance or force_chase_after_loops:
		mov_state = MOB_BEHAVIOR.CHASING
	elif mov_state == MOB_BEHAVIOR.CHASING and distance_to_player > chase_distance + 20 and not force_chase_after_loops:
		if path_points.size() > 0:
			mov_state = MOB_BEHAVIOR.PATROLLING
			current_point_index = find_closest_path_point()

	if mov_state == MOB_BEHAVIOR.PATROLLING:
		if path_points.size() > 0:
			var target_point = path_points[current_point_index]
			var direction = (target_point - global_position).normalized()
			velocity = direction * speed

			if global_position.distance_to(target_point) < 5.0:
				current_point_index = (current_point_index + 1) % path_points.size()
				if current_point_index == 0:
					loops_completed += 1
					
					if loops_completed >= patrol_loops:
						force_chase_after_loops = true
						mov_state = MOB_BEHAVIOR.CHASING
		else:
			velocity = Vector2.ZERO

	elif mov_state == MOB_BEHAVIOR.CHASING:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

	move_and_slide()
	update_animation()
	
	if(not has_projectile): 
		return

	match fire_state:
		FIRE_BEHAVIOR.ON_CHASE:
			if can_shoot and distance_to_player <= shooting_range and mov_state == MOB_BEHAVIOR.CHASING:
				shoot()
		FIRE_BEHAVIOR.IN_RANGE:
			if can_shoot and distance_to_player <= shooting_range:
				shoot()

func update_animation():
	if not animated:
		return

	var dir = velocity.normalized()
	var anim_name = ""

	if dir.length() < 0.1:
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim_name = "idle-right"
			else:
				anim_name = "idle-left"
		else:
			if last_direction.y > 0:
				anim_name = "idle-down"
			else:
				anim_name = "idle-up"
	else:
		last_direction = dir
		if abs(dir.x) > abs(dir.y):
			if dir.x > 0:
				anim_name = "walk-right"
			else:
				anim_name = "walk-left"
		else:
			if dir.y > 0:
				anim_name = "walk-down"
			else:
				anim_name = "walk-up"

	if animated.animation != anim_name:
		animated.play(anim_name)

func find_closest_path_point() -> int:
	if path_points.size() == 0:
		return 0
	var closest_index = 0
	var min_dist_sq = -1.0

	for i in range(path_points.size()):
		var dist_sq = global_position.distance_squared_to(path_points[i])
		if min_dist_sq < 0 or dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_index = i
	return closest_index

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE
	else:
		printerr("Cannot take damage, HealthComponent is missing!")

func _on_death() -> void:
	queue_free()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func shoot() -> void:
	if not projectile_scene:
		return

	var projectile = projectile_scene.instantiate()
	var direction = (player.global_position - global_position).normalized()
	
	var spawn_position = global_position + direction * 30
	projectile.global_position = spawn_position
	
	projectile.direction = direction
	projectile.set_meta("direction", direction)
	projectile.speed = projectile_speed
	
	projectile.set_meta("is_enemy_projectile", true)
	projectile.set_meta("shooter", self)
	
	if projectile.has_node("AnimatedSprite2D"):
		var sprite = projectile.get_node("AnimatedSprite2D")
		sprite.rotation = direction.angle()
		sprite.modulate = Color(1, 0.2, 0.2)
		if sprite.has_method("play"):
			sprite.play("enemy_projectile")
	
	get_tree().get_root().get_node("main").add_child(projectile)
	
	can_shoot = false
	shoot_timer.start()
