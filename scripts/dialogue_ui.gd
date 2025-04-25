extends Control

@onready var title_label = $Panel/TitleLabel
@onready var text_label = $Panel/TextLabel
@onready var panel = $Panel

func _ready() -> void:
	hide_dialog()
	print("Dialogue UI is ready")

func show_dialog(title: String, text: String) -> void:
	title_label.text = title
	text_label.text = text
	panel.visible = true
	
	panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
	print("Showing dialogue with title: ", title, " and text: ", text)

func hide_dialog() -> void:
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): panel.visible = false)
	print("Hiding dialogue")
