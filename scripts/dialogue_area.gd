extends Area2D

@export var npc_name = "NPC"

var dialogue_state = "start"
var dialogue_tree = {
	"start": {
		"text": "Hello! What would you like to talk about?",
		"choices": ["Tell me about this place", "I'm looking for something", "Goodbye"],
		"next": ["about_place", "looking_for", "goodbye"]
	},
	"about_place": {
		"text": "This is the hospital. We treat patients and conduct research here.",
		"choices": ["Tell me more about the research", "Who's in charge?", "Let's talk about something else"],
		"next": ["research", "in_charge", "start"]
	},
	"research": {
		"text": "Our research focuses on experimental treatments and new medications.",
		"choices": ["Is that safe?", "Back to main topics"],
		"next": ["safety", "start"]
	},
	"safety": {
		"text": "We follow strict protocols to ensure all our research is ethical and safe.",
		"choices": ["I understand", "Back to main topics"],
		"next": ["start", "start"]
	},
	"in_charge": {
		"text": "Dr. Blackwood is the head of this hospital. She's been here for 20 years.",
		"choices": ["Can I meet her?", "Back to main topics"],
		"next": ["meet_doctor", "start"]
	},
	"meet_doctor": {
		"text": "She's very busy, but sometimes visits this floor. You might catch her if you wait.",
		"choices": ["I'll wait then", "Maybe later", "Back to main topics"],
		"next": ["wait", "start", "start"]
	},
	"wait": {
		"text": "You wait for a while, but she doesn't appear. Maybe try again later.",
		"choices": ["Back to main topics"],
		"next": ["start"]
	},
	"looking_for": {
		"text": "What are you looking for? We have medicine, equipment, and information.",
		"choices": ["Medicine", "Equipment", "Information", "None of these"],
		"next": ["medicine", "equipment", "information", "start"]
	},
	"medicine": {
		"text": "We have various medications. You should talk to a doctor for prescriptions.",
		"choices": ["Where are the doctors?", "Back to main topics"],
		"next": ["doctors_location", "start"]
	},
	"doctors_location": {
		"text": "Doctors are usually on the second floor. Take the elevator at the end of the hall.",
		"choices": ["Thanks!", "Back to main topics"],
		"next": ["start", "start"]
	},
	"equipment": {
		"text": "Our equipment is for hospital use only, unless you have special authorization.",
		"choices": ["How do I get authorization?", "Back to main topics"],
		"next": ["authorization", "start"]
	},
	"authorization": {
		"text": "You need to speak with administration on the first floor.",
		"choices": ["I'll do that", "Back to main topics"],
		"next": ["start", "start"]
	},
	"information": {
		"text": "What information are you looking for?",
		"choices": ["Patient records", "Hospital history", "Staff directory", "None of these"],
		"next": ["records", "history", "directory", "start"]
	},
	"records": {
		"text": "Patient records are confidential. Only authorized personnel can access them.",
		"choices": ["Back to information", "Back to main topics"],
		"next": ["information", "start"]
	},
	"history": {
		"text": "This hospital was founded in 1965 and has been serving the community ever since.",
		"choices": ["Tell me more", "Back to information", "Back to main topics"],
		"next": ["history_more", "information", "start"]
	},
	"history_more": {
		"text": "The hospital was initially small but expanded in the 80s. It's now one of the largest in the region.",
		"choices": ["Back to information", "Back to main topics"],
		"next": ["information", "start"]
	},
	"directory": {
		"text": "You can find the staff directory at the front desk in the main lobby.",
		"choices": ["Back to information", "Back to main topics"],
		"next": ["information", "start"]
	},
	"goodbye": {
		"text": "Goodbye! Feel free to talk again if you need anything.",
		"choices": [],
		"next": []
	}
}

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	DialogueManager.choice_made.connect(_on_choice_made)

func show_current_dialogue() -> void:
	var dialogue_data = dialogue_tree[dialogue_state]
	DialogueManager.show_dialogue(npc_name, dialogue_data["text"], dialogue_data["choices"])

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		dialogue_state = "start"
		show_current_dialogue()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "player":
		DialogueManager.hide_dialogue()

func _on_choice_made(choice_index: int) -> void:
	if dialogue_state in dialogue_tree:
		var dialogue_data = dialogue_tree[dialogue_state]
		
		if choice_index >= 0 and choice_index < dialogue_data["next"].size():
			dialogue_state = dialogue_data["next"][choice_index]
			
			if dialogue_state in dialogue_tree:
				show_current_dialogue()
			else:
				DialogueManager.hide_dialogue()
		else:
			DialogueManager.hide_dialogue()
