extends Node
class_name HealthComponent

signal health_changed(old_value: int, new_value: int)
signal health_depleted()

@export var max_health := 100
@export var invincible := false
@export var invincibility_duration := 0.5 # em segundos

var is_invincible := false
var current_health: int:
	set(value):
		var old_health = current_health
		current_health = clamp(value, 0, max_health)
		emit_signal("health_changed", old_health, current_health)
		if current_health <= 0:
			emit_signal("health_depleted")
	get:
		return current_health


func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if invincible || is_invincible:
		return
	
	current_health -= amount
	
	if invincibility_duration > 0:
		is_invincible = true
		var t = get_tree()
		if(t):
			await t.create_timer(invincibility_duration).timeout
		else:
			print(null)
		is_invincible = false

func heal(amount: int) -> void:
	current_health += amount

func reset_health() -> void:
	current_health = max_health
