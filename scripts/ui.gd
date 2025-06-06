extends Control

@onready var health_bar = $HealthBar
@onready var points_label = $Points/Label
var fire_mode_labels = []

func _ready() -> void:
	$Modes/FireModes.pivot_offset = -get_viewport_rect().size / 2
	$HealthBar.pivot_offset.y = get_viewport_rect().size.y / 10
	fire_mode_labels = $Modes/FireModes.get_children()
	for label in fire_mode_labels:
		label.visible = false
	fire_mode_labels[0].visible = true
		
	var player = get_tree().get_root().get_node("main/Player")
	assert(player != null)
	
	# Garantir que o player foi inicializado antes de conectar o sinal
	call_deferred("set_up_health_bar", player) 

func set_up_health_bar(player: CharacterBody2D) -> void:
	player.health_component.health_changed.connect(_on_player_health_changed)
	health_bar.max_value = player.health_component.max_health
	health_bar.value = player.health_component.current_health

func update_health(old_value: int, new_value: int) -> void:
	pass

#TODO: maybe remove
func update_points(old_value: int, new_value: int) -> void:
	points_label.text = str(new_value)

func update_fire_mode_display(selected_index: int) -> void:
	for i in fire_mode_labels.size():
		$Modes/FireModes.get_child(i).modulate = Color.WHITE
	fire_mode_labels[selected_index].modulate = Color.RED

func _on_player_health_changed(old_value: int, new_value: int) -> void:
	health_bar.value = new_value

func unlock_fire_mode(fire_type: int) -> void:
	fire_mode_labels[fire_type].visible = true
