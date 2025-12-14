extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEATH }

@export var max_health: float = 50.0
@export var move_speed: float = 150.0
@export var attack_damage: float = 25.0
@export var attack_range: float = 40.0
@export var detection_range: float = 300.0
@export var attack_cooldown: float = 1.0
@export var gravity: float = 800.0
@export var health_bar_path: NodePath = "HealthBar"
@export var item_drop_scene: PackedScene
@export var crystal_drop_scene: PackedScene
@export var crystal_drop_chance: float = 0.25  # 25% шанс

var current_health: float
var state: State = State.IDLE
var player: Node2D
var can_attack: bool = true
var is_attacking: bool = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range_area: Area2D = $AttackRange
@onready var hit_box: Area2D = $HitBox
@onready var health_bar: TextureProgressBar = null

func _ready():
	current_health = max_health
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health
		health_bar.value = current_health

	player = get_tree().get_first_node_in_group("players")

	attack_range_area.body_entered.connect(Callable(self, "_on_attack_range_body_entered"))
	attack_range_area.body_exited.connect(Callable(self, "_on_attack_range_body_exited"))
	hit_box.area_entered.connect(Callable(self, "_on_hit_box_area_entered"))

	add_to_group("enemies")
	play_random_idle()

func _physics_process(delta):
	if state == State.DEATH:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if player:
		update_sprite_direction()
		var distance = global_position.distance_to(player.global_position)
		if state != State.ATTACK and state != State.HURT:
			if distance <= attack_range:
				state = State.ATTACK
			elif distance <= detection_range:
				state = State.CHASE
			else:
				state = State.IDLE

	match state:
		State.IDLE:
			anim_player.play("Idle")
			velocity.x = 0
		State.CHASE:
			state_chase(delta)
		State.ATTACK:
			state_attack()
		State.HURT:
			pass

	move_and_slide()

func state_chase(delta):
	if not player:
		state = State.IDLE
		return
	var dir = (player.global_position - global_position).normalized()
	velocity.x = dir.x * move_speed
	if anim_player.current_animation != "Run":
		anim_player.play("Run")

func state_attack():
	if not player:
		state = State.IDLE
		return
	if can_attack and not is_attacking and player_in_attack_range():
		perform_attack()
	elif not player_in_attack_range():
		state = State.CHASE

func perform_attack():
	can_attack = false
	is_attacking = true
	velocity.x = 0
	anim_player.play("Attack")

	await get_tree().create_timer(0.3).timeout
	apply_attack_damage()

	await anim_player.animation_finished
	is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func apply_attack_damage():
	for body in attack_range_area.get_overlapping_bodies():
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage(attack_damage)
			break

func player_in_attack_range() -> bool:
	return player and global_position.distance_to(player.global_position) <= attack_range

func _on_hit_box_area_entered(area):
	if area.is_in_group("player_attack"):
		var dmg = 20.0
		if area.has_meta("damage"):
			dmg = float(area.get_meta("damage"))
		take_damage(dmg)

func take_damage(amount: float):
	if state == State.DEATH:
		return
	current_health -= amount
	current_health = max(current_health, 0)

	if health_bar:
		health_bar.value = current_health

	if current_health <= 0:
		die()
	else:
		state = State.HURT
		anim_player.play("Hurt")
		await anim_player.animation_finished
		if player_in_attack_range():
			state = State.ATTACK
		else:
			state = State.CHASE

func die():
	state = State.DEATH
	velocity = Vector2.ZERO
	anim_player.play("Death")
	await anim_player.animation_finished

	# Всегда спавним обычный предмет
	if item_drop_scene:
		var item = item_drop_scene.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position
		print("Предмет заспавнен")

	# Спавним кристалл с 25% шансом
	if crystal_drop_scene:
		var random_value = randf()  # Случайное число от 0.0 до 1.0
		print("Шанс выпадения кристалла:", random_value, "/", crystal_drop_chance)
		
		if random_value <= crystal_drop_chance:
			var crystal = crystal_drop_scene.instantiate()
			get_parent().add_child(crystal)
			crystal.global_position = global_position
			print("🎉 Кристалл заспавнен! (шанс сработал)")
		else:
			print("❌ Кристалл не выпал (шанс не сработал)")

	queue_free()

func play_random_idle():
	var idle_animations = ["Idle", "Idle2"]
	anim_player.play(idle_animations[randi() % idle_animations.size()])

func update_sprite_direction():
	if player:
		sprite.flip_h = player.global_position.x < global_position.x

func _on_attack_range_body_entered(body):
	if body.is_in_group("players"):
		state = State.ATTACK

func _on_attack_range_body_exited(body):
	if body.is_in_group("players") and state != State.HURT:
		state = State.CHASE
