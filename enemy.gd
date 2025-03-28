extends CharacterBody2D

@export var health_component: HealthComponent

@onready var animated = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("mobs")
	
	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = 50
		add_child(health_component)
	
	health_component.health_depleted.connect(_on_death)
	animated.play("default", 0.6)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)
func _on_death() -> void:
	# Add score or other effects
	#if Global.score:
	#	Global.score += score_value
	#animated.play("death")
	queue_free()
