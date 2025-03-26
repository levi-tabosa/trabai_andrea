extends Area2D
#PROJECTILEE
#PROJECTILEE
#PROJECTILEE
#PROJECTILEE
@export var SPEED = 500
@export var life_time = 2.0 #seconds

var dir: float
var initialPos: Vector2
var initialRot: float

func _ready() -> void:
	global_position = initialPos
	global_rotation = initialRot
	# Add a timer for projectile lifetime
	var timer = Timer.new()
	timer.wait_time = life_time
	timer.one_shot = true
	timer.connect("timeout", _on_lifetime_timeout)
	add_child(timer)
	timer.start()

func _physics_process(delta: float) -> void:
	#velocity = Vector2(0,-SPEED).rotated(dir)
	position += transform.x * SPEED * delta
	#move_and_slide()
	
func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("mobs"):
	#	body.queue_free()
	queue_free()
	
func _on_lifetime_timeout() -> void:
	queue_free()
#PROJECTILEE
#PROJECTILEE
#PROJECTILEE
#PROJECTILEE
