extends Node

signal dialogue_started(title, text, choices, pos)
signal dialogue_ended
signal choice_made(choice_index)

var dialogue_ui: Control = null

func _ready() -> void:
	await get_tree().process_frame
	dialogue_ui = get_tree().get_root().find_child("DialogueUI", true, false)

func show_dialogue(title: String, text: String, pos: Vector2, choices: Array = []) -> void:
	if dialogue_ui:
		dialogue_ui.show_dialogue(title, text, pos, choices)
	emit_signal("dialogue_started", title, text, choices)

func hide_dialogue() -> void:
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	emit_signal("dialogue_ended")
	
func make_choice(choice_index: int) -> void:
	emit_signal("choice_made", choice_index)
	if dialogue_ui:
		dialogue_ui.on_choice_made(choice_index)
