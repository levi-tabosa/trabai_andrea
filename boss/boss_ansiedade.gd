extends CharacterBody2D

@export var health_component: HealthComponent
# Configurações do inimigo
var vida: int = 50
var velocidade: float = 350.0
var tempo_entre_corridas: float = 2.0
var duracao_corrida: float = 1.0
var player: Node2D

# Internos
var tempo_para_correr = 0.0
var esta_correndo = false
var direcao = Vector2.ZERO
var anim_sprite: AnimatedSprite2D

func _ready():
	player = get_tree().get_root().get_node("main/Player")  # Ajuste o caminho
	anim_sprite = $AnimatedSprite2D
	tempo_para_correr = tempo_entre_corridas * randf()
	anim_sprite.play("idle")
	add_to_group("mobs")

	if not health_component:
		health_component = HealthComponent.new()
		health_component.max_health = vida
		add_child(health_component)

	if health_component:
		if not health_component.health_depleted.is_connected(_on_death):
			health_component.health_depleted.connect(_on_death)
	else:
		printerr("Enemy requires a HealthComponent!")


func _physics_process(delta):
	if not player:
		return

	if esta_correndo:
		# Corre na direção do player
		velocity = direcao * velocidade
		duracao_corrida -= delta
		if duracao_corrida <= 0:
			esta_correndo = false
			tempo_para_correr = tempo_entre_corridas
			velocity = Vector2.ZERO
			anim_sprite.play("idle")
	else:
		tempo_para_correr -= delta
		if tempo_para_correr <= 0:
			direcao = (player.global_position - global_position).normalized()

			# Inverter sprite se for para a esquerda
			anim_sprite.flip_h = direcao.x < 0

			duracao_corrida = 1.0
			esta_correndo = true
			anim_sprite.play("run")

	move_and_slide()
	
func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE
	else:
		printerr("Cannot take damage, HealthComponent is missing!")

func _on_death() -> void:
	queue_free()
