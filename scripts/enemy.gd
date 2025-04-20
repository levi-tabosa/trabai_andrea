extends CharacterBody2D

class_name Enemy

@export var speed := 100.0
@export var chase_distance := 100.0
@export var path_node: NodePath  # Path to the Path2D node for patrolling
@export var player_node: NodePath
@export var health_component: HealthComponent
@export var score_value := 10
@export var patrol_loops := 0
# Shooting parameters
@export var can_shoot := true
@export var fire_rate := 1.0  # Slower than player by default
@export var projectile_speed := 150.0  # Slower than player
@export var shooting_range := 150.0  # Enemy will shoot when player is within this range
@export var mov_state := MOB_BEHAVIOR.PATROLLING
@export var fire_state:= FIRE_BEHAVIOR.ON_CHASE

var path_points: Array[Vector2] = []
var current_point_index := 0
var player: Node2D = null 
var loops_completed := 0
var force_chase_after_loops := false 
# Shooting variables
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
	add_to_group("mobs") # Good practice

	# --- Health Component Setup ---
	if not health_component:
		print("HealthComponent not assigned in editor, creating default.")
		health_component = HealthComponent.new()
		health_component.max_health = 50
		add_child(health_component)

	if health_component:
		if not health_component.health_depleted.is_connected(_on_death):
			health_component.health_depleted.connect(_on_death)
	else:
		printerr("Enemy requires a HealthComponent!")


	player = get_tree().get_root().get_node("main").get_node("player")
	if not player:
		return

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
					print("Path points loaded: ", path_points.size())
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

	if path_points.size() == 0:
		printerr("No path points loaded. Enemy will not patrol.")
		
	if patrol_loops == 0:
		force_chase_after_loops = true
	elif patrol_loops < 0:
		patrol_loops = 0xFFFF_FFFF

	projectile_scene = preload("res://scenes/projectile.tscn")
	if not projectile_scene:
		printerr("Failed to load projectile scene. Enemy won't be able to shoot.")
	
	# Create shoot timer
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.wait_time = fire_rate
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)
	add_child(shoot_timer)

# New method to receive configuration from a Path2D node
func configure_from_path(path_node: Node) -> void:
	if path_node.has_method("get_script") and path_node.get_script() != null:
		if path_node.get("enemy_speed") != null:
			speed = path_node.enemy_speed
			
		if path_node.get("enemy_chase_distance") != null:
			chase_distance = path_node.enemy_chase_distance
			
		if path_node.get("enemy_patrol_loops") != null:
			patrol_loops = path_node.enemy_patrol_loops
			
		if path_node.get("enemy_fire_rate") != null:
			fire_rate = path_node.enemy_fire_rate
			if shoot_timer:
				shoot_timer.wait_time = fire_rate
				
		if path_node.get("enemy_projectile_speed") != null:
			projectile_speed = path_node.enemy_projectile_speed
			
		if path_node.get("enemy_shooting_range") != null:
			shooting_range = path_node.enemy_shooting_range
			
		print("Enemy configured from path: ", path_node.name)

func _physics_process(delta: float) -> void:
	if not player or (mov_state == MOB_BEHAVIOR.PATROLLING and path_points.size() == 0):
		velocity = Vector2.ZERO
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

			if global_position.distance_to(target_point) < 5.0: # Use a small threshold
				current_point_index = (current_point_index + 1) % path_points.size()
				
				if current_point_index == 0:
					loops_completed += 1
					print("Enemy completed loop: ", loops_completed, " of ", patrol_loops)
					
					if loops_completed >= patrol_loops:
						force_chase_after_loops = true
						mov_state = MOB_BEHAVIOR.CHASING
						print("All patrol loops completed, switching to chase mode permanently")
		else:
			velocity = Vector2.ZERO

	elif mov_state == MOB_BEHAVIOR.CHASING:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

	move_and_slide()
	
	match fire_state:
		FIRE_BEHAVIOR.ON_CHASE:
			if can_shoot and distance_to_player <= shooting_range and mov_state == MOB_BEHAVIOR.CHASING:
				shoot()
		FIRE_BEHAVIOR.IN_RANGE:
			if can_shoot and distance_to_player <= shooting_range:
				shoot()

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
	#get_tree().call_group("game_manager", "increase_score", score_value)
	print("Enemy died!")
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
	
	# If projectile has AnimatedSprite2D, rotate it to face direction
	if projectile.has_node("AnimatedSprite2D"):
		var sprite = projectile.get_node("AnimatedSprite2D")
		sprite.rotation = direction.angle()
		
		# If there's an animation manager, play enemy projectile animation
		if sprite.has_method("play"):
			sprite.play("enemy_projectile")
	
	get_tree().get_root().get_node("main").add_child(projectile)
	
	can_shoot = false
	shoot_timer.start()
