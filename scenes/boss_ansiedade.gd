extends CharacterBody2D

# Configurações do inimigo
var vida: int = 50
var velocidade: float = 200.0
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
