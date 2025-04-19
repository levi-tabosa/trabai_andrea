extends CharacterBody2D

# --- Exports ---
@export var speed := 100.0
@export var chase_distance := 100.0
# IMPORTANT: Assign these NodePaths in the Godot Editor Inspector!
@export var path_node: NodePath  # Path to the Path2D node for patrolling
@export var player_node: NodePath # Path to the Player node
@export var health_component: HealthComponent
@export var score_value := 10

# --- OnReady Variables ---
# Removed @onready var main as it wasn't used in this script snippet.
# Add it back if you need it elsewhere.

# --- Internal Variables ---
var path_points: Array[Vector2] = [] # INITIALIZE THE ARRAY!
var current_point_index := 0
var state := "patrolling"
var player: Node2D = null # Initialize to null for clarity

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
		# Decide behavior: Maybe default to chasing? Or stay idle?
		# state = "idle" # Or maybe "chasing" if player exists?


func _physics_process(delta: float) -> void:
	# --- Essential Checks ---
	# If player is missing OR if patrolling but no path points exist, do nothing.
	if not player or (state == "patrolling" and path_points.size() == 0):
		# Optional: Print a warning periodically, but avoid flooding the console
		# print("Enemy cannot process: Player missing or no path points for patrolling.")
		velocity = Vector2.ZERO # Stop moving
		move_and_slide() # Apply zero velocity
		return # Stop further processing in this frame

	# --- State Logic ---
	var distance_to_player = global_position.distance_to(player.global_position)

	# Determine state based on distance
	if distance_to_player < chase_distance:
		state = "chasing"
	elif state == "chasing" and distance_to_player > chase_distance + 20: # Hysteresis (add a buffer)
		# Only switch back to patrolling if there are path points to follow
		if path_points.size() > 0:
			state = "patrolling"
			# Optional: Find the closest path point to resume patrolling smoothly
			# current_point_index = find_closest_path_point()
		else:
			# If no path, maybe go idle or keep chasing? Decide behavior.
			# For now, just stay chasing if no path to return to.
			pass # Keep chasing


	# --- Movement Logic ---
	if state == "patrolling":
		# Move toward the current path point
		if path_points.size() > 0: # Double-check path points exist
			var target_point = path_points[current_point_index]
			var direction = (target_point - global_position).normalized()
			velocity = direction * speed

			# Check if close enough to the target point
			if global_position.distance_to(target_point) < 5.0: # Use a small threshold
				current_point_index = (current_point_index + 1) % path_points.size()
		else:
			# Should not happen due to check at the start, but safety first
			velocity = Vector2.ZERO

	elif state == "chasing":
		# Move toward the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

	# Apply movement
	move_and_slide()

# Helper function to find the closest path point (optional, for smoother patrol resume)
# func find_closest_path_point() -> int:
# 	if path_points.size() == 0:
# 		return 0
# 	var closest_index = 0
# 	var min_dist_sq = -1.0
#
# 	for i in range(path_points.size()):
# 		var dist_sq = global_position.distance_squared_to(path_points[i])
# 		if min_dist_sq < 0 or dist_sq < min_dist_sq:
# 			min_dist_sq = dist_sq
# 			closest_index = i
# 	return closest_index

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)

		# Visual feedback
		modulate = Color.RED # Use Color constant
		# Use await with SceneTreeTimer timeout signal
		await get_tree().create_timer(0.2).timeout
		# Ensure the enemy hasn't been freed in the meantime
		if is_instance_valid(self):
			modulate = Color.WHITE # Use Color constant
	else:
		printerr("Cannot take damage, HealthComponent is missing!")


func _on_death() -> void:
	# Add score or other death effects here if needed *before* queue_free
	# Example: get_tree().call_group("game_manager", "increase_score", score_value)
	print("Enemy died!")
	queue_free() # Remove the enemy from the scene
