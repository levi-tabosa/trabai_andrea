extends Node

signal dialog_started(title, text)
signal dialog_ended

var dialogue_ui: Control = null

func _ready() -> void:
	await get_tree().process_frame
	dialogue_ui = get_tree().get_root().find_child("DialogUI", true, false)

func show_dialogue(title: String, text: String) -> void:
	if dialogue_ui:
		dialogue_ui.show_dialogue(title, text)
	emit_signal("dialog_started", title, text)

func hide_dialogue() -> void:
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	emit_signal("dialog_ended")
