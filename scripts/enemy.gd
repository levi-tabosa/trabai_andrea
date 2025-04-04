extends CharacterBody2D

@export var health_component: HealthComponent
@export var score_value := 10

func _ready() -> void:
	add_to_group("mobs")
	
	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = 50 
		add_child(health_component)
	
	health_component.health_depleted.connect(_on_death)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)
	
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)
	
func _on_death() -> void:
	queue_free()
