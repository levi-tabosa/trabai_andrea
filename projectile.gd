extends CharacterBody2D


@export var SPEED = 100

var dir: float
var initialPos: Vector2
var initialRot: float

func _ready() -> void:
	global_position = initialPos
	global_rotation = initialRot
	

func _physics_process(delta: float) -> void:
	velocity = Vector2(0,-SPEED).rotated(dir)
	move_and_slide()
	
