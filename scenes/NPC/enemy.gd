extends CharacterBody2D

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEATH
}

@export var max_health: float = 50.0
@export var move_speed: float = 150.0
@export var attack_damage: float = 25.0
@export var attack_range: float = 40.0
@export var detection_range: float = 300.0
@export var gravity: float = 800.0

var state: State = State.IDLE
var current_health: float
var player: Node2D
var is_dead: bool = false
var can_attack: bool = true
var is_attacking: bool = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range_area = $AttackRange
@onready var hit_box = $HitBox

var player_in_detection_range: bool = false
var player_in_attack_range: bool = false

func _ready():
	current_health = max_health
	await get_tree().create_timer(0.5).timeout
	player = get_tree().get_first_node_in_group("players")
	print("Враг загружен. Игрок найден: ", player != null)
	
	attack_range_area.body_entered.connect(_on_attack_range_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_body_exited)
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	
	play_random_idle()

func _physics_process(delta):
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	if player:
		update_sprite_direction()
		check_player_distance()
	
	match state:
		State.IDLE:
			state_idle()
		State.CHASE:
			state_chase(delta)
		State.ATTACK:
			state_attack()
		State.HURT:
			state_hurt()
		State.DEATH:
			pass
	
	move_and_slide()

func check_player_distance():
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	player_in_detection_range = distance_to_player <= detection_range
	
	# Обновляем player_in_attack_range на основе расстояния
	if distance_to_player <= attack_range:
		player_in_attack_range = true
	else:
		player_in_attack_range = false

func state_idle():
	if not player:
		player = get_tree().get_first_node_in_group("players")
		return
	
	if player_in_detection_range:
		state = State.CHASE
		anim_player.play("Run")
		return
	
	if randf() < 0.002:
		play_random_idle()

func state_chase(delta):
	if not player:
		state = State.IDLE
		play_random_idle()
		return
	
	if not player_in_detection_range:
		state = State.IDLE
		velocity = Vector2.ZERO
		play_random_idle()
		return
	
	if player_in_attack_range:
		state = State.ATTACK
		velocity = Vector2.ZERO
		anim_player.play("Idle")
		return
	
	var move_direction = Vector2.ZERO
	if player:
		move_direction = (player.global_position - global_position).normalized()
		velocity.x = move_direction.x * move_speed
	
	if velocity.x != 0 and anim_player.current_animation != "Run":
		anim_player.play("Run")

func state_attack():
	if not player:
		state = State.CHASE
		return
	
	# Проверяем расстояние каждый кадр
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > attack_range:
		state = State.CHASE
		return
	
	if can_attack and not is_attacking:
		start_attack()

func state_hurt():
	velocity = Vector2.ZERO

func start_attack():
	if not can_attack or is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	velocity = Vector2.ZERO
	
	anim_player.play("Attack")
	print("Враг начинает атаку")
	
	# Ждем момент в анимации когда нужно нанести урон
	await get_tree().create_timer(0.3).timeout
	
	# НАНОСИМ УРОН через Area2D
	apply_attack_damage()
	
	await anim_player.animation_finished
	is_attacking = false
	
	# КД атаки
	await get_tree().create_timer(1.0).timeout
	can_attack = true
	
	# После атаки проверяем где игрок
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= attack_range:
			# Игрок всё ещё в зоне атаки - атакуем снова
			start_attack()
		else:
			# Игрок отошел - переходим в погоню
			state = State.CHASE
	else:
		state = State.IDLE

# ФУНКЦИЯ НАНЕСЕНИЯ УРОНА
func apply_attack_damage():
	if attack_range_area:
		var bodies = attack_range_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players"):
				print("Враг атаковал игрока! Урон: ", attack_damage)
				body.take_damage(attack_damage)
				break  # Наносим урон только одному игроку

# ----------------- Система получения урона -----------------
func _on_hit_box_area_entered(area):
	if area.is_in_group("player_attack") and not is_dead:
		print("Враг получил урон от игрока")
		take_damage(20.0)

# ----------------- Система обнаружения игрока -----------------
func _on_attack_range_body_entered(body):
	if body.is_in_group("players"):
		player_in_attack_range = true
		print("Игрок вошел в зону атаки врага")

func _on_attack_range_body_exited(body):
	if body.is_in_group("players"):
		player_in_attack_range = false
		print("Игрок вышел из зоны атаки врага")

func take_damage(damage: float):
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	print("Враг получил урон: ", damage, ". Текущее здоровье: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		# Прерываем текущую атаку если получаем урон
		if state == State.ATTACK:
			is_attacking = false
			can_attack = true
		
		state = State.HURT
		anim_player.play("Hurt")
		await anim_player.animation_finished
		
		# После получения урона проверяем где игрок
		if player_in_attack_range:
			state = State.ATTACK
		elif player_in_detection_range:
			state = State.CHASE
		else:
			state = State.IDLE

func die():
	is_dead = true
	state = State.DEATH
	velocity = Vector2.ZERO
	
	anim_player.play("Death")
	await anim_player.animation_finished
	
	queue_free()

func play_random_idle():
	var idle_animations = ["Idle", "Idle2", "Idle3", "Idle4"]
	var random_idle = idle_animations[randi() % idle_animations.size()]
	anim_player.play(random_idle)

func update_sprite_direction():
	if player:
		sprite.flip_h = player.global_position.x < global_position.x
