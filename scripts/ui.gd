extends Control

@onready var health_bar = $HealthBar
@onready var points_label = $Points/Label
var fire_mode_labels = []

func _ready() -> void:
	$Modes/FireModes.pivot_offset = -get_viewport_rect().size / 2
	fire_mode_labels = $Modes/FireModes.get_children()
	

	var player = get_tree().get_root().get_node("main/player")
	call_deferred("set_up_health_bar", player)

func set_up_health_bar(player: CharacterBody2D) -> void:
	player.health_component.health_changed.connect(_on_player_health_changed)
	health_bar.max_value = player.health_component.max_health
	health_bar.value = player.health_component.current_health

func update_health(old_value: int, new_value: int) -> void:
	pass

func update_points(old_value: int, new_value: int) -> void:
	points_label.text = str(new_value)

func update_fire_mode_display(selected_index: int) -> void:
	for i in fire_mode_labels.size():
		$Modes/FireModes.get_child(i).modulate = Color.WHITE
	fire_mode_labels[selected_index].modulate = Color.RED
	#fire_mode_labels[selected_index].modulate(Color8(255,0,0,255))

func _on_player_health_changed(old_value: int, new_value: int) -> void:
	health_bar.value = new_value
