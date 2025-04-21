extends Area2D

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		print("Player entered transition area!")
		get_tree().change_scene_to_file("res://scenes/level_2.tscn")
