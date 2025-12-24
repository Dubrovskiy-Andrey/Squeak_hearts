extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEATH }

# Экспортируемые параметры
@export var max_health: float = 50.0
@export var move_speed: float = 120.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 300.0
@export var min_shooting_distance: float = 150.0
@export var detection_range: float = 2300.0
@export var player_detection_range: float = 200.0
@export var attack_cooldown: float = 2.0
@export var gravity: float = 800.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 300.0
@export var health_bar_path: NodePath = "HealthBar"
@export var item_drop_scene: PackedScene
@export var item_drop_chance: float = 0.2
@export var crystal_drop_scene: PackedScene
@export var crystal_drop_chance: float = 0.25
@export var enemy_id: String = "enemy_ranged_"

# Переменные
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

# Ноды
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range_area: Area2D = $AttackRange
@onready var hit_box: Area2D = $HitBox
@onready var health_bar: TextureProgressBar = null
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var shoot_point: Marker2D = $ShootPoint
@onready var save_system = get_node_or_null("/root/save_system")

func _ready():
	# Генерируем уникальный ID
	my_unique_id = enemy_id + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y)) + "_" + str(Time.get_ticks_msec())
	
	# Проверяем, не убит ли уже враг
	if save_system and save_system.is_enemy_killed(my_unique_id):
		print("Враг уже убит, удаляем: ", my_unique_id)
		queue_free()
		return
	
	current_health = max_health
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Добавляем в группу врагов
	add_to_group("enemies")
	add_to_group("ranged_enemies")
	print("✅ Враг-стрелок добавлен в группу 'enemies'")
	
	# Находим цели
	call_deferred("_find_initial_targets")
	
	# Подключаем сигналы
	attack_range_area.body_entered.connect(Callable(self, "_on_attack_range_body_entered"))
	attack_range_area.body_exited.connect(Callable(self, "_on_attack_range_body_exited"))
	hit_box.area_entered.connect(Callable(self, "_on_hit_box_area_entered"))
	
	if player_detection_area:
		player_detection_area.body_entered.connect(Callable(self, "_on_player_detection_area_body_entered"))
		player_detection_area.body_exited.connect(Callable(self, "_on_player_detection_area_body_exited"))
	
	# Просто проигрываем Idle анимацию
	anim_player.play("Idle")

func _find_initial_targets():
	# Ищем цели по группам
	player = get_tree().get_first_node_in_group("players")
	cheese = get_tree().get_first_node_in_group("great_cheese")
	
	print("🔍 Враг-стрелок ищет начальные цели:")
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

func scale_stats(hp_multiplier: float, damage_multiplier: float):
	max_health *= hp_multiplier
	current_health = max_health
	attack_damage *= damage_multiplier
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	print("📊 Враг усилен: HP=", max_health, " DMG=", attack_damage)

func _physics_process(delta):
	if state == State.DEATH or is_dying:
		return

	# Применяем гравитацию ВСЕГДА
	velocity.y += gravity * delta

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
			print("🎯 Игрок рядом! Отвлекаюсь на него")
			target = player
			is_distracted_by_player = true
			distraction_cooldown = 10.0
			state = State.CHASE
	
	# ЛОГИКА СТРЕЛЬБЫ:
	if state != State.ATTACK and state != State.HURT:
		if distance_to_target <= attack_range and distance_to_target >= min_shooting_distance:
			# Если цель в зоне стрельбы
			state = State.ATTACK
		elif distance_to_target > attack_range and distance_to_target <= detection_range:
			# Если цель в зоне преследования
			state = State.CHASE
		elif distance_to_target < min_shooting_distance:
			# Если слишком близко - отступаем
			state = State.CHASE
		else:
			state = State.IDLE

	match state:
		State.IDLE:
			velocity.x = 0
			if anim_player.current_animation != "Idle" and not is_attacking:
				anim_player.play("Idle")
		State.CHASE:
			state_chase(delta)
		State.ATTACK:
			state_attack()
		State.HURT:
			pass

	move_and_slide()
	
	# Сбрасываем вертикальную скорость если на земле
	if is_on_floor():
		velocity.y = 0

func _return_to_original_target():
	if original_target and is_instance_valid(original_target):
		print("🎯 Возвращаюсь к оригинальной цели:", original_target.name)
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
				print("🧀 Сыр уничтожен, переключаюсь на игрока")
				original_target = player
				target = player
			elif original_target == player and cheese and is_instance_valid(cheese):
				print("💀 Игрок умер, переключаюсь на сыр")
				original_target = cheese
				target = cheese
			else:
				print("⚠️ Нет целей!")
				target = null

func state_chase(delta):
	if not target or not is_instance_valid(target):
		state = State.IDLE
		return
	
	var distance = global_position.distance_to(target.global_position)
	var dir = Vector2.ZERO
	
	if distance < min_shooting_distance:
		# Слишком близко - отступаем
		dir = (global_position - target.global_position).normalized()
	elif distance > attack_range:
		# Слишком далеко - приближаемся
		dir = (target.global_position - global_position).normalized()
	else:
		# В идеальной зоне стрельбы - стоим на месте
		dir = Vector2.ZERO
	
	velocity.x = dir.x * move_speed
	
	if anim_player.current_animation != "Run" and not is_attacking:
		anim_player.play("Run")
	
	# Проверяем, находимся ли мы в зоне стрельбы
	if distance <= attack_range and distance >= min_shooting_distance:
		state = State.ATTACK

func state_attack():
	if not target or not is_instance_valid(target):
		state = State.IDLE
		return
	
	# Останавливаемся для стрельбы
	velocity.x = 0
	
	var distance = global_position.distance_to(target.global_position)
	
	# Проверяем дистанцию
	if distance < min_shooting_distance or distance > attack_range:
		state = State.CHASE
		return
	
	if can_attack and not is_attacking:
		perform_ranged_attack()

func perform_ranged_attack():
	can_attack = false
	is_attacking = true
	velocity.x = 0
	
	# Проигрываем анимацию атаки
	if anim_player.has_animation("Attack"):
		anim_player.play("Attack")
	else:
		# Если нет анимации Attack, используем Idle
		anim_player.play("Idle")
	
	# Ждём момент выстрела (0.4 секунды)
	await get_tree().create_timer(0.4).timeout
	
	# Стреляем
	shoot_projectile()
	
	# Ждём окончания анимации
	if anim_player.has_animation("Attack"):
		await anim_player.animation_finished
	else:
		# Если нет анимации, ждём немного
		await get_tree().create_timer(0.4).timeout
	
	is_attacking = false
	
	# Ждём кулдаун
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func shoot_projectile():
	if not projectile_scene or not target or not is_instance_valid(target):
		print("⚠️ Не могу выстрелить: нет снаряда или цели")
		return
	
	print("🎯 Цель для выстрела: ", target.name)
	print("🎯 Группы цели: ", target.get_groups())
	print("🎯 Тип цели: ", target.get_class())
	
	var projectile = projectile_scene.instantiate()
	
	# Устанавливаем позицию выстрела
	projectile.global_position = shoot_point.global_position
	
	# Рассчитываем направление к цели
	var direction = (target.global_position - shoot_point.global_position).normalized()
	print("🎯 Направление выстрела: ", direction)
	
	# Передаём параметры снаряду
	if projectile.has_method("setup"):
		projectile.setup(direction, projectile_speed, attack_damage)
	
	# Настраиваем спрайт снаряда
	if projectile.has_node("Sprite2D"):
		projectile.get_node("Sprite2D").rotation = direction.angle()
	elif projectile.has_node("AnimatedSprite2D"):
		projectile.get_node("AnimatedSprite2D").rotation = direction.angle()
	
	# Добавляем в сцену (в родителя врага)
	get_parent().add_child(projectile)
	
	print("🔫 Враг стреляет в ", target.name)

func target_in_attack_range() -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	var distance = global_position.distance_to(target.global_position)
	return distance <= attack_range and distance >= min_shooting_distance

func _on_hit_box_area_entered(area):
	if area.is_in_group("player_attack"):
		var dmg = 20.0
		if area.has_meta("damage"):
			dmg = float(area.get_meta("damage"))
		take_damage(dmg)

func take_damage(amount: float):
	if state == State.DEATH or is_dying:
		return
	
	current_health -= amount
	current_health = max(current_health, 0)

	if health_bar:
		health_bar.value = current_health

	if current_health <= 0:
		die()
	else:
		state = State.HURT
		
		# Проигрываем анимацию получения урона если есть
		if anim_player.has_animation("Hurt"):
			anim_player.play("Hurt")
			await anim_player.animation_finished
		else:
			# Или просто ждём короткое время
			await get_tree().create_timer(0.3).timeout
		
		# Возвращаемся к предыдущему состоянию
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
	
	# Отключаем коллизии
	set_collision_layer(0)
	set_collision_mask(0)
	
	anim_player.play("Death")
	await anim_player.animation_finished

	# Применяем бонус шанса дропа от Salli
	var drop_multiplier = 1.0
	var crystal_multiplier = 1.0
	
	if save_system:
		# Получаем уровень улучшения дропа от Salli
		var drop_level = save_system.get_npc_upgrade_level("salli_drop_chance")
		if drop_level > 0:
			# Каждый уровень даёт +5% к шансу дропа (0.05)
			drop_multiplier = 1.0 + (drop_level * 0.05)
			crystal_multiplier = 1.0 + (drop_level * 0.05)
			print("🎯 Бонус дропа от Salli: ×", drop_multiplier, " (уровень ", drop_level, ")")
	
	# Шанс выпадения обычного лута (мусора) с учётом бонуса
	var final_item_chance = item_drop_chance * drop_multiplier
	# Ограничиваем максимальный шанс 80%
	final_item_chance = min(final_item_chance, 0.8)
	
	if item_drop_scene and randf() <= final_item_chance:
		var item = item_drop_scene.instantiate()
		if item.has_method("set_enemy_id"):
			item.set_enemy_id(my_unique_id)
		get_parent().add_child(item)
		item.global_position = global_position
		print("📦 Обычный лут выпал (шанс: ", int(final_item_chance * 100), "%)")
	
	# Шанс выпадения кристалла с учётом бонуса
	var final_crystal_chance = crystal_drop_chance * crystal_multiplier
	# Ограничиваем максимальный шанс 70%
	final_crystal_chance = min(final_crystal_chance, 0.7)
	
	if crystal_drop_scene and randf() <= final_crystal_chance:
		var crystal = crystal_drop_scene.instantiate()
		if crystal.has_method("set_enemy_id"):
			crystal.set_enemy_id(my_unique_id)
		get_parent().add_child(crystal)
		crystal.global_position = global_position
		print("💎 Кристалл выпал (шанс: ", int(final_crystal_chance * 100), "%)")
	
	
	# Отмечаем врага как убитого
	if save_system and my_unique_id != "":
		save_system.mark_enemy_killed(my_unique_id)
	
	# Удаляем врага
	queue_free()
	
	# Эмитируем сигнал смерти для WaveManager
	get_tree().call_group("wave_manager", "_on_enemy_died")

func _on_attack_range_body_entered(body):
	if (body.is_in_group("great_cheese") or body.is_in_group("players")) and target == body:
		var distance = global_position.distance_to(body.global_position)
		if distance >= min_shooting_distance:
			state = State.ATTACK

func _on_attack_range_body_exited(body):
	if (body.is_in_group("great_cheese") or body.is_in_group("players")) and state != State.HURT:
		state = State.CHASE

func _on_player_detection_area_body_entered(body):
	if body.is_in_group("players"):
		print("🎯 Обнаружен игрок в зоне!")
		if not is_distracted_by_player:
			print("🎯 Отвлекаюсь на игрока!")
			target = body
			is_distracted_by_player = true
			distraction_cooldown = 10.0

func _on_player_detection_area_body_exited(body):
	if body.is_in_group("players") and is_distracted_by_player:
		print("🎯 Игрок вышел из зоны обнаружения")
		distraction_cooldown = 3.0

func stop_moving():
	state = State.IDLE
	velocity = Vector2.ZERO
	if anim_player:
		anim_player.play("Idle")

func apply_wave_bonus(wave_number: int):
	pass
