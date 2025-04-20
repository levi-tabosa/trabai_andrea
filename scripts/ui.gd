extends Control

@onready var health_bar = $HealthBar
@onready var points_label = $Points/Label
var fire_mode_labels = []

func _ready() -> void:
	fire_mode_labels = $FireModes.get_children()
	assert(fire_mode_labels.size() == 7, "Expected 7 fire mode labels, got %d" % fire_mode_labels.size())

	var player = get_tree().get_root().get_node("main/player")
	player.print_tree_pretty()

	call_deferred("set_up_health_bar", player)

func set_up_health_bar(player: CharacterBody2D) -> void:
	print("Setting up health bar", player, player.health_component)
	player.health_component.health_changed.connect(_on_player_health_changed)
	health_bar.max_value = player.health_component.max_health
	health_bar.value = player.health_component.current_health

func update_health(old_value: int, new_value: int) -> void:
	pass

func update_points(old_value: int, new_value: int) -> void:
	points_label.text = str(new_value)

func update_fire_mode_display(selected_index: int) -> void:
	for label in fire_mode_labels:
		label.set("custom_colors/font_color", Color.WHITE)
	fire_mode_labels[selected_index].set("custom_colors/font_color", Color.YELLOW)
	print(selected_index)

func _on_player_health_changed(old_value: int, new_value: int) -> void:
	health_bar.value = new_value
