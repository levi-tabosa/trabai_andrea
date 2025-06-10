extends Area2D

@export var npc_name = "NPC"
@export_multiline var dialogue_data = """
{
	"start": {
		"text": "Olá! Sobre o que você gostaria de conversar?",
		"choices": ["Me fale sobre este lugar", "Estou procurando algo", "Adeus"],
		"next": ["about_place", "looking_for", "goodbye"]
	},
	"about_place": {
		"text": "Este é um lugar. As pessoas vêm aqui.",
		"choices": ["Voltar aos tópicos principais"],
		"next": ["start"]
	},
	"looking_for": {
		"text": "O que você está procurando?",
		"choices": ["Nada específico", "Voltar aos tópicos principais"],
		"next": ["start", "start"]
	},
	"goodbye": {
		"text": "Adeus! Sinta-se à vontade para conversar de novo se precisar de algo.",
		"choices": [],
		"next": []
	}
}
"""

var dialogue_tree = {}
var dialogue_state = "start"
var is_player_in_area = false

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	DialogueManager.choice_made.connect(_on_choice_made)
	
	# Parse the dialogue data from the exported string
	dialogue_tree = JSON.parse_string(dialogue_data)
	if dialogue_tree == null:
		push_error("Invalid JSON in dialogue_data for " + name)
		dialogue_tree = {}

func show_current_dialogue() -> void:
	if not is_player_in_area:
		return
		
	if dialogue_tree.has(dialogue_state):
		var current_dialogue = dialogue_tree[dialogue_state]
		DialogueManager.show_dialogue(npc_name, current_dialogue["text"], global_position, current_dialogue["choices"], self)
	else:
		push_error("Missing dialogue state: " + dialogue_state)
		DialogueManager.hide_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_in_area = true
		dialogue_state = "start"
		show_current_dialogue()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_in_area = false
		DialogueManager.hide_dialogue()

func _on_choice_made(choice_index: int) -> void:
	if not is_player_in_area:
		return
		
	if dialogue_state in dialogue_tree:
		var current_dialogue = dialogue_tree[dialogue_state]
		
		if choice_index >= 0 and choice_index < current_dialogue["next"].size():
			dialogue_state = current_dialogue["next"][choice_index]
			
			if dialogue_state in dialogue_tree:
				show_current_dialogue()
			else:
				DialogueManager.hide_dialogue()
		else:
			DialogueManager.hide_dialogue()
