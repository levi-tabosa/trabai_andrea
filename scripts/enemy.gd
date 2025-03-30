extends CharacterBody2D

@export var health_component: HealthComponent
@export var score_value := 10

func _ready() -> void:
	add_to_group("mobs")
	
	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = 50  # Enemies have less health
		add_child(health_component)
	
	health_component.health_depleted.connect(_on_death)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func _on_death() -> void:
	# Add score or other effects
	queue_free()
