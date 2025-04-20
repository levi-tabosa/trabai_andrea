extends Node

# Enemy scene reference
@export var enemy_scene: PackedScene

# Called when the node enters the scene tree for the first time
func _ready():
	# Optional: You can automatically spawn enemies at paths when the scene starts
	spawn_enemies_at_paths()

# Function to spawn enemies at all Path2D nodes with the correct script
func spawn_enemies_at_paths() -> void:
	var paths = get_tree().get_nodes_in_group("enemy_paths")
	for path in paths:
		if path is Path2D and path.get_script() != null:
			spawn_enemy_at_path(path)

# Function to spawn a single enemy at a specific path
func spawn_enemy_at_path(path: Path2D) -> void:
	if not enemy_scene:
		printerr("Enemy scene not assigned in Main script!")
		return
		
	# Create enemy instance
	var enemy = enemy_scene.instantiate()
	
	# Set the path
	if enemy.has("path_node"):
		enemy.path_node = get_path_to(path)
	
	# Set player reference if needed
	var player = get_node_or_null("player")
	if player and enemy.has("player_node"):
		enemy.player_node = get_path_to(player)
		
	# Add to scene
	add_child(enemy)
	
	# Position at start of path
	if path.curve and path.curve.get_point_count() > 0:
		enemy.global_position = path.to_global(path.curve.get_point_position(0))
		
	# Configure from path automatically
	if enemy.has_method("configure_from_path"):
		enemy.configure_from_path(path)
		
	print("Enemy spawned at path: ", path.name)

# This function can be called from editor scripts, signals, or other game logic
func create_enemy_at_path(path_node_path: NodePath) -> void:
	var path = get_node_or_null(path_node_path)
	if path and path is Path2D:
		spawn_enemy_at_path(path)
	else:
		printerr("Invalid path node: ", path_node_path)
