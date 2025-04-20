extends Node

@export var enemy_scene: PackedScene

func _ready():
	spawn_enemies_at_paths()

func spawn_enemies_at_paths() -> void:
	var paths = get_tree().get_nodes_in_group("enemy_paths")
	for path in paths:
		if path is Path2D and path.get_script() != null:
			spawn_enemy_at_path(path)

func spawn_enemy_at_path(path: Path2D) -> void:
	if not enemy_scene:
		printerr("Enemy scene not assigned in Main script!")
		return
	var enemy = enemy_scene.instantiate()
	
	if enemy.has("path_node"):
		enemy.path_node = get_path_to(path)
	
	var player = get_node_or_null("player")
	if player and enemy.has("player_node"):
		enemy.player_node = get_path_to(player)
		
	add_child(enemy)
	
	if path.curve and path.curve.get_point_count() > 0:
		enemy.global_position = path.to_global(path.curve.get_point_position(0))
		
	if enemy.has_method("configure_from_path"):
		enemy.configure_from_path(path)
		
	print("Enemy spawned at path: ", path.name)

func create_enemy_at_path(path_node_path: NodePath) -> void:
	var path = get_node_or_null(path_node_path)
	if path and path is Path2D:
		spawn_enemy_at_path(path)
	else:
		printerr("Invalid path node: ", path_node_path)
