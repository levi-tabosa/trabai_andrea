extends Node2D

@export var animated: AnimationPlayer
@export var autoplay: bool = false
@export var next_scene: String = "res://scenes/cutscene_2.tscn"  # Caminho da próxima cena, ex: "res://Cena2.tscn"

func _ready():
	if animated == null:
		animated = $AnimationPlayer  
	
	if autoplay:
		animated.play()

func pause():
	if animated and animated.is_playing():
		animated.pause()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("enter"):
		if animated and not animated.is_playing():
			animated.play()  
		else:
			change_scene()

func change_scene():
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
	else:
		print("Caminho da próxima cena não definido.")
