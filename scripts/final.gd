extends Control


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/cutscene_2.tscn")


func _on_sair_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tela_inicial.tscn")
