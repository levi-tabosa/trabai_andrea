extends CharacterBody2D

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

var path_points: Array[Vector2] = []
var current_point_index := 0
var state := MOB_BEHAVIOR.PATROLLING
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

func _ready() -> void:
	add_to_group("mobs") # Good practice

	# --- Health Component Setup ---
	if not health_component:
		print("HealthComponent not assigned in editor, creating default.")
		health_component = HealthComponent.new()
		health_component.max_health = 50
		add_child(health_component) # Add the created component as a child

	# Ensure connection only happens if health_component is valid
	if health_component:
		# Check if already connected to prevent duplicate connections if _ready is called multiple times (unlikely but safe)
		if not health_component.health_depleted.is_connected(_on_death):
			health_component.health_depleted.connect(_on_death)
	else:
		printerr("Enemy requires a HealthComponent!") # Print an error if still no component

	# --- Player Node Setup ---
	if player_node: # Check if the NodePath is assigned
		player = get_node_or_null(player_node) # Use get_node_or_null for safety
	else:
		player = get_tree().get_root().get_node("main").get_node("player")
		print(player)

	if not player:
		printerr("Player node not found or not assigned! Check 'player_node' export variable in the inspector. Path was: ", player_node)
		# Optionally, disable the enemy or stop processing if player is essential
		# set_physics_process(false)
		# return # Exit _ready early if no player

	# --- Path Node Setup ---
	if path_node: # Check if the NodePath is assigned
		var path = get_node_or_null(path_node) # Use get_node_or_null
		if path and path is Path2D:
			if path.curve and path.curve.get_point_count() > 0:
				var local_points = path.curve.get_baked_points()
				if local_points: # Check if baking points worked
					print(local_points)
					for local_point in local_points:
						# Convert point from Path2D's local space to global world space
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

	# Check if path points were successfully loaded
	if path_points.size() == 0:
		printerr("No path points loaded. Enemy will not patrol.")
		
	# Ensure patrol_loops is at least 1
	if patrol_loops < 1:
		force_chase_after_loops = true
		#patrol_loops = 9223372036854775807 #i64 max
		print("Patrol loops set to minimum value of 1")
	
	# --- Shooting Setup ---
	# Load projectile scene
	projectile_scene = preload("res://scenes/projectile.tscn")
	if not projectile_scene:
		printerr("Failed to load projectile scene. Enemy won't be able to shoot.")
	
	# Create shoot timer
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.wait_time = fire_rate
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)
	add_child(shoot_timer)


func _physics_process(delta: float) -> void:
	if not player or (state == MOB_BEHAVIOR.PATROLLING and path_points.size() == 0):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	# --- State Logic ---
	if distance_to_player < chase_distance or force_chase_after_loops:
		state = MOB_BEHAVIOR.CHASING
	elif state == MOB_BEHAVIOR.CHASING and distance_to_player > chase_distance + 20 and not force_chase_after_loops:
		if path_points.size() > 0:
			state = MOB_BEHAVIOR.PATROLLING
			current_point_index = find_closest_path_point()

	# --- Movement Logic ---
	if state == MOB_BEHAVIOR.PATROLLING:
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
						state = MOB_BEHAVIOR.CHASING
						print("All patrol loops completed, switching to chase mode permanently")
		else:
			velocity = Vector2.ZERO

	elif state == MOB_BEHAVIOR.CHASING:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

	move_and_slide()
	
	# --- Shooting Logic ---
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
	# Add score or other death effects here if needed *before* queue_free
	# Example: get_tree().call_group("game_manager", "increase_score", score_value)
	print("Enemy died!")
	queue_free()
	
# --- Shooting Functions ---
func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func shoot() -> void:
	if not projectile_scene:
		return
		
	# Create the projectile
	var projectile = projectile_scene.instantiate()
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
	# Position the projectile in front of the enemy
	var spawn_position = global_position + direction * 30
	projectile.global_position = spawn_position
	
	# Set direction and speed
	projectile.direction = direction
	projectile.set_meta("direction", direction)
	projectile.speed = projectile_speed
	
	# Make sure it's an enemy projectile
	projectile.set_meta("is_enemy_projectile", true)
	
	# Store reference to the shooter (THIS IS THE KEY FIX!)
	projectile.set_meta("shooter", self)
	
	# If projectile has AnimatedSprite2D, rotate it to face direction
	if projectile.has_node("AnimatedSprite2D"):
		var sprite = projectile.get_node("AnimatedSprite2D")
		sprite.rotation = direction.angle()
		
		# If there's an animation manager, play enemy projectile animation
		if sprite.has_method("play"):
			sprite.play("enemy_projectile")
	
	# Add the projectile to the scene
	get_tree().get_root().get_node("main").add_child(projectile)
	
	# Start cooldown
	can_shoot = false
	shoot_timer.start()
