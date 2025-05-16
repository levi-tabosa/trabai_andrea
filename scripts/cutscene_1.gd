extends Node2D

@export var animated: AnimationPlayer
@export var autoplay: bool = false

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
			animated.play()  # Retoma a animação pausada
