extends Control

@onready var health_label = $HP/Label
@onready var points_label = $Points/Label

##TODO: old value usado para efeitos com base se houve um ganho ou perda
func update_health(old_value: int, new_value: int) -> void:
	health_label.text = str(new_value)

func update_points(old_value: int, new_value: int) -> void:
	points_label.text = str(new_value)
