extends Control

@onready var control = $UIControl
@onready var title_label = $UIControl/MainLayout/TitleLabel
@onready var text_label = $UIControl/MainLayout/TextLabel
@onready var layout = $UIControl/MainLayout
@onready var panel = $UIControl/Panel
@onready var choices_container = $UIControl/MainLayout/ChoicesContainer

var current_choices = []
var choice_buttons = []

func _ready() -> void:
	hide_dialogue()

func show_dialogue(title: String, text: String, pos: Vector2, choices: Array = []) -> void:
	global_position = pos
	title_label.text = title
	text_label.text = text
	
	clear_choices()

	current_choices = choices
	choices_container.visible = choices.size() > 0
	if choices.size() > 0:
		create_choice_buttons(choices)
	
	control.visible = true
	control.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(control, "modulate", Color(1, 1, 1, 1), 0.3)

	await  get_tree().create_timer(0).timeout
	update_panel_size()

func hide_dialogue() -> void:
	var tween = create_tween()
	tween.tween_property(control, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): 
		control.visible = false
		clear_choices()
	)

func update_panel_size() -> void:
	panel.size = text_label.get_rect().size + Vector2(10, 20)
	panel.position = text_label.get_rect().position - Vector2(5, 15)

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
	pass
