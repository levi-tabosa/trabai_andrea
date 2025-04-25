extends Area2D

@export_multiline var dialog_text = "Hello! This is a dialog message that appears when you enter this area."
@export var dialog_title = "NPC"

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		print(1)
		DialogueManager.show_dialogue(dialog_title, dialog_text)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "player":
		DialogueManager.hide_dialogue()
