extends Path2D

@export var enemy_speed := 100.0
@export var enemy_chase_distance := 100.0
@export var enemy_fire_rate := 1.0
@export var enemy_projectile_speed := 150.0
@export var enemy_shooting_range := 150.0
@export var enemy_patrol_loops := 2
@export var enemy_mov_state := Enemy.MOB_BEHAVIOR.CHASING
@export var enemy_fire_state := Enemy.FIRE_BEHAVIOR.ON_CHASE

func configure_enemy(enemy: Node) -> void:
	if enemy.has_method("configure_from_path"):
		enemy.configure_from_path(self)
	else:
		push_warning("Enemy doesn't implement configure_from_path method")
