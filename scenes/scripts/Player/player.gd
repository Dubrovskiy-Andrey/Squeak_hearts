extends CharacterBody2D

# Глобальные ссылки
@onready var save_system: Node = get_node("/root/save_system")
@onready var game_manager: Node = get_node("/root/game_manager")

signal health_changed(current_health, max_health)
signal player_died()
signal currency_changed(new_amount)
signal cheese_changed(cheese_states)
signal cheese_bite_added(cheese_index, new_state)
signal cheese_consumed(cheese_index)
signal super_attack_used()

enum State { IDLE, MOVE, JUMP, ATTACK, SUPER_JUMP, SUPER_LAND }

@export var move_speed: float = 250.0
@export var gravity: float = 800.0
@export var jump_force: float = -900.0
@export var super_jump_force: float = -1200.0
@export var attack_cooldown: float = 0.5
@export var super_attack_cooldown: float = 2.0
@export var max_health: float = 100.0
@export var attack_damage: int = 20
@export var super_attack_damage: int = 50
@export var inventory_path: NodePath = "../UserInterface/Inventory"
@export var hud_path: NodePath = "../UserInterface/HUD"

@export var max_cheese: int = 3
var cheese_bites: Array = []
var bites_per_cheese: int = 3
var current_hit_count: int = 0

var inventory_node: Node = null
var hud_node: Control = null
var state: State = State.IDLE
var can_attack: bool = true
var can_super_attack: bool = true
var is_attacking: bool = false
var can_move: bool = true
var current_health: float
var currency: int = 0

var talisman_hp_bonus: int = 0
var talisman_damage_bonus: int = 0
var talisman_speed_bonus: int = 0
var talisman_cooldown_bonus: int = 0
var talisman_cheese_bonus: int = 0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_point: Node2D = $PickupPoint
@onready var attack_range: Area2D = $AttackRange
@onready var hit_box: Area2D = $HitBox
@onready var super_attack_area: Area2D = $SuperAttackArea

@export var health_bar_path: NodePath = "../UserInterface/HUD/HealthBar"
@export var currency_label_path: NodePath = "../UserInterface/HUD/CurrencyLabel"

var health_bar: TextureProgressBar
var currency_label: Label

var enemies_in_attack_range: Array = []
var enemies_in_super_range: Array = []
var stats_panel: Control = null

var is_super_jumping: bool = false
var original_gravity: float = 0

var is_on_arena: bool = false
var is_initialized: bool = false
var is_dying: bool = false

func _ready():
	if not save_system:
		print("❌ save_system не найден в корне сцены!")
		return
	
	print("💾 save_system найден: ", save_system != null)
	
	if not game_manager:
		print("⚠️ GameManager не найден!")
	
	_check_if_on_arena()
	
	add_to_group("players")
	
	original_gravity = gravity
	current_health = max_health
	currency = 0
	
	_init_cheese()
	bites_per_cheese = max(1, 3 + talisman_cheese_bonus)
	
	print("🧀 Временный сыр: ", cheese_bites)
	print("📍 На арене: ", is_on_arena)
	
	if health_bar_path and has_node(health_bar_path):
		health_bar = get_node(health_bar_path)
		health_bar.max_value = max_health + talisman_hp_bonus
		health_bar.value = current_health
		
	if currency_label_path and has_node(currency_label_path):
		currency_label = get_node(currency_label_path)
		currency_label.text = str(currency)

	if hud_path and has_node(hud_path):
		hud_node = get_node(hud_path)
	
	await get_tree().create_timer(0.1).timeout
	
	call_deferred("_delayed_load")

func _check_if_on_arena():
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name.to_lower()
		if "arena" in scene_name or current_scene.scene_file_path and "arena" in current_scene.scene_file_path.to_lower():
			is_on_arena = true
			print("🎮 Игрок загружен на арене")
		else:
			is_on_arena = false

func _delayed_load():
	print("🧀 Начинаем загрузку сохранения игрока...")
	load_saved_data()
	
	sync_health_with_talismans()
	
	if health_bar:
		health_bar.max_value = max_health + talisman_hp_bonus
		health_bar.value = current_health
		
	if currency_label:
		currency_label.text = str(currency)
	
	bites_per_cheese = max(1, 3 + talisman_cheese_bonus)
	print("🧀 Финальный сыр после загрузки: ", cheese_bites)
	
	emit_signal("health_changed", current_health, max_health + talisman_hp_bonus)
	emit_signal("currency_changed", currency)
	emit_cheese_changed()

	if inventory_path and has_node(inventory_path):
		inventory_node = get_node(inventory_path)
		call_deferred("_ensure_stats_panel_found")

	for child in get_children():
		if child is Area2D and child.name == "PickupZone":
			if child.body_entered.is_connected(_on_pickup_zone_body_entered):
				child.body_entered.disconnect(_on_pickup_zone_body_entered)
			child.body_entered.connect(_on_pickup_zone_body_entered)

	attack_range.body_entered.connect(Callable(self, "_on_attack_range_body_entered"))
	attack_range.body_exited.connect(Callable(self, "_on_attack_range_body_exited"))
	hit_box.area_entered.connect(Callable(self, "_on_hit_box_area_entered"))
	
	if super_attack_area:
		super_attack_area.body_entered.connect(Callable(self, "_on_super_attack_area_body_entered"))
		super_attack_area.body_exited.connect(Callable(self, "_on_super_attack_area_body_exited"))
	
	is_initialized = true
	print("✅ Игрок полностью инициализирован. Здоровье: ", current_health, "/", max_health + talisman_hp_bonus)

func sync_health_with_talismans():
	var total_max_health = max_health + talisman_hp_bonus
	
	if current_health > total_max_health:
		current_health = total_max_health
	
	if talisman_hp_bonus > 0 and current_health < total_max_health:
		var health_ratio = float(current_health) / float(max_health) if max_health > 0 else 1.0
		current_health = total_max_health * health_ratio
	
	if health_bar:
		health_bar.max_value = total_max_health
		health_bar.value = current_health
	
	emit_signal("health_changed", current_health, total_max_health)
	
	print("🔄 Здоровье синхронизировано: ", current_health, "/", total_max_health, " (бонусы: +", talisman_hp_bonus, ")")

func _init_cheese():
	cheese_bites.clear()
	for i in range(max_cheese):
		cheese_bites.append(3)
	
	current_hit_count = 0

func emit_cheese_changed():
	var states = []
	for bites in cheese_bites:
		states.append(bites)
	cheese_changed.emit(states)

func load_saved_data():
	if save_system and is_instance_valid(save_system):
		print("🧀 Загрузка сохранения из save_system...")
		var player_data = save_system.get_player_data()
		
		print("🧀 Получены данные игрока: ", player_data.keys())
		
		if player_data.has("currency"):
			currency = player_data.get("currency", 0)
		if player_data.has("health"):
			current_health = player_data.get("health", max_health)
		if player_data.has("max_health"):
			max_health = player_data.get("max_health", max_health)
		if player_data.has("damage"):
			attack_damage = player_data.get("damage", attack_damage)
		
		if player_data.has("cheese_bites"):
			var loaded_cheese = player_data["cheese_bites"]
			print("🧀 Загруженный сыр из сохранения (сырой): ", loaded_cheese)
			
			if loaded_cheese is Array and loaded_cheese.size() == max_cheese:
				var valid = true
				for bite in loaded_cheese:
					if not (bite is int and bite >= 0 and bite <= 3):
						valid = false
						break
				
				if valid:
					cheese_bites = loaded_cheese.duplicate()
					print("🧀 СЫР ЗАГРУЖЕН ИЗ СОХРАНЕНИЯ: ", cheese_bites)
				else:
					print("🧀 Невалидные данные сыра, инициализирую заново")
					_init_cheese()
			else:
				print("🧀 Сыр в сохранении невалидный, инициализирую заново")
				_init_cheese()
		else:
			print("🧀 Сыр не найден в сохранении, инициализирую заново")
			_init_cheese()
		
		if player_data.has("current_hit_count"):
			current_hit_count = player_data.get("current_hit_count", 0)
		else:
			current_hit_count = 0
		
		if player_data.has("position_x") and player_data.has("position_y") and not is_on_arena:
			var pos = Vector2(player_data["position_x"], player_data["position_y"])
			if pos != Vector2.ZERO:
				global_position = pos
				print("🧀 Позиция загружена: ", global_position)
		
		print("🧀 Итоговый сыр после загрузки: ", cheese_bites)
	else:
		print("🧀 save_system не найден или невалиден")
		_init_cheese()

func apply_upgrade(health_bonus: int, damage_bonus: int, crystal_cost: int = 0, currency_cost: int = 0) -> bool:
	if currency_cost > 0 and currency < currency_cost:
		return false
	
	if crystal_cost > 0 and PlayerInventory.get_crystal_count() < crystal_cost:
		return false
	
	if currency_cost > 0:
		currency -= currency_cost
		emit_signal("currency_changed", currency)
	
	if crystal_cost > 0:
		PlayerInventory.spend_crystals(crystal_cost)
	
	max_health += health_bonus
	current_health += health_bonus
	attack_damage += damage_bonus
	
	if health_bar:
		health_bar.max_value = max_health + talisman_hp_bonus
		health_bar.value = current_health
	
	if currency_label:
		currency_label.text = str(currency)
	
	_refresh_inventory_stats()
	emit_signal("health_changed", current_health, max_health + talisman_hp_bonus)
	
	if save_system:
		save_system.update_player_data(self)
	
	return true

func _ensure_stats_panel_found():
	if inventory_node:
		stats_panel = inventory_node.get_node_or_null("StatsPanel")

func _input(event):
	if event.is_action_pressed("inventory") and inventory_node:
		inventory_node.visible = not inventory_node.visible
		can_move = not inventory_node.visible
		
		if hud_node:
			hud_node.visible = not inventory_node.visible
		
		if inventory_node.visible:
			_refresh_inventory_stats()
	
	if event.is_action_pressed("start_arena") and not is_on_arena and can_move:
		print("🎮 Нажата кнопка O - запуск арены...")
		start_arena_mode()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("super_attack") and can_super_attack and not is_super_jumping and can_move:
		try_super_attack()
	
	if event.is_action_pressed("ui_cancel") and not Input.is_key_pressed(KEY_SHIFT):
		save_without_restore()

	if event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_SHIFT):
		return_to_main_menu()
		get_viewport().set_input_as_handled()

func start_arena_mode():
	print("🎮 Запуск режима защиты арены!")
	
	if not game_manager:
		print("❌ GameManager не найден! Нельзя запустить арену.")
		_show_notification("Ошибка: GameManager не найден!")
		return
	
	print("🎮 Текущая сложность: ", game_manager.get_difficulty_name())
	
	if save_system:
		print("💾 Сохраняем игру перед переходом на арену...")
		save_without_restore()
		await get_tree().create_timer(0.5).timeout
	
	print("🚀 Переход на арену...")
	get_tree().change_scene_to_file("res://scenes/arena_scene.tscn")

func save_without_restore():
	if save_system and is_instance_valid(save_system):
		print("💾 БЫСТРОЕ СОХРАНЕНИЕ...")
		print("🧀 Текущий сыр перед сохранением: ", cheese_bites)
		
		save_system.update_player_data(self)
		save_system.quick_save(self)
		
		print("✅ Игра сохранена!")
		_show_notification("Игра сохранена!")
	else:
		print("❌ save_system не найден или невалиден!")

func _physics_process(delta: float):
	if not can_move or is_super_jumping:
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	match state:
		State.IDLE: _state_idle()
		State.MOVE: _state_move()
		State.JUMP: _state_jump()
		State.ATTACK: pass
		State.SUPER_JUMP: _state_super_jump(delta)
		State.SUPER_LAND: _state_super_land(delta)
	
	move_and_slide()

func _state_idle():
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if dir != 0:
		state = State.MOVE
		return
	
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force
		anim_player.play("Jump")
		state = State.JUMP
		return
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
		return
	
	anim_player.play("Idle")
	velocity.x = move_toward(velocity.x, 0, move_speed)

func _state_move():
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var speed_multiplier = 1.0 + (talisman_speed_bonus / 100.0)
	velocity.x = dir * move_speed * speed_multiplier
	
	if dir != 0:
		sprite.flip_h = dir > 0
		anim_player.play("Walk")
	else:
		state = State.IDLE
		return
	
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force
		anim_player.play("Jump")
		state = State.JUMP
		return
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
		return

func _state_jump():
	anim_player.play("Jump")
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var speed_multiplier = 1.0 + (talisman_speed_bonus / 100.0)
	velocity.x = dir * move_speed * speed_multiplier
	
	if dir != 0:
		sprite.flip_h = dir > 0
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
	
	if is_on_floor():
		state = State.IDLE

func _state_super_jump(delta: float):
	velocity.y += gravity * delta
	anim_player.play("Jump")

func _state_super_land(delta: float):
	velocity.y += gravity * delta * 3.0
	anim_player.play("Jump")

func start_attack() -> void:
	if not can_attack or is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	state = State.ATTACK
	velocity.x = 0
	anim_player.play("Attack")
	
	await get_tree().create_timer(0.18).timeout
	_apply_attack_damage()
	
	await anim_player.animation_finished
	
	var actual_cooldown = attack_cooldown
	if talisman_cooldown_bonus > 0:
		actual_cooldown = attack_cooldown * (1.0 - talisman_cooldown_bonus / 100.0)
		actual_cooldown = max(actual_cooldown, 0.1)
	
	await get_tree().create_timer(actual_cooldown).timeout
	
	is_attacking = false
	can_attack = true
	
	if not is_on_floor():
		state = State.JUMP
	else:
		state = State.IDLE

func _apply_attack_damage():
	var total_damage = attack_damage + talisman_damage_bonus
	var hit_landed = false
	
	for enemy in enemies_in_attack_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(total_damage)
			hit_landed = true
	
	if hit_landed:
		add_cheese_bite()

func _on_attack_range_body_entered(body):
	if body.is_in_group("enemies") and not enemies_in_attack_range.has(body):
		enemies_in_attack_range.append(body)

func _on_attack_range_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_attack_range.erase(body)

func _on_super_attack_area_body_entered(body):
	if body.is_in_group("enemies") and not enemies_in_super_range.has(body):
		enemies_in_super_range.append(body)

func _on_super_attack_area_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_super_range.erase(body)

func _on_hit_box_area_entered(area):
	if area.is_in_group("enemy_attack"):
		if area.has_meta("damage"):
			take_damage(float(area.get_meta("damage")))
		else:
			take_damage(20.0)

func _on_pickup_zone_body_entered(body):
	if body.is_in_group("item_drop") and body.has_method("pick_up_item"):
		body.pick_up_item(self)
	if body.is_in_group("crystals") and body.has_method("pick_up"):
		body.pick_up(self)

func _auto_pick_item(item):
	if not is_instance_valid(item):
		return
	
	if item.item_name == "Trash":
		currency += 20
		
		if currency_label:
			currency_label.text = str(currency)
		
		if save_system:
			save_system.add_currency(20)
		
		emit_signal("currency_changed", currency)
		_refresh_inventory_stats()
	elif item.item_name == "Crystal":
		_auto_pick_crystal(item)
	else:
		PlayerInventory.add_item(item.item_name, item.item_quantity)
		_refresh_inventory_stats()
	item.queue_free()

func _auto_pick_crystal(crystal):
	if not is_instance_valid(crystal):
		return
	
	PlayerInventory.add_item("Crystal", 1)
	_show_pickup_notification("Кристалл +1")
	
	_refresh_inventory_stats()
	crystal.queue_free()

func _show_pickup_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.position = global_position + Vector2(0, -50)
	get_parent().add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 30, 0.5)
	tween.parallel().tween_property(notification, "modulate:a", 0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	notification.queue_free()

func _show_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.position = global_position + Vector2(0, -80)
	get_parent().add_child(notification)
	
	notification.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	notification.add_theme_font_size_override("font_size", 16)
	
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 30, 0.5)
	tween.parallel().tween_property(notification, "modulate:a", 0, 0.8)
	
	await get_tree().create_timer(1.0).timeout
	notification.queue_free()

func _refresh_inventory_stats():
	if stats_panel:
		stats_panel.refresh_stats()

func take_damage(damage: float) -> void:
	if is_dying:
		return
	
	var total_max_health = max_health + talisman_hp_bonus
	
	current_health = max(current_health - damage, 0)
	
	if health_bar:
		health_bar.max_value = total_max_health
		health_bar.value = current_health
	
	emit_signal("health_changed", current_health, total_max_health)
	
	if anim_player.has_animation("hit_effect"):
		anim_player.play("hit_effect")
	
	if current_health <= 0:
		die()
	
	_refresh_inventory_stats()

func heal(amount: float) -> void:
	var total_max_health = max_health + talisman_hp_bonus
	current_health = min(current_health + amount, total_max_health)
	
	if health_bar:
		health_bar.max_value = total_max_health
		health_bar.value = current_health
	
	emit_signal("health_changed", current_health, total_max_health)
	
	print("❤️ Исцеление: +", amount, " HP. Теперь: ", current_health, "/", total_max_health)
	
	_refresh_inventory_stats()

func heal_to_full():
	var total_max_health = max_health + talisman_hp_bonus
	current_health = total_max_health
	
	if health_bar:
		health_bar.max_value = total_max_health
		health_bar.value = current_health
	
	emit_signal("health_changed", current_health, total_max_health)
	
	print("❤️ Здоровье восстановлено до максимума с бонусами: ", current_health, "/", total_max_health)
	
	if save_system:
		save_system.update_player_data(self)

func die() -> void:
	if is_dying:
		return
	
	is_dying = true
	print("💀 Игрок умирает...")
	
	set_physics_process(false)
	can_move = false
	can_attack = false
	
	set_collision_layer(0)
	set_collision_mask(0)
	
	emit_signal("player_died")
	
	if is_on_arena:
		print("💀 Игрок умер на арене, сообщаю арене...")
		var arena = get_tree().get_first_node_in_group("arena")
		if arena and arena.has_method("on_player_died"):
			print("💀 Вызываю on_player_died() на арене")
			arena.on_player_died()
		else:
			print("⚠️ Арена не найдена или не имеет метода on_player_died")
			_show_arena_results_on_death()
	else:
		print("💀 Игрок умер не на арене")
	
	if anim_player.has_animation("Death"):
		anim_player.play("Death")
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	if not is_on_arena:
		print("💀 Возвращаем в лагерь через 2 секунды...")
		
		await get_tree().create_timer(2.0).timeout
		
		if save_system and is_instance_valid(save_system):
			print("💾 Сохраняем перед возвратом в лагерь...")
			save_without_restore()
		
		print("🚪 Возвращаемся в лагерь...")
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _show_arena_results_on_death():
	print("📊 Показываю экран результатов после смерти игрока...")
	
	var arena = get_tree().get_first_node_in_group("arena")
	if arena:
		print("✅ Арена найдена, получаю данные...")
		
		var survival_time = 0.0
		var waves_completed = 0
		
		if arena.has_method("get_survival_time"):
			survival_time = arena.get_survival_time()
			print("⏱️ Время выживания: ", survival_time)
		
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		if wave_manager and wave_manager.has_method("get_current_wave"):
			waves_completed = wave_manager.get_current_wave() - 1
			print("🌊 Волн пройдено: ", waves_completed)
		
		if save_system and is_instance_valid(save_system):
			print("💾 Сохраняем перед показом результатов...")
			save_without_restore()
			await get_tree().create_timer(0.5).timeout
		
		var message = Label.new()
		message.text = "💀 ВАС УБИЛИ! 💀"
		message.add_theme_font_size_override("font_size", 48)
		message.add_theme_color_override("font_color", Color(1, 0, 0))
		message.position = Vector2(400, 300) - Vector2(150, 25)
		get_parent().add_child(message)
		
		var tween = create_tween()
		tween.tween_property(message, "scale", Vector2(1.5, 1.5), 0.5)
		tween.tween_property(message, "scale", Vector2(1.0, 1.0), 0.5)
		tween.tween_property(message, "modulate:a", 0, 1.0)
		
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(message):
			message.queue_free()
		
		await get_tree().create_timer(1.0).timeout
		
		var results_scene = load("res://scenes/arena_result.tscn")
		if results_scene:
			print("✅ Сцена результатов загружена")
			
			var results = results_scene.instantiate()
			print("✅ Экземпляр создан")
			
			var camera_position = _get_camera_center_position()
			print("📊 Центр камеры для позиционирования:", camera_position)
			
			get_parent().add_child(results)
			print("✅ Окно добавлено на сцену")
			
			await get_tree().process_frame
			
			var wave_num = 0
			if wave_manager and wave_manager.has_method("get_current_wave"):
				wave_num = wave_manager.get_current_wave()
				print("📊 Волна для отображения:", wave_num)
			
			if results.has_method("position_at_camera"):
				print("✅ Вызываю position_at_camera()")
				results.position_at_camera(camera_position)
			
			var is_victory = false
			
			if results.has_method("display_results"):
				print("✅ Вызываю display_results()")
				await get_tree().create_timer(0.05).timeout
				results.display_results(survival_time, wave_num, is_victory, camera_position)
				print("✅ display_results() вызван")
			else:
				print("❌ Окно не имеет метода display_results()")
			
			var ui = get_tree().get_first_node_in_group("arena_ui")
			if ui:
				ui.visible = false
				print("✅ UI арены скрыт")
			
			print("✅ Всё готово, окно должно быть видно!")
		else:
			print("❌ Сцена результатов не найдена")
	else:
		print("❌ Арена не найдена, просто возвращаюсь в лагерь")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/world/labaratory/lab_scene.tscn")

func _get_camera_center_position() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if camera:
		print("🎥 Камера найдена, позиция:", camera.global_position)
		return camera.global_position
	
	print("🎥 Камера не найдена, использую позицию игрока:", global_position)
	return global_position

func add_cheese_bite():
	if cheese_bites.size() == 0:
		return
	
	var cheese_to_fill = -1
	
	for i in range(cheese_bites.size()):
		if cheese_bites[i] < 3:
			cheese_to_fill = i
			break
	
	if cheese_to_fill == -1:
		print("🧀 Все сыры полные!")
		return
	
	current_hit_count += 1
	
	var hits_needed = bites_per_cheese
	var progress = float(current_hit_count) / float(hits_needed)
	
	var new_state = 0
	if progress >= 1.0:
		new_state = 3
	elif progress >= 2.0/3.0:
		new_state = 2
	elif progress >= 1.0/3.0:
		new_state = 1
	
	if new_state != cheese_bites[cheese_to_fill]:
		cheese_bites[cheese_to_fill] = new_state
		cheese_bite_added.emit(cheese_to_fill, new_state)
	
	if new_state == 3:
		print("🧀 Сыр ", cheese_to_fill, " стал полным!")
		current_hit_count = 0
	
	emit_cheese_changed()
	
	if save_system and is_instance_valid(save_system):
		print("🧀 Сохраняем сыр после добавления кусочка: ", cheese_bites)
		save_system.update_player_data(self)

func consume_cheese() -> bool:
	for i in range(cheese_bites.size() - 1, -1, -1):
		if cheese_bites[i] == 3:
			cheese_bites[i] = 0
			current_hit_count = 0
			
			cheese_consumed.emit(i)
			emit_cheese_changed()
			print("🧀 Потрачен правый сыр ", i)
			
			if save_system and is_instance_valid(save_system):
				print("🧀 Сохраняем сыр после траты: ", cheese_bites)
				save_system.update_player_data(self)
			return true
	return false

func restore_all_cheese():
	for i in range(cheese_bites.size()):
		cheese_bites[i] = 3
	
	current_hit_count = 0
	
	emit_cheese_changed()
	print("🧀 Все сыры восстановлены!")
	
	if save_system and is_instance_valid(save_system):
		print("🧀 Сохраняем полный сыр: ", cheese_bites)
		save_system.update_player_data(self)

func get_full_cheese_count() -> int:
	var count = 0
	for bites in cheese_bites:
		if bites == 3:
			count += 1
	return count

func has_full_cheese() -> bool:
	for bites in cheese_bites:
		if bites == 3:
			return true
	return false

func get_cheese_state(index: int) -> int:
	if index >= 0 and index < cheese_bites.size():
		return cheese_bites[index]
	return 0

func get_current_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func get_total_max_health() -> float:
	return max_health + talisman_hp_bonus

func get_talisman_bonuses() -> Dictionary:
	return {
		"hp_bonus": talisman_hp_bonus,
		"damage_bonus": talisman_damage_bonus,
		"speed_bonus": talisman_speed_bonus,
		"cooldown_bonus": talisman_cooldown_bonus,
		"cheese_bonus": talisman_cheese_bonus
	}

func get_total_health() -> Dictionary:
	return {
		"base_current": current_health,
		"base_max": max_health,
		"bonus_hp": talisman_hp_bonus,
		"total_current": current_health,
		"total_max": max_health + talisman_hp_bonus
	}

func update_cheese_bonus():
	bites_per_cheese = max(1, 3 + talisman_cheese_bonus)
	print("Для полного сыра теперь нужно ударов: ", bites_per_cheese)

func try_super_attack():
	if not has_full_cheese():
		print("Недостаточно сыра для супер-удара!")
		return
	
	if not can_super_attack or is_super_jumping:
		return
	
	print("Запускаем супер-атаку...")
	
	if consume_cheese():
		start_super_jump()
	else:
		print("Не удалось использовать сыр для супер-удара")

func start_super_jump():
	can_super_attack = false
	is_super_jumping = true
	state = State.SUPER_JUMP
	can_move = false
	can_attack = false
	
	print("Супер-прыжок!")
	
	velocity.y = super_jump_force
	velocity.x = 0
	
	anim_player.play("Jump")
	sprite.modulate = Color(1, 0.8, 0.5, 1)
	
	await get_tree().create_timer(0.4).timeout
	
	print("Начинаем быстрое падение...")
	state = State.SUPER_LAND
	
	var fast_fall_gravity = original_gravity * 3.0
	
	var fall_timer = 0.0
	var max_fall_time = 1.5
	
	while not is_on_floor() and fall_timer < max_fall_time:
		velocity.y += fast_fall_gravity * get_physics_process_delta_time()
		fall_timer += get_physics_process_delta_time()
		await get_tree().physics_frame
	
	print("Удар при приземлении!")
	
	gravity = original_gravity
	
	_apply_super_attack_damage()
	
	anim_player.play("Attack")
	sprite.modulate = Color(1, 0.5, 0.5, 1)
	
	await get_tree().create_timer(0.2).timeout
	
	sprite.modulate = Color(1, 1, 1, 1)
	
	await get_tree().create_timer(0.3).timeout
	
	print("Супер-атака завершена!")
	
	is_super_jumping = false
	can_move = true
	can_attack = true
	state = State.IDLE
	
	emit_signal("super_attack_used")
	
	await get_tree().create_timer(super_attack_cooldown).timeout
	can_super_attack = true

func _apply_super_attack_damage():
	var total_damage = super_attack_damage + talisman_damage_bonus
	
	print("Супер-удар! Урон: ", total_damage)
	
	var damaged_enemies = 0
	for enemy in enemies_in_super_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(total_damage)
			damaged_enemies += 1
	
	for enemy in enemies_in_attack_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and not enemies_in_super_range.has(enemy):
			enemy.take_damage(total_damage)
			damaged_enemies += 1
	
	if damaged_enemies > 0:
		print("Поражено врагов: ", damaged_enemies)

func get_player_health() -> String:
	var total_current = current_health
	var total_max = max_health + talisman_hp_bonus
	return str(int(total_current)) + "/" + str(int(total_max))

func get_player_damage() -> int:
	return attack_damage + talisman_damage_bonus

func get_player_currency() -> int:
	return currency

func return_to_main_menu():
	print("Возврат в главное меню...")
	save_without_restore()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func quick_save():
	save_without_restore()

func set_can_move(value: bool):
	can_move = value
	if not can_move:
		velocity = Vector2.ZERO
		state = State.IDLE
		anim_player.play("Idle")
	print("Движение игрока:", "разблокировано" if value else "заблокировано")

func stop_all_enemies():
	print("⏹️ Игрок пытается остановить врагов...")
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("stop_moving"):
			enemy.call_deferred("stop_moving")
	print("⏹️ Отправлен запрос на остановку", enemies.size(), "врагов")
