extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEATH }

@export var max_health: float = 250.0
@export var move_speed: float = 150.0
@export var attack_damage: float = 25.0
@export var attack_range: float = 80.0  # Увеличил атаку босса
@export var detection_range: float = 2300.0
@export var player_detection_range: float = 300.0  # Увеличил зону обнаружения игрока
@export var attack_cooldown: float = 1.5  # Немного больше кд для баланса
@export var gravity: float = 800.0
@export var health_bar_path: NodePath = "HealthBar"
@export var item_drop_scene: PackedScene
@export var item_drop_chance: float = 0.3  # 30% для босса
@export var crystal_drop_scene: PackedScene
@export var crystal_drop_chance: float = 0.4  # 40% для босса
@export var enemy_id: String = "boss_enemy_"

var current_health: float
var state: State = State.IDLE
var player: Node2D
var cheese: Node2D
var can_attack: bool = true
var is_attacking: bool = false
var my_unique_id: String = ""
var target: Node2D = null
var original_target: Node2D = null
var is_distracted_by_player: bool = false
var distraction_cooldown: float = 0.0
var is_dying: bool = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range_area: Area2D = $AttackRange
@onready var hit_box: Area2D = $HitBox
@onready var health_bar: TextureProgressBar = null
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var save_system = get_node_or_null("/root/save_system")

func _ready():
	print("👑 БОСС создан! HP:", max_health)
	
	# Генерируем уникальный ID
	my_unique_id = enemy_id + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y)) + "_" + str(Time.get_ticks_msec())
	
	# Проверяем, не убит ли уже враг
	if save_system and save_system.is_enemy_killed(my_unique_id):
		print("👑 Босс уже убит, удаляем: ", my_unique_id)
		queue_free()
		return
	
	current_health = max_health
	

	
	# Настраиваем health bar
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Добавляем в группы
	add_to_group("enemies")  # Важно для WaveManager!
	add_to_group("boss")
	
	# Увеличиваем параметры для босса
	max_health *= 2.0  # В 2 раза больше HP
	attack_damage *= 1.5  # В 1.5 раза больше урона
	current_health = max_health
	attack_range = 100.0  # Большая зона атаки
	player_detection_range = 350.0  # Большая зона обнаружения
	
	# Находим цели
	call_deferred("_find_initial_targets")
	
	# Подключаем сигналы
	attack_range_area.body_entered.connect(_on_attack_range_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_body_exited)
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	
	if player_detection_area:
		player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
		player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	
	play_random_idle()
	
	print("👑 ГИГАНТСКИЙ БОСС создан!")
	print("  HP:", max_health)
	print("  Урон:", attack_damage)
	print("  Масштаб:", sprite.scale if sprite else "нет спрайта")

func _find_initial_targets():
	# Ищем цели по группам
	player = get_tree().get_first_node_in_group("players")
	cheese = get_tree().get_first_node_in_group("great_cheese")
	
	print("🔍 Босс ищет начальные цели:")
	print("   Игрок (players):", player != null)
	print("   Сыр (great_cheese):", cheese != null)
	
	# Устанавливаем приоритет: сыр > игрок
	if cheese and is_instance_valid(cheese):
		original_target = cheese
		target = cheese
		print("🎯 Первоначальная цель: Сыр")
	elif player and is_instance_valid(player):
		original_target = player
		target = player
		print("🎯 Первоначальная цель: Игрок (сыр не найден)")
	else:
		print("⚠️ Ничего не найдено!")
		state = State.IDLE

func scale_stats(hp_multiplier: float, damage_multiplier: float):
	max_health *= hp_multiplier
	current_health = max_health
	attack_damage *= damage_multiplier
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	print("👑 Босс усилен: HP=", max_health, " DMG=", attack_damage)

func _physics_process(delta):
	if state == State.DEATH or is_dying:
		return

	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Обновляем кулдаун отвлечения
	if distraction_cooldown > 0:
		distraction_cooldown -= delta
		if distraction_cooldown <= 0 and is_distracted_by_player:
			_return_to_original_target()

	# Если нет цели или цель невалидна - обновляем цель
	if not target or not is_instance_valid(target):
		_update_target()
		if not target:
			state = State.IDLE
			velocity.x = 0
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")
			move_and_slide()
			return

	# Направление спрайта
	if target:
		sprite.flip_h = target.global_position.x < global_position.x
	
	# Дистанция до текущей цели
	var distance_to_target = global_position.distance_to(target.global_position) if target else INF
	
	# Проверяем, есть ли игрок рядом для отвлечения
	if not is_distracted_by_player and player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= player_detection_range:
			print("🎯 Босс: Игрок рядом! Отвлекаюсь на него")
			target = player
			is_distracted_by_player = true
			distraction_cooldown = 10.0
			state = State.CHASE
	
	if state != State.ATTACK and state != State.HURT:
		if distance_to_target <= attack_range:
			state = State.ATTACK
		elif distance_to_target <= detection_range:
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

func _return_to_original_target():
	if original_target and is_instance_valid(original_target):
		print("🎯 Босс: Возвращаюсь к оригинальной цели:", original_target.name)
		target = original_target
		is_distracted_by_player = false
		distraction_cooldown = 0

func _update_target():
	# Если отвлечены на игрока, проверяем его доступность
	if is_distracted_by_player:
		if player and is_instance_valid(player):
			# Проверяем здоровье игрока
			if player.has_method("get_current_health") and player.get_current_health() <= 0:
				_return_to_original_target()
			else:
				target = player
		else:
			_return_to_original_target()
	else:
		# Проверяем оригинальную цель
		if original_target and not is_instance_valid(original_target):
			# Если сыр уничтожен, атакуем игрока
			if original_target == cheese and player and is_instance_valid(player):
				print("🧀 Босс: Сыр уничтожен, переключаюсь на игрока")
				original_target = player
				target = player
			elif original_target == player and cheese and is_instance_valid(cheese):
				print("💀 Босс: Игрок умер, переключаюсь на сыр")
				original_target = cheese
				target = cheese
			else:
				print("⚠️ Босс: Нет целей!")
				target = null

func state_chase(delta):
	if not target or not is_instance_valid(target):
		state = State.IDLE
		return
	
	var dir = (target.global_position - global_position).normalized()
	velocity.x = dir.x * move_speed
	
	if anim_player.current_animation != "Run":
		anim_player.play("Run")
	
	# Если догнали - атака
	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		state = State.ATTACK

func state_attack():
	if not target or not is_instance_valid(target):
		state = State.IDLE
		return
	
	if can_attack and not is_attacking and target_in_attack_range():
		perform_attack()
	elif not target_in_attack_range():
		state = State.CHASE

func perform_attack():
	can_attack = false
	is_attacking = true
	velocity.x = 0
	anim_player.play("Attack")

	await get_tree().create_timer(0.3).timeout
	apply_attack_damage_to_target()

	await anim_player.animation_finished
	is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func apply_attack_damage_to_target():
	if not target or not is_instance_valid(target):
		return
	
	print("👑 Босс атакует:", target.name)
	
	if target.is_in_group("great_cheese") and target.has_method("take_damage"):
		target.take_damage(attack_damage)
	elif target.is_in_group("players") and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func target_in_attack_range() -> bool:
	if not target or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= attack_range

func _on_hit_box_area_entered(area):
	print("👑 Босс получает удар от:", area.name)
	
	# Проверяем что это атака игрока
	if area.is_in_group("player_attack") or area.is_in_group("player_hitbox"):
		var dmg = 20.0
		if area.has_meta("damage"):
			dmg = float(area.get_meta("damage"))
		print("👑 Босс получает урон:", dmg)
		take_damage(dmg)
	elif area.is_in_group("enemy_attack"):
		print("👑 Босс получает удар от другого врага (игнорируем)")

func take_damage(amount: float):
	if state == State.DEATH or is_dying:
		return
	
	current_health -= amount
	current_health = max(current_health, 0)
	print("👑 Босс HP: ", current_health, "/", max_health)

	if health_bar:
		health_bar.value = current_health

	if current_health <= 0:
		die()
	else:
		state = State.HURT
		anim_player.play("Hurt")
		await anim_player.animation_finished
		if target and target_in_attack_range():
			state = State.ATTACK
		else:
			state = State.CHASE

func die():
	if is_dying:
		return
	
	is_dying = true
	state = State.DEATH
	velocity = Vector2.ZERO
	
	print("👑 Босс умирает!")
	
	# Отключаем коллизии
	set_collision_layer(0)
	set_collision_mask(0)
	
	anim_player.play("Death")
	await anim_player.animation_finished

	# Шанс выпадения обычного лута (мусора) - 30% для босса
	if item_drop_scene and randf() <= item_drop_chance:
		var item = item_drop_scene.instantiate()
		if item.has_method("set_enemy_id"):
			item.set_enemy_id(my_unique_id)
		get_parent().add_child(item)
		item.global_position = global_position
		print("👑 Босс: Лут выпал!")
	
	# Шанс выпадения кристалла - 40% для босса
	if crystal_drop_scene and randf() <= crystal_drop_chance:
		var crystal = crystal_drop_scene.instantiate()
		if crystal.has_method("set_enemy_id"):
			crystal.set_enemy_id(my_unique_id)
		get_parent().add_child(crystal)
		crystal.global_position = global_position
		print("👑 Босс: Кристалл выпал!")

	# Отмечаем врага как убитого
	if save_system and my_unique_id != "":
		save_system.mark_enemy_killed(my_unique_id)
	
	# Эмитируем сигнал смерти для WaveManager
	get_tree().call_group("wave_manager", "_on_enemy_died")
	
	print("👑 Босс побежден!")
	
	# Удаляем врага
	queue_free()

func play_random_idle():
	var idle_animations = ["Idle", "Idle2"]
	if idle_animations.size() > 0:
		anim_player.play(idle_animations[randi() % idle_animations.size()])

func _on_attack_range_body_entered(body):
	if (body.is_in_group("great_cheese") or body.is_in_group("players")) and target == body:
		state = State.ATTACK
		print("👑 Босс: Цель вошла в зону атаки")

func _on_attack_range_body_exited(body):
	if (body.is_in_group("great_cheese") or body.is_in_group("players")) and state != State.HURT:
		state = State.CHASE
		print("👑 Босс: Цель вышла из зоны атаки")

func _on_player_detection_area_body_entered(body):
	if body.is_in_group("players"):
		print("👑 Босс: Обнаружен игрок в зоне!")
		if not is_distracted_by_player:
			print("👑 Босс: Отвлекаюсь на игрока!")
			target = body
			is_distracted_by_player = true
			distraction_cooldown = 10.0

func _on_player_detection_area_body_exited(body):
	if body.is_in_group("players") and is_distracted_by_player:
		print("👑 Босс: Игрок вышел из зоны обнаружения")
		distraction_cooldown = 3.0

func stop_moving():
	state = State.IDLE
	velocity = Vector2.ZERO
	if anim_player:
		anim_player.play("Idle")
