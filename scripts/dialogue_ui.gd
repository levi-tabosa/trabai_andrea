extends Control

@onready var title_label = $Panel/TitleLabel
@onready var text_label = $Panel/TextLabel
@onready var panel = $Panel
@onready var choices_container = $Panel/ChoicesContainer

var current_choices = []
var choice_buttons = []

func _ready() -> void:
	hide_dialogue()

func show_dialogue(title: String, text: String, pos: Vector2, choices: Array = []) -> void:
	global_position = pos
	title_label.text = title
	text_label.text = text
	panel.visible = true

	clear_choices()

	current_choices = choices
	if choices.size() > 0:
		create_choice_buttons(choices)
	
	panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

func hide_dialogue() -> void:
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): 
		panel.visible = false
		clear_choices()
	)

func clear_choices() -> void:
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()

func create_choice_buttons(choices: Array) -> void:
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.connect("pressed", func(): on_choice_button_pressed(i))
		
		choices_container.add_child(button)
		choice_buttons.append(button)

func on_choice_button_pressed(index: int) -> void:
	DialogueManager.make_choice(index)

func on_choice_made(choice_index: int) -> void:
	# This can be used to handle UI changes after a choice is made
	pass
